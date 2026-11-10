#!/bin/sh
# Point d'entrée de l'add-on AdGuard Home pour Sonoff iHost.
#
# /data est le volume persistant fourni par le Supervisor. Il est vide au
# premier démarrage, or AdGuard Home refuse de démarrer si son dossier de
# travail n'existe pas ("failed to init working directory").
set -eu

CONF_DIR=/data/conf
WORK_DIR=/data/work

# 0700 : permissions attendues par AdGuard Home (évite les avertissements
# "permcheck" au démarrage).
mkdir -p "${CONF_DIR}" "${WORK_DIR}"
chmod 0700 "${CONF_DIR}" "${WORK_DIR}"

echo "[adguard_ihost] Démarrage d'AdGuard Home sur $(uname -m)"
echo "[adguard_ihost] Interface web : http://<ip-de-l-ihost>:3000"

# --web-addr force l'interface sur le port 3000 quel que soit le choix fait
# dans l'assistant, pour que le bouton "Ouvrir l'interface web" fonctionne.
# --no-check-update : les mises à jour passent par la version de l'add-on.
exec /opt/adguardhome/AdGuardHome \
    --no-check-update \
    --config "${CONF_DIR}/AdGuardHome.yaml" \
    --work-dir "${WORK_DIR}" \
    --web-addr 0.0.0.0:3000
