# 🚀 indico-docker

A production-ready containerized version of [Indico](https://getindico.io), the open-source event management system.

## 📦 Images

The following images are available and hosted on Codeberg:

| Image | Description |
| :--- | :--- |
| `codeberg.org/0x2321/indico-docker:latest` | **Standard** Indico installation. |
| `codeberg.org/0x2321/indico-docker:latest-latex` | Indico installation with **PDF support** (includes XeTeX). |

## 🚀 Quickstart

For a complete, functional setup, please refer to the [**/example**](./example) folder. It includes:
- `compose.yaml`: Full orchestration of Indico, PostgreSQL, Redis, and Caddy.
- `Caddyfile`: Reverse proxy configuration for SSL and static file serving.
- `indico.conf`: Additional Indico configuration overrides.

## ⚙️ Configuration

The container is configured using environment variables. Below are the required variables to get started:

### Database
| Variable | Description | Example |
| :--- | :--- | :--- |
| `PGHOST` | Hostname of the PostgreSQL database. | `postgres` |
| `PGUSER` | Username for the PostgreSQL database. | `indico` |
| `PGPASSWORD` | Password for the PostgreSQL database. | `secure-password` |
| `PGDATABASE` | Name of the PostgreSQL database. | `indico` |

### App
| Variable | Description | Example |
| :--- | :--- | :--- |
| `SECRET_KEY` | Secret key for Indico sessions. | `random-string` |
| `BASE_URL` | Public URL of the Indico instance. | `https://indico.example.com/` |
