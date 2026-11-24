# =============================================================================
# Dotmatics Platform 6.2 — APPLICATION image
# Expects at runtime:
#   /mnt/dotmatics/Dotmatics_Platform_6.2.zip   (the Dotmatics zip)
#   /mnt/dotmatics/config/                      (optional config overrides)
# =============================================================================
FROM dotmatics-base:6.2

LABEL org.opencontainers.image.title="dotmatics-app" \
      org.opencontainers.image.description="Dotmatics Platform 6.2 application" \
      com.dotmatics.platform.version="6.2"

ENV DOTMATICS_ZIP=/mnt/dotmatics/Dotmatics_Platform_6.2.zip \
    DOTMATICS_CONFIG_DIR=/mnt/dotmatics/config \
    DOTMATICS_DATA_DIR=/home/dotmatics/dotmatics/data

COPY --chown=dotmatics:dotmatics --chmod=0755 docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

# Persistent document uploads (§6.9.3)
VOLUME ["/home/dotmatics/dotmatics/data"]

EXPOSE 8080 8443

HEALTHCHECK --interval=30s --timeout=10s --start-period=240s --retries=3 \
  CMD bash -c 'exec 3<>/dev/tcp/127.0.0.1/8080' || exit 1

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["catalina.sh", "run"]

# Build:  docker build -t dotmatics-app:6.2 -f Dockerfile.app .
