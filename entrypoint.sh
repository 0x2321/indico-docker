#!/bin/bash
set -e

export PGHOST="${INDICO_POSTGRES_HOST}"
export PGDATABASE="${INDICO_POSTGRES_DB}"
export PGUSER="${INDICO_POSTGRES_USER}"
export PGPASSWORD="${INDICO_POSTGRES_PASSWORD}"

export INDICO_CONFIG=/tmp/indico.conf
cat /etc/indico.tmpl.conf /etc/indico.conf > /tmp/indico.conf

if [ $# -gt 0 ]; then
    exec indico "$@"
fi

# Prefix standard output with a custom label
prefix_output() {
  local prefix="$1"
  sed --unbuffered "s/^/[$prefix] /"
}

# Logger for the entrypoint itself
log() {
  echo "[ENTRY] $1"
}

# Wait for database connection
until psql -c '\q' > /dev/null 2>&1; do
  log "Waiting for database connection..."
  sleep 2
done

# Initialize database if needed
if ! psql -c 'SELECT count(*) FROM events.events LIMIT 1' > /dev/null 2>&1; then
    log "Preparing database..."
    psql -c 'CREATE EXTENSION IF NOT EXISTS unaccent;' > /dev/null 2>&1
    psql -c 'CREATE EXTENSION IF NOT EXISTS pg_trgm;' > /dev/null 2>&1

    log "Running indico db prepare..."
    indico db prepare
fi

log "Executing database upgrades..."
indico db upgrade > /dev/null

log "Executing plugin database migrations..."
indico db --all-plugins upgrade

# Signal-Handling: Beendet alle Hintergrundprozesse bei SIGTERM
terminate() {
  log "Terminating background processes..."
  kill $(jobs -p)
  wait
}
trap terminate SIGTERM SIGINT

# Start services in the background
log "Starting Indico celery worker..."
indico celery worker -B 2>&1 | prefix_output "CELERY" &

log "Starting Indico uWSGI..."
uwsgi --ini /etc/uwsgi-indico.ini 2>&1 | prefix_output "UWSGI" &

# Wait for background services
wait -n

exit $?