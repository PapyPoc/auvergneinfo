#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "::error::$*" >&2
  exit 1
}

: "${PROXMOX_HOST:?}"
: "${PROXMOX_PORT:?}"
: "${TEMPLATE_VMID:?}"
: "${TEMPLATE_NAME:?}"
: "${STORAGE:?}"
: "${BRIDGE:?}"
: "${VMID_MIN:?}"
: "${VMID_MAX:?}"
: "${STATIC_IP_FIRST:?}"
: "${STATIC_IP_LAST:?}"
: "${NETWORK_CIDR:?}"
: "${NETWORK_GATEWAY:?}"
: "${NETWORK_DNS:?}"
: "${CI_USER:?}"
: "${WEB_ROOT:?}"
: "${VM_HOSTNAME:?}"
: "${CORES:?}"
: "${MEMORY_MB:?}"
: "${DISK_GROW_GB:?}"
: "${START_VM:?}"
: "${PROXMOX_TOKEN_ID:?Secret PROXMOX_TOKEN_ID absent}"
: "${PROXMOX_TOKEN_SECRET:?Secret PROXMOX_TOKEN_SECRET absent}"

for cmd in curl python3 ssh ssh-keygen tar; do
  command -v "$cmd" >/dev/null || fail "$cmd est requis sur runner-git."
done

PROXMOX_TOKEN_ID="$(printf '%s' "$PROXMOX_TOKEN_ID" | python3 -c 'import sys; print(sys.stdin.read().strip())')"
PROXMOX_TOKEN_SECRET="$(printf '%s' "$PROXMOX_TOKEN_SECRET" | python3 -c 'import sys; print(sys.stdin.read().strip())')"

[[ "$PROXMOX_TOKEN_ID" =~ ^[^[:space:]]+@[^[:space:]!]+![^[:space:]]+$ ]] \
  || fail "PROXMOX_TOKEN_ID invalide. Format attendu : utilisateur@realm!token."
[[ "$VM_HOSTNAME" =~ ^[a-zA-Z0-9][a-zA-Z0-9.-]{0,62}$ ]] \
  || fail "Nom de VM invalide : $VM_HOSTNAME"
[[ "$CORES" =~ ^[0-9]+$ ]] && (( CORES >= 1 && CORES <= 64 )) \
  || fail "Nombre de vCPU invalide."
[[ "$MEMORY_MB" =~ ^[0-9]+$ ]] && (( MEMORY_MB >= 512 )) \
  || fail "Mémoire invalide (minimum 512 Mo)."
[[ "$DISK_GROW_GB" =~ ^[0-9]+$ ]] \
  || fail "disk_grow_gb doit être un entier positif ou 0."

SSH_KEY_FILE=""
cleanup() {
  [ -z "$SSH_KEY_FILE" ] || rm -f "$SSH_KEY_FILE"
}
trap cleanup EXIT

if [ "$START_VM" = "true" ]; then
  [ -n "${VM_SSH_PRIVATE_KEY:-}" ] || fail "Secret VM_SSH_PRIVATE_KEY absent."
  SSH_KEY_FILE="$(mktemp)"
  printf '%s\n' "$VM_SSH_PRIVATE_KEY" | tr -d '\r' > "$SSH_KEY_FILE"
  chmod 600 "$SSH_KEY_FILE"
  if ! SSH_KEY_ERROR="$(ssh-keygen -y -P '' -f "$SSH_KEY_FILE" 2>&1 >/dev/null)"; then
    fail "VM_SSH_PRIVATE_KEY invalide ou protégée par une passphrase. Détail : ${SSH_KEY_ERROR:-format invalide}"
  fi
fi

API="https://${PROXMOX_HOST}:${PROXMOX_PORT}/api2/json"
AUTH_HEADER="Authorization: PVEAPIToken=${PROXMOX_TOKEN_ID}=${PROXMOX_TOKEN_SECRET}"

