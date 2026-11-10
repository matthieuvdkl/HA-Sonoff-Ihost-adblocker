# Bloqueur de pubs pour Home Assistant sur Sonoff iHost

Dépôt d'add-on Home Assistant qui installe **AdGuard Home** sur un
**Sonoff iHost** sous Home Assistant OS (projet « HA over iHost »), avec un
guide pour configurer la box Internet et piloter le bloqueur depuis
Home Assistant.

[![Ajouter ce dépôt à Home Assistant](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Fmatthieuvdkl%2FHA-Sonoff-Ihost-adblocker)

## Pourquoi ce dépôt ?

L'iHost utilise un processeur ARM **32-bit** (Rockchip RV1126/RV1109,
architecture `armv7`). Home Assistant a arrêté le support des systèmes
32-bit avec la version 2025.12, et l'add-on communautaire « AdGuard Home »
n'est plus publié que pour `aarch64` et `amd64` : il n'apparaît donc plus
dans la boutique d'un iHost.

AdGuard Home lui-même publie toujours une version `armv7`. L'add-on de ce
dépôt est construit sur l'iHost à partir de l'image Docker officielle
`adguard/adguardhome`, sans dépendre des images 32-bit de Home Assistant.

## Ce que ça bloque (et ce que ça ne bloque pas)

AdGuard Home est un **bloqueur DNS** : il empêche les appareils de trouver
l'adresse des serveurs de pub et de pistage. Il agit sur tout le réseau,
sans rien installer sur les appareils.

| Bloqué | Pas bloqué |
| --- | --- |
| Bannières et pop-ups de la plupart des sites web | **Pubs YouTube** (servies par les mêmes serveurs que les vidéos) |
| Pubs de nombreuses applis et jeux mobiles gratuits | Pubs Twitch, posts sponsorisés Facebook / Instagram |
| Traqueurs, télémétrie des TV et objets connectés | Pubs Spotify (en grande partie), offres avec pub de Netflix / Prime Video |
| Domaines de malware et de phishing connus | Liens sponsorisés intégrés aux résultats Google |

Pour YouTube, il faut un bloqueur **sur l'appareil** :

- PC : Firefox + uBlock Origin ;
- Android : navigateur Brave, ou ReVanced / NewPipe ;
- Android TV / Google TV : SmartTube ;
- iPhone / iPad / Apple TV : peu d'options (Safari + extension de blocage),
  sinon YouTube Premium.

Les deux se complètent : AdGuard Home pour tout le réseau, un bloqueur local
pour YouTube.

## Prérequis

- Un Sonoff iHost sous **Home Assistant OS** (projet « HA over iHost »),
  avec le menu *Paramètres → Modules complémentaires*.
- Aucun autre serveur DNS sur l'iHost (ancien add-on AdGuard Home,
  Pi-hole…) : arrêtez-le pour libérer le port 53.
- Une **adresse IP fixe** pour l'iHost : réservez-la dans la box
  (bail DHCP statique), sinon les appareils perdront leur DNS si elle change.

## 1. Installer l'add-on

1. Cliquez sur le bouton « Ajouter ce dépôt » ci-dessus, ou :
   *Paramètres → Modules complémentaires → Boutique des modules
   complémentaires → ⋮ (en haut à droite) → Dépôts*, puis ajoutez
   `https://github.com/matthieuvdkl/HA-Sonoff-Ihost-adblocker`.
2. Rafraîchissez la boutique : la section « Add-ons Sonoff iHost (ARM 32-bit) »
   apparaît en bas. Ouvrez **AdGuard Home (iHost)** et cliquez sur
   **Installer** (quelques minutes : l'add-on est construit sur l'iHost).
3. Activez **Démarrage au boot** et **Watchdog**, puis **Démarrer**.

## 2. Configurer AdGuard Home

Cliquez sur **Ouvrir l'interface web** (`http://<ip-de-l-ihost>:3000`) et
suivez l'assistant :

