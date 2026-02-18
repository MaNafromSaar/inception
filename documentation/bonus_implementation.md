# Bonus Implementation Attestation

This document attests to the presence and implementation of all required bonus services in the Inception project.

---

## Redis Cache
- Implemented: Yes
- Location: `srcs/requirements/redis/` (Dockerfile, config, entrypoint)
- Usage: WordPress connects to Redis for caching via environment variables in `.env`.

## FTP Server
- Implemented: Yes
- Location: `srcs/requirements/ftp/` (Dockerfile, config, entrypoint)
- Usage: FTP server points to the WordPress volume for file access.

## Static Website
- Implemented: Yes
- Location: `html/` directory, served by NGINX
- Usage: Accessible via a subdomain or path, not using PHP.

## Adminer
- Implemented: Yes
- Location: `srcs/requirements/adminer/` (Dockerfile, config)
- Usage: Accessible via subdomain (e.g., adminer.<domain>), manages MariaDB.

## Extra Service
- Implemented: Not present (intentionally left simple as per user request)
- Justification: All required bonuses are present; no additional service added for simplicity and maintainability.

---

All bonus requirements except the optional extra service are fully implemented and integrated into the project.