api_request() {
  local method="$1" path="$2"
  shift 2
  local body_file http_code body
  body_file="$(mktemp)"
  if ! http_code="$(curl -ksS -o "$body_file" -w '%{http_code}' -X "$method" -H "$AUTH_HEADER" "$@" "${API}${path}")"; then
    rm -f "$body_file"
    fail "Impossible de joindre l'API Proxmox ${PROXMOX_HOST}:${PROXMOX_PORT}."
  fi
  body="$(cat "$body_file")"
  rm -f "$body_file"
  if [[ ! "$http_code" =~ ^2[0-9][0-9]$ ]]; then
    [ -n "$body" ] || body="aucun détail retourné"
    fail "API Proxmox ${method} ${path} : HTTP ${http_code} — ${body}"
  fi
  printf '%s' "$body"
}

api_get() { api_request GET "$1"; }
api_post() { local path="$1"; shift; api_request POST "$path" "$@"; }
api_put() { local path="$1"; shift; api_request PUT "$path" "$@"; }
json_data() { python3 -c 'import json,sys; print(json.load(sys.stdin).get("data", ""))'; }
url_encode() { python3 -c 'import sys,urllib.parse; print(urllib.parse.quote(sys.argv[1], safe=""))' "$1"; }

wait_task() {
  local node="$1" upid="$2" encoded response status exitstatus
  encoded="$(url_encode "$upid")"
  for _ in $(seq 1 300); do
    response="$(api_get "/nodes/${node}/tasks/${encoded}/status")"
    status="$(printf '%s' "$response" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("data", {}).get("status", ""))')"
    if [ "$status" = "stopped" ]; then
      exitstatus="$(printf '%s' "$response" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("data", {}).get("exitstatus", ""))')"
      [ "$exitstatus" = "OK" ] || fail "Tâche Proxmox échouée : ${exitstatus:-inconnu}"
      return 0
    fi
    sleep 2
  done
  fail "Timeout en attente de la tâche Proxmox."
}

cloudinit_config_args() {
  CONFIG_ARGS=(
    --data-urlencode "cores=${CORES}"
    --data-urlencode "memory=${MEMORY_MB}"
    --data-urlencode "net0=virtio,bridge=${BRIDGE}"
    --data-urlencode "onboot=1"
    --data-urlencode "ciuser=${CI_USER}"
    --data-urlencode "ipconfig0=ip=${EXPECTED_IP}/${NETWORK_CIDR},gw=${NETWORK_GATEWAY}"
    --data-urlencode "nameserver=${NETWORK_DNS}"
  )

  if [ "$START_VM" = "true" ]; then
    local raw_key encoded_key
    raw_key="$(ssh-keygen -y -P '' -f "$SSH_KEY_FILE")"
    encoded_key="$(url_encode "$raw_key")"
    CONFIG_ARGS+=(--data-urlencode "sshkeys=${encoded_key}")
  fi
}

echo "Connexion à Proxmox ${PROXMOX_HOST}:${PROXMOX_PORT}..."
cluster_resources="$(api_get '/cluster/resources?type=vm')"
echo "Authentification API Proxmox réussie."

existing_info="$(printf '%s' "$cluster_resources" | python3 -c '
import json,sys
wanted=sys.argv[1].lower()
matches=[]
for item in json.load(sys.stdin).get("data", []):
    if str(item.get("name", "")).lower() == wanted and not int(item.get("template", 0) or 0):
        matches.append(item)
if len(matches) > 1:
    print("MULTIPLE")
elif len(matches) == 1:
    x=matches[0]
    print("{}\t{}\t{}".format(x.get("vmid", ""), x.get("node", ""), x.get("status", "")))
' "$VM_HOSTNAME")"

[ "$existing_info" != "MULTIPLE" ] \
  || fail "Plusieurs VM portent le nom ${VM_HOSTNAME}. Impossible de choisir en sécurité."

VM_REUSED="false"
VM_STATUS="stopped"

