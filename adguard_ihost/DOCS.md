# AdGuard Home (iHost)

AdGuard Home répond aux requêtes DNS de tous les appareils du réseau et
renvoie une adresse vide (`0.0.0.0`) pour les domaines de publicité et de
pistage. Rien à installer sur les téléphones, PC ou TV : il suffit qu'ils
utilisent l'iHost comme serveur DNS.

## Installation

1. Installez l'add-on puis cliquez sur **Démarrer**. La première installation
   prend quelques minutes : l'add-on est construit sur l'iHost.
2. Cliquez sur **Ouvrir l'interface web** (ou allez sur
   `http://<ip-de-l-ihost>:3000`).
3. Suivez l'assistant d'AdGuard Home :
   - **Interface web d'administration** : « Toutes les interfaces », port
     **3000**. Gardez 3000 : c'est le port utilisé par le bouton
     « Ouvrir l'interface web » et par l'intégration Home Assistant.
   - **Serveur DNS** : « Toutes les interfaces », port **53**.
   - Choisissez un nom d'utilisateur et un mot de passe.
4. Activez **Démarrage au boot** et **Watchdog** dans l'onglet Info de
   l'add-on.

> Si vous laissez le port 80 dans l'assistant, l'interface passera
> temporairement sur le port 80, puis reviendra sur le port 3000 au prochain
> redémarrage de l'add-on.

## Réglages recommandés

Dans l'interface d'AdGuard Home :

- **Filtres → Listes de blocage DNS** : gardez « AdGuard DNS filter » et
  ajoutez au plus une ou deux listes, par exemple
  « HaGeZi's Multi PRO »
  (`https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/pro.txt`).
  Empiler trop de listes augmente la mémoire utilisée et les faux positifs.
- **Paramètres → Paramètres généraux** :
  - Rotation du journal des requêtes : **24 heures** ;
  - Conservation des statistiques : **7 jours**.

  L'iHost sous HAOS tourne sur carte microSD : limiter le journal réduit les
  écritures.
- **Paramètres → Paramètres DNS** : les serveurs DNS en amont par défaut
  (Quad9 en DNS-over-HTTPS) conviennent. Vous pouvez en ajouter un second,
  par exemple `https://cloudflare-dns.com/dns-query`.

## Données et sauvegardes

- Configuration : `/data/conf/AdGuardHome.yaml` (dans le volume de l'add-on).
- Données : `/data/work` (statistiques, journal, listes téléchargées).

Les sauvegardes Home Assistant incluent la configuration et les statistiques.
Le journal des requêtes et les listes de blocage en sont exclus : ils sont
volumineux et se reconstruisent tout seuls.

## Mises à jour

AdGuard Home ne se met pas à jour lui-même dans cet add-on : la version suit
celle de l'add-on. Une nouvelle version de l'add-on apparaît dans
Home Assistant quand ce dépôt est mis à jour.

## Dépannage

- **L'assistant indique que le port 53 est occupé** : un autre serveur DNS
  tourne sur l'iHost (ancien add-on AdGuard Home, Pi-hole, dnsmasq…).
  Arrêtez-le, puis redémarrez cet add-on.
- **Rien n'est bloqué** : l'appareil n'utilise pas l'iHost comme DNS.
  Vérifiez la configuration de la box (voir le guide du dépôt) et désactivez
  le « DNS sécurisé » du navigateur ou le « DNS privé » d'Android.
- **Plus d'accès à Internet sur le réseau** : l'iHost est arrêté ou redémarre
  (le démarrage peut prendre plusieurs minutes). Patientez ou remettez
  temporairement les DNS d'origine dans la box.

Guide complet (box Internet, intégration Home Assistant, tableau de bord) :
<https://github.com/matthieuvdkl/HA-Sonoff-Ihost-adblocker>