- Interface web d'administration : toutes les interfaces, port **3000** ;
- Serveur DNS : toutes les interfaces, port **53** ;
- Créez un identifiant et un mot de passe (ils serviront aussi pour
  l'intégration Home Assistant).

Réglages conseillés ensuite (détails dans [DOCS.md](adguard_ihost/DOCS.md)) :

- **Filtres → Listes de blocage DNS** : gardez « AdGuard DNS filter » et
  ajoutez une seule liste en plus, par exemple HaGeZi Multi PRO :
  `https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/pro.txt`
- **Paramètres généraux** : rotation du journal des requêtes sur
  **24 heures**, statistiques sur **7 jours** (moins d'écritures sur la
  microSD).

Testez depuis un PC (remplacez l'IP par celle de l'iHost) :

```bash
nslookup doubleclick.net 192.168.1.50
```

La réponse doit être `0.0.0.0`.

## 3. Faire passer le réseau par AdGuard Home

Les appareils doivent utiliser l'iHost comme serveur DNS. Le plus simple est
de le faire annoncer par la box via le DHCP.

> Ne mettez **pas** de DNS secondaire public (8.8.8.8, 1.1.1.1…) à côté de
> l'iHost : les appareils l'utiliseraient au hasard et contourneraient le
> blocage. Si la box impose deux champs, mettez deux fois l'IP de l'iHost.

### Freebox

*Freebox OS → Paramètres de la Freebox → DHCP* (mode avancé) : mettez l'IP
de l'iHost en DNS 1 et videz les autres. Pour l'IPv6, voir plus bas.

### Livebox (Orange)

La Livebox ne permet pas de changer les serveurs DNS distribués par son DHCP.
Deux solutions :

1. **Réglage par appareil** : saisissez l'IP de l'iHost comme DNS dans les
   paramètres réseau du PC, du téléphone ou de la TV. Simple et sans risque,
   mais à refaire sur chaque appareil.
2. **DHCP d'AdGuard Home** : désactivez le DHCP de la Livebox, puis activez
   celui d'AdGuard Home (*Paramètres → Paramètres DHCP*). Attention :
   - fixez d'abord l'IP de l'iHost dans Home Assistant
     (*Paramètres → Système → Réseau*), car il ne pourra plus la recevoir de
     la box ;
   - le **décodeur TV Orange** attend le DHCP de la Livebox et peut perdre la
     TV ;
   - les baux statiques configurés dans la Livebox sont à recréer dans
     AdGuard Home ;
   - si l'iHost est arrêté, les appareils ne recevront plus d'adresse IP.

### Autres box (Bbox, box SFR, routeur perso)

Cherchez les « serveurs DNS » dans les réglages DHCP du réseau local. S'ils
ne sont pas modifiables, procédez comme pour la Livebox.

### IPv6 et DNS chiffré

- Si la box annonce ses propres DNS IPv6, des appareils peuvent les utiliser
  à la place de l'iHost. Si la box le permet (Freebox :
  *Configuration IPv6*), renseignez l'adresse IPv6 de l'iHost (visible dans
  *Paramètres → Système → Réseau* de Home Assistant) ; sinon désactivez
  l'annonce des DNS IPv6.
- Le « DNS sécurisé » des navigateurs, le « DNS privé » d'Android et le
  relais privé iCloud contournent AdGuard Home : désactivez-les sur les
  appareils à protéger.
- Vérification : un appareil qui n'apparaît jamais dans le *Journal des
  requêtes* d'AdGuard Home ne passe pas par lui.

## 4. Piloter le bloqueur depuis Home Assistant

### Intégration AdGuard Home

*Paramètres → Appareils et services → Ajouter une intégration →
AdGuard Home* :

- Hôte : IP de l'iHost (ex. `192.168.1.50`) ;
- Port : `3000` ;
- Identifiant / mot de passe : ceux de l'assistant AdGuard ;
- SSL et vérification du certificat : décochés.