if [ -n "$existing_info" ]; then
  IFS=$'\t' read -r VMID node VM_STATUS <<< "$existing_info"
  [[ "$VMID" =~ ^[0-9]+$ ]] || fail "VMID existant invalide : ${VMID:-vide}."
  (( VMID >= VMID_MIN && VMID <= VMID_MAX )) \
    || fail "La VM ${VM_HOSTNAME} existe avec le VMID ${VMID}, hors du pool géré ${VMID_MIN}-${VMID_MAX}."

  EXPECTED_IP="10.0.0.$((STATIC_IP_FIRST + VMID - VMID_MIN))"
  vm_config="$(api_get "/nodes/${node}/qemu/${VMID}/config")"
  CONFIGURED_IP="$(printf '%s' "$vm_config" | python3 -c '
import json,re,sys
cfg=str(json.load(sys.stdin).get("data", {}).get("ipconfig0", ""))
m=re.search(r"(?:^|,)ip=([^/,]+)(?:/\d+)?", cfg)
print(m.group(1) if m else "")
')"

  if [ -z "$CONFIGURED_IP" ]; then
    echo "VM ${VMID} trouvée mais provisioning Cloud-Init incomplet : reprise de la configuration."
    cloudinit_config_args
    api_put "/nodes/${node}/qemu/${VMID}/config" "${CONFIG_ARGS[@]}" >/dev/null
  elif [ "$CONFIGURED_IP" != "$EXPECTED_IP" ]; then
    fail "La VM ${VMID} existe mais son IP Cloud-Init (${CONFIGURED_IP}) ne correspond pas à ${EXPECTED_IP}."
  else
    VM_REUSED="true"
    echo "VM existante : ${VM_HOSTNAME} (VMID ${VMID}, ${EXPECTED_IP})."
    echo "Aucun clonage ni changement matériel : mise à jour du site uniquement."
  fi

  if [ "$START_VM" = "true" ] && [ "$VM_STATUS" != "running" ]; then
    echo "Démarrage de la VM existante ${VMID}..."
    start_response="$(api_post "/nodes/${node}/qemu/${VMID}/status/start")"
    start_upid="$(printf '%s' "$start_response" | json_data)"
    [ -n "$start_upid" ] || fail "Proxmox n'a pas retourné de tâche de démarrage."
    wait_task "$node" "$start_upid"
    VM_STATUS="running"
  fi
else
  node="$(printf '%s' "$cluster_resources" | python3 -c '
import json,sys
target=int(sys.argv[1])
for item in json.load(sys.stdin).get("data", []):
    if int(item.get("vmid", -1)) == target:
        print(item.get("node", ""))
        break
' "$TEMPLATE_VMID")"
  [ -n "$node" ] || fail "Template VMID ${TEMPLATE_VMID} introuvable."

  template_config="$(api_get "/nodes/${node}/qemu/${TEMPLATE_VMID}/config")"
  template_check="$(printf '%s' "$template_config" | python3 -c '
import json,sys
expected=sys.argv[1]
data=json.load(sys.stdin).get("data", {})
is_template=int(data.get("template", 0)) == 1
name=str(data.get("name", ""))
has_cloudinit=any(isinstance(v, str) and "cloudinit" in v.lower() for v in data.values())
print("ok" if is_template and name.lower() == expected.lower() and has_cloudinit else "template={};name={};cloudinit={}".format(is_template,name,has_cloudinit))
' "$TEMPLATE_NAME")"
  [ "$template_check" = "ok" ] \
    || fail "Le VMID ${TEMPLATE_VMID} n'est pas le template Cloud-Init attendu ${TEMPLATE_NAME} (${template_check})."

  VMID="$(printf '%s' "$cluster_resources" | python3 -c '
import json,sys
minimum=int(sys.argv[1]); maximum=int(sys.argv[2])
used={int(x.get("vmid", -1)) for x in json.load(sys.stdin).get("data", [])}
for vmid in range(minimum, maximum + 1):
    if vmid not in used:
        print(vmid)
        break
