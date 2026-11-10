ARG BUILD_FROM=adguard/adguardhome:v0.107.80
# hadolint ignore=DL3006
FROM ${BUILD_FROM}

COPY run.sh /run.sh
RUN chmod a+x /run.sh

# Répond pendant l'assistant de premier démarrage comme après la configuration
# (redirection vers /install.html ou /login.html). Utilisé par le watchdog du
# Supervisor s'il est activé.
HEALTHCHECK --interval=60s --timeout=10s --start-period=60s --retries=3 \
    CMD wget -q -O /dev/null http://127.0.0.1:3000/ || exit 1

ENTRYPOINT ["/run.sh"]
CMD []
