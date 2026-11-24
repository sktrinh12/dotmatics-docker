# Dotmatics Docker Images (Amazon Linux 2)

Production-ready container images for the Dotmatics Platform 6.2 web server, built on Amazon Linux 2 (RHEL-compatible).

## Files

| File | Purpose |
|------|---------|
| `Dockerfile.base` | Reusable base image: Corretto 11, Tomcat 8.5, OpenBabel (built from source), fonts, non-root user |
| `Dockerfile.app`  | Thin application image — mounts the Dotmatics zip at runtime |
| `docker-entrypoint.sh` | Idempotent deploy script (extracts WARs, applies config overrides) |

## Prerequisites

- The **Dotmatics Platform 6.2 zip** from the support portal (not included — proprietary)
- A running **Oracle database** with the **Pinpoint cartridge** installed. ⚠️ Pinpoint must be installed on the DB server **before** starting this container (doc §6.3).
- A valid **Dotmatics license file** (`license.lic`)

## Build

```bash
# 1. Build the base (only when Java/Tomcat/OpenBabel versions change)
docker build -t dotmatics-base:6.2 -f Dockerfile.base .

# 2. Build the app (rebuild on every Dotmatics release)
docker build -t dotmatics-app:6.2 -f Dockerfile.app .
```

## Runtime

Prepare a mount directory:

```
/srv/dotmatics/
├── Dotmatics_Platform_6.2.zip        # the proprietary zip
└── config/                            # optional config overrides
    ├── license.lic
    ├── browser/browser.properties             # §6.5.2
    ├── platformservices/browser.properties    # §6.6.5
    └── bioregister/bioregister.properties     # §6.7.3
```

Run:

```bash
docker run -d --name dotmatics \
  -p 8080:8080 \
  -v /srv/dotmatics/Dotmatics_Platform_6.2.zip:/mnt/dotmatics/Dotmatics_Platform_6.2.zip:ro \
  -v /srv/dotmatics/config:/mnt/dotmatics/config:ro \
  -v /srv/dotmatics/data:/home/dotmatics/dotmatics/data \
  -e DOTMATICS_JAVA_OPTS="-Xmx4g -XX:+UseG1GC" \
  dotmatics-app:6.2
```

| Env var | Default | Purpose |
|---------|---------|---------|
| `DOTMATICS_ZIP` | `/mnt/dotmatics/Dotmatics_Platform_6.2.zip` | Path to the Dotmatics zip |
| `DOTMATICS_CONFIG_DIR` | `/mnt/dotmatics/config` | Override directory |
| `DOTMATICS_JAVA_OPTS` | `-Xmx2048m -XX:+UseG1GC` | Tomcat heap/GC options |
| `DOTMATICS_FORCE_REDEPLOY` | `0` | Set to `1` to re-extract the zip (e.g. after an upgrade) |

Document uploads persist in the `data` volume (§6.9.3).

## Notes

- **OpenBabel** is built from source (3.2.1) with Python bindings, required for CDXML support (§6.4). The build applies the standard upstream patches for the `HAVE_EIGEN3` SWIG issue — no manual patching needed.
- **Fonts**: DejaVu and Liberation font families are pre-installed (§6.5.4) for chemical structure rendering in PDFs.
- **TLS**: the container listens on plain HTTP `8080`. Terminate TLS at a reverse proxy or ALB (§6.2.7 / Appendix F).
- **Non-root**: Tomcat runs as user `dotmatics` (UID 1000) — compatible with `runAsNonRoot` and OpenShift restricted SCCs.
- **Oracle DB configuration** (SID/PDB, credentials, TNS alias) is provided at runtime via `browser.properties` overrides — nothing is hard-coded in the image. If your PDB is not `orclpdb`, update `browser.properties` accordingly (doc §2.2).
- **Upgrading**: replace the mounted zip and restart with `-e DOTMATICS_FORCE_REDEPLOY=1`.

## Version Pins

| Component | Version |
|-----------|---------|
| Java | Amazon Corretto 11.0.14.9-1 |
| Tomcat | 8.5.77 |
| OpenBabel | 3.2.1 |
| Dotmatics Platform | 6.2 |