' "$VMID_MIN" "$VMID_MAX")"
  [ -n "$VMID" ] || fail "Pool VMID saturé : ${VMID_MIN}-${VMID_MAX}."

  EXPECTED_IP="10.0.0.$((STATIC_IP_FIRST + VMID - VMID_MIN))"
  (( STATIC_IP_FIRST + VMID - VMID_MIN <= STATIC_IP_LAST )) \
    || fail "Aucune IP statique disponible pour le VMID ${VMID}."

  echo "Création de ${VM_HOSTNAME} : VMID ${VMID}, IP ${EXPECTED_IP}/${NETWORK_CIDR}."
  api_get "/nodes/${node}/storage/${STORAGE}/status" >/dev/null
  api_get "/nodes/${node}/network/${BRIDGE}" >/dev/null

  clone_response="$(api_post "/nodes/${node}/qemu/${TEMPLATE_VMID}/clone" \
    --data-urlencode "newid=${VMID}" \
    --data-urlencode "name=${VM_HOSTNAME}" \
    --data-urlencode "full=1" \
    --data-urlencode "storage=${STORAGE}")"
  clone_upid="$(printf '%s' "$clone_response" | json_data)"
  [ -n "$clone_upid" ] || fail "Proxmox n'a pas retourné de tâche de clonage."
  wait_task "$node" "$clone_upid"

  cloudinit_config_args
  api_put "/nodes/${node}/qemu/${VMID}/config" "${CONFIG_ARGS[@]}" >/dev/null

  if (( DISK_GROW_GB > 0 )); then
    vm_config="$(api_get "/nodes/${node}/qemu/${VMID}/config")"
    boot_disk="$(printf '%s' "$vm_config" | python3 -c '
import json,sys
data=json.load(sys.stdin).get("data", {})
for key in ["scsi0", "virtio0", "sata0", "ide0"]:
    value=data.get(key, "")
    if isinstance(value, str) and value and "media=cdrom" not in value.lower() and "cloudinit" not in value.lower():
        print(key)
        break
')"
    [ -n "$boot_disk" ] || fail "Impossible de déterminer le disque système à agrandir."
    api_put "/nodes/${node}/qemu/${VMID}/resize" \
      --data-urlencode "disk=${boot_disk}" \
      --data-urlencode "size=+${DISK_GROW_GB}G" >/dev/null
  fi

  if [ "$START_VM" = "true" ]; then
    start_response="$(api_post "/nodes/${node}/qemu/${VMID}/status/start")"
    start_upid="$(printf '%s' "$start_response" | json_data)"
    [ -n "$start_upid" ] || fail "Proxmox n'a pas retourné de tâche de démarrage."
    wait_task "$node" "$start_upid"
    VM_STATUS="running"
  fi
fi

SITE_DEPLOYED="false"

if [ "$START_VM" = "true" ]; then
  SSH_OPTS=(
    -i "$SSH_KEY_FILE"
    -o BatchMode=yes
    -o ConnectTimeout=5
    -o ConnectionAttempts=1
    -o StrictHostKeyChecking=no
    -o UserKnownHostsFile=/dev/null
    -o LogLevel=ERROR
  )

  echo "Attente de SSH sur ${CI_USER}@${EXPECTED_IP}..."
  READY="false"
  for _ in $(seq 1 60); do
    if ssh "${SSH_OPTS[@]}" "${CI_USER}@${EXPECTED_IP}" "printf READY" 2>/dev/null | grep -q READY; then
      READY="true"
      break
    fi
    sleep 5
  done
  [ "$READY" = "true" ] || fail "La VM ${VMID} ne répond pas en SSH sur ${EXPECTED_IP}."

  CLOUD_INIT_RC=0
  CLOUD_INIT_OUTPUT="$(ssh "${SSH_OPTS[@]}" "${CI_USER}@${EXPECTED_IP}" \
    "if command -v cloud-init >/dev/null 2>&1; then cloud-init status --wait --long; fi" 2>&1)" \
    || CLOUD_INIT_RC=$?

  if [ -n "$CLOUD_INIT_OUTPUT" ]; then
    printf '%s\n' "$CLOUD_INIT_OUTPUT"
  fi

  case "$CLOUD_INIT_RC" in
    0) ;;
    2)
      echo "::warning::Cloud-Init a terminé avec un état dégradé (code 2). Le déploiement continue car la VM est joignable en SSH."
      ;;
    *)
      fail "Cloud-Init a échoué sur ${EXPECTED_IP} avec le code ${CLOUD_INIT_RC}."
      ;;
  esac

  SUDO_MODE=""
  if ssh "${SSH_OPTS[@]}" "${CI_USER}@${EXPECTED_IP}" "sudo -n true" >/dev/null 2>&1; then
    SUDO_MODE="nopasswd"
  elif [ -n "${VM_SUDO_PASSWORD:-}" ] && \
       printf '%s\n' "$VM_SUDO_PASSWORD" | ssh "${SSH_OPTS[@]}" "${CI_USER}@${EXPECTED_IP}" "sudo -S -k -p '' true" >/dev/null 2>&1; then
    SUDO_MODE="password"
  else
    fail "Le compte ${CI_USER} ne peut pas utiliser sudo. Configure VM_SUDO_PASSWORD si nécessaire."
  fi

  SITE_ARCHIVE="$(mktemp --suffix=.tar.gz)"
  REMOTE_SCRIPT="$(mktemp)"
  trap 'rm -f "$SSH_KEY_FILE" "$SITE_ARCHIVE" "$REMOTE_SCRIPT"' EXIT
  tar -C dist -czf "$SITE_ARCHIVE" .

  cat > "$REMOTE_SCRIPT" <<'REMOTE_EOF'
