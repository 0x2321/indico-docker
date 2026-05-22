# 🐳 indico-docker

[![Codeberg](https://img.shields.io/badge/Main_Repo-Codeberg-blue?logo=codeberg)](https://codeberg.org/0x2321/indico-docker)

A production-ready containerized version of [Indico](https://getindico.io), the open-source event management system.

## 📦 Images

The following images are available and hosted on Codeberg:

| Image                                       | Description                                                |
|:--------------------------------------------|:-----------------------------------------------------------|
| `codeberg.org/0x2321/indico-docker:3`       | **Standard** Indico installation.                          |
| `codeberg.org/0x2321/indico-docker:3-latex` | Indico installation with **PDF support** (includes XeTeX). |

## 🛠️ Quickstart

The fastest way to get a production-ready Indico instance running is using our pre-configured [**example stack**](./example). It includes a database, redis, and a reverse proxy with SSL support.

## ⚙️ Configuration

The container is configured using environment variables. These are used to **automatically generate** the core configuration during startup.

### Database
| Variable                   | Description                           | Example           |
|:---------------------------|:--------------------------------------|:------------------|
| `INDICO_POSTGRES_HOST`     | Hostname of the PostgreSQL database.  | `postgres`        |
| `INDICO_POSTGRES_USER`     | Username for the PostgreSQL database. | `indico`          |
| `INDICO_POSTGRES_PASSWORD` | Password for the PostgreSQL database. | `secure-password` |
| `INDICO_POSTGRES_DB`       | Name of the PostgreSQL database.      | `indico`          |

### App
| Variable                 | Description                        | Example                       |
|:-------------------------|:-----------------------------------|:------------------------------|
| `INDICO_SECRET_KEY`      | Secret key for Indico sessions.    | `openssl rand -hex 32`        |
| `INDICO_BASE_URL`        | Public URL of the Indico instance. | `https://indico.example.com/` |
| `INDICO_REDIS_CACHE_URL` | Redis connection URL for caching.  | `redis://redis:6379/0`        |
| `INDICO_CELERY_BROKER`   | Redis connection URL for Celery.   | `redis://redis:6379/1`        |
| `INDICO_NO_REPLY_EMAIL`  | No-reply email address.            | `noreply@example.invalid`     |
| `INDICO_SUPPORT_EMAIL`   | Support email address.             | `suppport@example.invalid`    |
| `INDICO_STORAGE_DIR`     | Internal storage path (optional).  | `/data` (Default)             |

## 🛠️ Advanced Configuration

Indico's configuration in this container is split into two parts:

1.  **Core Configuration (Automatic)**:
    Basic settings (Database, Secret Key, Base URL, Storage) are automatically generated from the environment variables above.

2.  **Custom Overrides (`indico.conf`)**:
    If you need to configure **additional** settings (like SMTP, LDAP, or Plugins), you can mount a custom configuration file to `/etc/indico.conf`. Settings in this file will take precedence over the automatically generated defaults.

## 💾 Persistence

To ensure your data survives container restarts, make sure to mount a persistent volume to:
- `/data`: This directory stores all uploaded files, attachments, and images.