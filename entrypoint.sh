#!/bin/bash
# entrypoint.sh - Orchestration script for the Indico application.
#
# This script prepares the Indico environment by:
# 1. Validating that all required environment variables are set.
# 2. Mapping environment variables to technical standards.
# 3. Merging configuration templates with user-provided overrides.
# 4. Waiting for the PostgreSQL database to become available.
# 5. Performing database initialization and migrations.
# 6. Starting background services (Celery and uWSGI) and monitoring them.

set -e

# --- Environment Check ---
# Verify that all mandatory environment variables are set before proceeding.
# This prevents runtime errors related to missing configuration.
required_vars=(
  INDICO_POSTGRES_HOST
  INDICO_POSTGRES_DB
  INDICO_POSTGRES_USER
  INDICO_POSTGRES_PASSWORD
  INDICO_REDIS_CACHE_URL
  INDICO_CELERY_BROKER
  INDICO_SECRET_KEY
  INDICO_BASE_URL
  INDICO_NO_REPLY_EMAIL
  INDICO_SUPPORT_EMAIL
)

missing_vars=()
for var in "${required_vars[@]}"; do
  if [[ -z "${!var}" ]]; then
    missing_vars+=("$var")
  fi
done

if [[ ${#missing_vars[@]} -gt 0 ]]; then
  echo "[ERROR] The following mandatory environment variables are not set:"
  for var in "${missing_vars[@]}"; do
    echo "  - $var"
  done
  exit 1
fi

# --- Environment Mapping ---
# Map INDICO_ variables to standard PostgreSQL environment variables (PGHOST, etc.).
# This allows standard tools like `psql` to authenticate without explicit command-line arguments.
export PGHOST="${INDICO_POSTGRES_HOST}"
export PGDATABASE="${INDICO_POSTGRES_DB}"
export PGUSER="${INDICO_POSTGRES_USER}"
export PGPASSWORD="${INDICO_POSTGRES_PASSWORD}"

# --- Configuration Merging ---
# Indico expects a single configuration file. We combine a generated template
# (containing container-specific defaults) with the user-provided /etc/indico.conf
# to allow for flexible runtime configuration while maintaining core defaults.
export INDICO_CONFIG=/tmp/indico.conf
cp /etc/indico.tmpl.conf /tmp/indico.conf
[[ -f /etc/indico.conf ]] && cat /etc/indico.conf >> /tmp/indico.conf
echo "del read_file" >> /tmp/indico.conf # remove utility function

# Prefix standard output with a custom label to distinguish between multiple services
# running within the same container logs.
prefix_output() {
  local prefix="$1"
  sed --unbuffered "s/^/[$prefix] /"
}

# Logger for the entrypoint itself for uniform status reporting.
log() {
  echo "[ENTRY] $1"
}

# --- Database Wait Loop ---
# PostgreSQL may take longer to start than the application container.
# We poll the database using `psql` to ensure connectivity before attempting migrations.
until psql -c '\q' > /dev/null 2>&1; do
  log "Waiting for database connection..."
  sleep 2
done

# --- Initialization & Migrations ---
# Check if the 'events' schema exists to determine if the database is already initialized.
# If not, we install required extensions and run 'db prepare' to set up the schema.
if ! psql -c 'SELECT count(*) FROM events.events LIMIT 1' > /dev/null 2>&1; then
    log "Preparing database..."
    psql -c 'CREATE EXTENSION IF NOT EXISTS unaccent;' > /dev/null 2>&1
    psql -c 'CREATE EXTENSION IF NOT EXISTS pg_trgm;' > /dev/null 2>&1

    log "Running indico db prepare..."
    indico db prepare
fi

# Automatically apply any pending migrations for the core application and all plugins.
log "Executing database upgrades..."
indico db upgrade > /dev/null

log "Executing plugin database migrations..."
indico db --all-plugins upgrade

# --- Signal-Handling ---
terminate() {
  log "Terminating background processes..."
  kill $(jobs -p)
  wait
}
trap terminate SIGTERM SIGINT

# --- Service Management ---
# Both Celery (for background tasks) and uWSGI (the web server) are started
# in the background. Standard output and error are piped through `prefix_output`
# to ensure logs are clearly attributed to each service.
log "Starting Indico celery worker..."
indico celery worker -B 2>&1 | prefix_output "CELERY" &

log "Starting Indico uWSGI..."
uwsgi --ini /etc/uwsgi-indico.ini 2>&1 | prefix_output "UWSGI" &

# `wait -n` monitors all background jobs and returns as soon as ANY process exits.
# This ensures that if either Celery or uWSGI fails, the container itself exits
# with the error code, allowing the orchestrator (e.g., Docker Compose/K8s) to restart it.
wait -n

exit $?