#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
WEB_ROOT="$1"

POLICY_RC_D="/usr/sbin/policy-rc.d"
POLICY_BACKUP=""
restore_policy_rc_d() {
  if [ -n "$POLICY_BACKUP" ] && [ -e "$POLICY_BACKUP" ]; then
    mv -f "$POLICY_BACKUP" "$POLICY_RC_D"
  else
    rm -f "$POLICY_RC_D"
  fi
}

if [ -e "$POLICY_RC_D" ]; then
  POLICY_BACKUP="$(mktemp /tmp/policy-rc.d.auvergneinfo.XXXXXX)"
  cp -a "$POLICY_RC_D" "$POLICY_BACKUP"
fi
cat > "$POLICY_RC_D" <<'POLICY_EOF'
#!/bin/sh
exit 101
POLICY_EOF
chmod 0755 "$POLICY_RC_D"
trap restore_policy_rc_d EXIT

apt-get update
apt-get install -y nginx curl

install -d -o root -g root -m 0755 "$WEB_ROOT"
find "$WEB_ROOT" -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +
tar -xzf /tmp/auvergneinfo-site.tar.gz -C "$WEB_ROOT"
chown -R www-data:www-data "$WEB_ROOT"
find "$WEB_ROOT" -type d -exec chmod 0755 {} +
find "$WEB_ROOT" -type f -exec chmod 0644 {} +

install -m 0644 /tmp/auvergneinfo.conf /etc/nginx/sites-available/auvergneinfo.conf
ln -sfn /etc/nginx/sites-available/auvergneinfo.conf /etc/nginx/sites-enabled/auvergneinfo.conf
rm -f /etc/nginx/sites-enabled/default

nginx -t

restore_policy_rc_d
trap - EXIT

# Le template peut avoir UFW actif avec uniquement SSH autorisé.
if command -v ufw >/dev/null 2>&1; then
  echo "Configuration UFW : autorisation de HTTP/80..."
  ufw allow 80/tcp >/dev/null
  ufw status || true
fi

systemctl enable nginx
systemctl restart nginx

if ! systemctl is-active --quiet nginx; then
  echo "=== systemctl status nginx ===" >&2
  systemctl status nginx --no-pager -l >&2 || true
  echo "=== journal nginx ===" >&2
  journalctl -u nginx -n 80 --no-pager >&2 || true
  exit 1
fi

echo "=== écoute TCP Nginx ==="
ss -ltnp | grep -E 'LISTEN.*:80([[:space:]]|$)' || {
  echo "Nginx est actif mais aucun socket TCP/80 n'est en écoute." >&2
  exit 1
}