Vous obtenez des interrupteurs (`switch.adguard_home_protection`,
`switch.adguard_home_filtering`, contrôle parental, recherche sécurisée…)
et des capteurs (`sensor.adguard_home_dns_queries`,
`sensor.adguard_home_dns_queries_blocked_ratio`…).

### Package : pause du bloqueur et alertes

[`homeassistant/packages/adguard.yaml`](homeassistant/packages/adguard.yaml)
ajoute :

- le script **`script.adguard_pause`** : coupe la protection pendant
  *N* minutes (5 par défaut) puis la réactive ;
- une automatisation qui réactive la protection si elle est restée coupée
  plus de 2 heures (par exemple après un redémarrage pendant une pause) ;
- une alerte si AdGuard Home ne répond plus, puisque tout le réseau en
  dépend pour son DNS.

Installation : ajoutez dans `configuration.yaml`

```yaml
homeassistant:
  packages: !include_dir_named packages
```

copiez le fichier dans `/config/packages/adguard.yaml` (add-on File editor ou
Samba), vérifiez la configuration et redémarrez Home Assistant.

### Carte de tableau de bord

[`homeassistant/dashboards/adguard_card.yaml`](homeassistant/dashboards/adguard_card.yaml) :
interrupteur, boutons « Pause 5 min / 30 min », compteurs et historique du
taux de blocage. *Modifier le tableau de bord → Ajouter une carte → Manuel*,
puis collez le contenu.

## Limites à connaître

- **Point unique de défaillance** : si l'iHost est arrêté ou redémarre, plus
  aucun appareil ne résout les noms de domaine. Le démarrage d'un iHost sous
  HAOS peut prendre plusieurs minutes. En cas de panne prolongée, remettez
  les DNS d'origine dans la box.
- **Home Assistant figé en 2025.11** : l'iHost étant 32-bit, Home Assistant
  n'y reçoit plus de mises à jour. Cet add-on, lui, peut continuer à suivre
  les versions d'AdGuard Home.
- **Faux positifs** : si un site ou une appli ne marche plus, regardez le
  *Journal des requêtes*, débloquez le domaine en un clic, ou utilisez
  « Pause 5 min ».

## Contenu du dépôt

```text
repository.yaml                       Déclaration du dépôt d'add-ons
adguard_ihost/                        Add-on AdGuard Home (iHost)
  config.yaml, build.yaml, Dockerfile
  run.sh                              Point d'entrée (dossiers /data, port 3000)
  DOCS.md                             Documentation affichée dans HA
homeassistant/packages/adguard.yaml   Script de pause + automatisations
homeassistant/dashboards/adguard_card.yaml  Carte Lovelace
.github/workflows/ci.yaml             Lint + build et test armv7 sous QEMU
```

## Mettre à jour AdGuard Home (mainteneur)

1. Remplacez le tag `adguard/adguardhome:vX.Y.Z` dans
   `adguard_ihost/build.yaml` et `adguard_ihost/Dockerfile`.
2. Mettez la même version dans `version:` de `adguard_ihost/config.yaml`.
3. Ajoutez une entrée dans `adguard_ihost/CHANGELOG.md`.
4. Poussez : la CI construit l'image armv7 et vérifie qu'AdGuard Home
   démarre. Home Assistant proposera ensuite la mise à jour.

## Sources

- [Home Assistant : fin du support des systèmes 32-bit](https://www.home-assistant.io/blog/2025/05/22/deprecating-core-and-supervised-installation-methods-and-32-bit-systems/)
- [Projet HA over iHost](https://community.home-assistant.io/t/ha-over-ihost-open-source-project-is-officially-live-try-it-out-and-join-the-community/878028)
- [Add-on communautaire AdGuard Home](https://github.com/hassio-addons/addon-adguard-home)
- [AdGuard Home : image Docker](https://github.com/AdguardTeam/AdGuardHome/wiki/Docker)
- [Intégration AdGuard Home de Home Assistant](https://www.home-assistant.io/integrations/adguard)
- [Listes de blocage HaGeZi](https://github.com/hagezi/dns-blocklists)
