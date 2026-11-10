#!/usr/bin/env bash
# Test de fumée de l'add-on AdGuard Home (iHost), tel que le lance le
# Supervisor : /data vide au premier démarrage, assistant de configuration,
# puis vérification qu'un domaine de pub est bien bloqué.
#
# Usage : tests/smoke_test.sh <image> [plateforme]
#   ex. : tests/smoke_test.sh adguard_ihost:test linux/arm/v7
set -euo pipefail

IMAGE="${1:?image Docker à tester}"
PLATFORM="${2:-linux/amd64}"
HOST_PORT="${HOST_PORT:-3000}"
NAME="adguard_ihost_smoke"
USER_NAME="smoke"
USER_PASS="smoke-test-password"
DATA_DIR="$(mktemp -d)"
BASE_URL="http://127.0.0.1:${HOST_PORT}"

cleanup() {
  echo "--- journal du conteneur"
  docker logs "${NAME}" 2>&1 | tail -n 30 || true
  docker rm -f "${NAME}" >/dev/null 2>&1 || true
}
trap cleanup EXIT

wait_for() {
  local url="$1"
  for _ in $(seq 1 90); do
    if curl -fsS -o /dev/null "${url}"; then
      return 0
    fi
    sleep 2
  done
  echo "ÉCHEC : ${url} ne répond pas" >&2
  return 1
}

echo "--- démarrage de ${IMAGE} (${PLATFORM}) avec /data vide"
docker rm -f "${NAME}" >/dev/null 2>&1 || true
docker run -d --name "${NAME}" --platform "${PLATFORM}" \
  -p "${HOST_PORT}:3000" -v "${DATA_DIR}:/data" "${IMAGE}" >/dev/null

echo "--- l'assistant de premier démarrage répond sur le port 3000"
wait_for "${BASE_URL}/install.html"

echo "--- configuration via l'API de l'assistant"
curl -fsS -X POST "${BASE_URL}/control/install/configure" \
  -H 'Content-Type: application/json' \
  -d "{\"web\":{\"ip\":\"0.0.0.0\",\"port\":3000},\"dns\":{\"ip\":\"0.0.0.0\",\"port\":53},\"username\":\"${USER_NAME}\",\"password\":\"${USER_PASS}\"}"
echo

echo "--- AdGuard Home tourne et la protection est active"
wait_for "${BASE_URL}/login.html"
status="$(curl -fsS -u "${USER_NAME}:${USER_PASS}" "${BASE_URL}/control/status")"
echo "${status}"
grep -q '"running":true' <<<"${status}"
grep -q '"protection_enabled":true' <<<"${status}"

echo "--- un domaine de pub est bloqué (règle locale, sans dépendre d'Internet)"
curl -fsS -u "${USER_NAME}:${USER_PASS}" -X POST \
  "${BASE_URL}/control/filtering/set_rules" \
  -H 'Content-Type: application/json' \
  -d '{"rules":["||doubleclick.net^"]}'
answer=""
for _ in $(seq 1 15); do
  answer="$(docker exec "${NAME}" nslookup -type=a ad.doubleclick.net 127.0.0.1 2>&1 || true)"
  if grep -q 'Address: 0\.0\.0\.0' <<<"${answer}"; then
    break
  fi
  sleep 2
done
echo "${answer}"
grep -q 'Address: 0\.0\.0\.0' <<<"${answer}"

echo "--- la configuration est persistée dans /data et survit au redémarrage"
docker restart "${NAME}" >/dev/null
wait_for "${BASE_URL}/login.html"
curl -fsS -o /dev/null -u "${USER_NAME}:${USER_PASS}" "${BASE_URL}/control/status"

echo "OK : test de fumée réussi (${PLATFORM})"