echo "=== test HTTP local ==="
LOCAL_HTTP_CODE="$(curl -sS --connect-timeout 2 --max-time 5 -o /dev/null -w '%{http_code}' http://127.0.0.1/ || true)"
echo "HTTP local 127.0.0.1 : ${LOCAL_HTTP_CODE:-échec}"
[ "$LOCAL_HTTP_CODE" = "200" ] || {
  echo "Nginx ne sert pas le site localement." >&2
  tail -n 80 /var/log/nginx/error.log >&2 || true
  exit 1
}

rm -f /tmp/auvergneinfo-site.tar.gz /tmp/auvergneinfo.conf /tmp/auvergneinfo-deploy.sh
REMOTE_EOF

  echo "Transfert du site via SSH (sans SCP/SFTP)..."
  ssh "${SSH_OPTS[@]}" "${CI_USER}@${EXPECTED_IP}" \
    "umask 077; cat > /tmp/auvergneinfo-site.tar.gz" < "$SITE_ARCHIVE"
  ssh "${SSH_OPTS[@]}" "${CI_USER}@${EXPECTED_IP}" \
    "umask 077; cat > /tmp/auvergneinfo.conf" < deploy/nginx/auvergneinfo.conf
  ssh "${SSH_OPTS[@]}" "${CI_USER}@${EXPECTED_IP}" \
    "umask 077; cat > /tmp/auvergneinfo-deploy.sh" < "$REMOTE_SCRIPT"

  if [ "$SUDO_MODE" = "nopasswd" ]; then
    ssh "${SSH_OPTS[@]}" "${CI_USER}@${EXPECTED_IP}" \
      "sudo -n bash /tmp/auvergneinfo-deploy.sh '$WEB_ROOT'"
  else
    printf '%s\n' "$VM_SUDO_PASSWORD" | ssh "${SSH_OPTS[@]}" "${CI_USER}@${EXPECTED_IP}" \
      "sudo -S -k -p '' bash /tmp/auvergneinfo-deploy.sh '$WEB_ROOT'"
  fi

  echo "Test HTTP depuis runner-git vers http://${EXPECTED_IP}/..."
  HTTP_OK="false"
  LAST_HTTP_CODE=""
  for _ in $(seq 1 10); do
    LAST_HTTP_CODE="$(curl -sS --connect-timeout 2 --max-time 5 -o /dev/null -w '%{http_code}' "http://${EXPECTED_IP}/" || true)"
    if [ "$LAST_HTTP_CODE" = "200" ]; then
      HTTP_OK="true"
      break
    fi
    sleep 2
  done
  [ "$HTTP_OK" = "true" ] || fail "Nginx répond localement dans la VM mais runner-git n'obtient pas HTTP 200 sur http://${EXPECTED_IP}/ (dernier code : ${LAST_HTTP_CODE:-aucun}). Vérifier UFW/nftables ou un filtrage réseau entre runner-git et la VM."
  SITE_DEPLOYED="true"
fi

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  {
    echo "vmid=${VMID}"
    echo "node=${node}"
    echo "expected_ip=${EXPECTED_IP}"
    echo "vm_status=${VM_STATUS}"
    echo "reused=${VM_REUSED}"
    echo "site_deployed=${SITE_DEPLOYED}"
  } >> "$GITHUB_OUTPUT"
fi

if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  if [ "$VM_REUSED" = "true" ]; then
    ACTION="VM existante réutilisée / site mis à jour"
  else
    ACTION="Nouvelle VM créée ou provisioning repris / site déployé"
  fi
  {
    echo "## Déploiement AuvergneInfo"
    echo ""
    echo "| Paramètre | Valeur |"
    echo "|---|---|"
    echo "| Action | ${ACTION} |"
    echo "| VMID | ${VMID} |"
    echo "| Nom | ${VM_HOSTNAME} |"
    echo "| IP | ${EXPECTED_IP}/${NETWORK_CIDR} |"
    echo "| Nœud Proxmox | ${node} |"
    echo "| VM | ${VM_STATUS} |"
    echo "| Nginx / site | ${SITE_DEPLOYED} |"
    echo "| Racine Web | ${WEB_ROOT} |"
  } >> "$GITHUB_STEP_SUMMARY"
fi