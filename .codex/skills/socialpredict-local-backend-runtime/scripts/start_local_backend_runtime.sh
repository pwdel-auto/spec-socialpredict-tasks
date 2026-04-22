#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_LIB_DIR="$(cd "$SCRIPT_DIR/../../lib" && pwd)"
# shellcheck source=../../lib/socialpredict_backend_common.sh
source "$SKILLS_LIB_DIR/socialpredict_backend_common.sh"

usage() {
  cat <<'EOF'
Usage: start_local_backend_runtime.sh [repo-dir] <check|start|status|stop>

Starts or checks a non-Docker local SocialPredict backend runtime for
Schemathesis and other runtime API conformance tests.
EOF
}

if [ "$#" -lt 1 ]; then
  usage >&2
  exit 2
fi

case "${1:-}" in
  check|start|status|stop)
    REPO_DIR="$(resolve_target_repo_dir "")"
    COMMAND="$1"
    ;;
  *)
    REPO_DIR="$(resolve_target_repo_dir "$1")"
    COMMAND="${2:-}"
    ;;
esac

if [ -z "$COMMAND" ]; then
  usage >&2
  exit 2
fi

BACKEND_DIR="$(require_backend_dir "$REPO_DIR")"
BACKEND_DIR="$(cd "$BACKEND_DIR" && pwd)"
REPO_DIR="$(cd "$BACKEND_DIR/.." && pwd)"
ENV_EXAMPLE="$REPO_DIR/.env.example"
ENV_FILE="$REPO_DIR/.env"

STATE_DIR="${SOCIALPREDICT_RUNTIME_STATE_DIR:-${TMPDIR:-/tmp}/socialpredict-local-backend-runtime}"
PGDATA_DIR="$STATE_DIR/pgdata"
PGSOCKET_DIR="$STATE_DIR/pgsocket"
LOG_DIR="$STATE_DIR/logs"
BACKEND_PID_FILE="$STATE_DIR/backend.pid"
POSTGRES_PID_FILE="$STATE_DIR/postgres.pid"

mkdir -p "$STATE_DIR" "$PGSOCKET_DIR" "$LOG_DIR"

WORKSPACE_DIR="$(cd "$REPO_DIR/.." && pwd)"

set_default_dir_var() {
  local var_name="$1"
  local preferred_dir="$2"
  local fallback_dir="$3"
  if [ -z "${!var_name:-}" ]; then
    if [ -d "$preferred_dir" ]; then
      printf -v "$var_name" '%s' "$preferred_dir"
    else
      printf -v "$var_name" '%s' "$fallback_dir"
      mkdir -p "$fallback_dir"
    fi
    export "$var_name"
  fi
}

set_default_dir_var GOPATH "$WORKSPACE_DIR/.gopath" "$STATE_DIR/gopath"
set_default_dir_var GOMODCACHE "$WORKSPACE_DIR/.gomodcache" "$STATE_DIR/gomodcache"
set_default_dir_var GOCACHE "$WORKSPACE_DIR/.gocache" "$STATE_DIR/gocache"
set_default_dir_var GOTMPDIR "$WORKSPACE_DIR/.tmp-go" "$STATE_DIR/gotmp"

load_env_file() {
  local path="$1"
  if [ -f "$path" ]; then
    set -a
    # shellcheck disable=SC1090
    source "$path"
    set +a
  fi
}

load_env_file "$ENV_EXAMPLE"
load_env_file "$ENV_FILE"

BACKEND_PORT="${BACKEND_PORT:-8080}"
DB_PORT="${DB_PORT:-${POSTGRES_PORT:-5432}}"
POSTGRES_USER="${POSTGRES_USER:-${DB_USER:-user}}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-${DB_PASSWORD:-${DB_PASS:-password}}}"
POSTGRES_DATABASE="${POSTGRES_DATABASE:-${POSTGRES_DB:-${DB_NAME:-socialpredict_db}}}"
DB_HOST="${DB_HOST:-${DBHOST:-127.0.0.1}}"

if [ "$DB_HOST" = "db" ]; then
  DB_HOST="127.0.0.1"
fi

BASE_URL="http://127.0.0.1:$BACKEND_PORT"

has_command() {
  command -v "$1" >/dev/null 2>&1
}

health_ok() {
  has_command curl && curl --fail --silent --show-error --max-time 3 "$BASE_URL/health" >/dev/null 2>&1
}

postgres_ok() {
  if has_command pg_isready; then
    PGPASSWORD="$POSTGRES_PASSWORD" pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DATABASE" >/dev/null 2>&1
    return $?
  fi
  return 1
}

postgres_server_ok() {
  if has_command pg_isready; then
    PGPASSWORD="$POSTGRES_PASSWORD" pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$POSTGRES_USER" -d postgres >/dev/null 2>&1
    return $?
  fi
  return 1
}

print_config() {
  echo "Backend dir: $BACKEND_DIR"
  echo "Backend URL: $BASE_URL"
  echo "DB host: $DB_HOST"
  echo "DB port: $DB_PORT"
  echo "DB user: ${POSTGRES_USER:+set}"
  echo "DB name: ${POSTGRES_DATABASE:+set}"
  echo "DB password: ${POSTGRES_PASSWORD:+set}"
  echo "State dir: $STATE_DIR"
}

pid_running() {
  local pid_file="$1"
  [ -f "$pid_file" ] || return 1
  local pid
  pid="$(cat "$pid_file")"
  [ -n "$pid" ] || return 1
  process_running "$pid"
}

process_running() {
  local pid="$1"
  kill -0 "$pid" >/dev/null 2>&1 || return 1
  if has_command ps; then
    local state
    state="$(ps -p "$pid" -o stat= 2>/dev/null || true)"
    case "$state" in
      Z*) return 1 ;;
    esac
  fi
  return 0
}

process_group_running() {
  local pgid="$1"
  has_command ps || return 1
  local process_pgid
  local process_state
  while read -r process_pgid process_state; do
    if [ "$process_pgid" = "$pgid" ]; then
      case "$process_state" in
        Z*) ;;
        *) return 0 ;;
      esac
    fi
  done < <(ps -eo pgid=,stat= 2>/dev/null)
  return 1
}

cleanup_stale_postgres_state() {
  local postmaster_pid_file="$PGDATA_DIR/postmaster.pid"
  [ -f "$postmaster_pid_file" ] || return 0
  local postmaster_pid
  postmaster_pid="$(head -n 1 "$postmaster_pid_file" 2>/dev/null || true)"
  if [ -z "$postmaster_pid" ] || ! process_running "$postmaster_pid"; then
    rm -f "$postmaster_pid_file" "$PGSOCKET_DIR/.s.PGSQL.$DB_PORT" "$PGSOCKET_DIR/.s.PGSQL.$DB_PORT.lock"
  fi
}

start_postgres_if_needed() {
  if postgres_ok; then
    echo "Postgres is reachable at $DB_HOST:$DB_PORT."
    return 0
  fi

  if pid_running "$POSTGRES_PID_FILE"; then
    echo "Postgres PID is recorded but readiness failed. See $LOG_DIR/postgres.log" >&2
    return 1
  fi

  for cmd in initdb postgres pg_isready createdb; do
    if ! has_command "$cmd"; then
      echo "Postgres is not reachable, and '$cmd' is not installed." >&2
      echo "Start Postgres externally or install local Postgres binaries." >&2
      return 1
    fi
  done

  if [ ! -d "$PGDATA_DIR/base" ]; then
    rm -rf "$PGDATA_DIR"
    initdb -D "$PGDATA_DIR" -U "$POSTGRES_USER" --auth=trust >/dev/null
  else
    cleanup_stale_postgres_state
  fi

  if has_command setsid; then
    setsid postgres -D "$PGDATA_DIR" -h "$DB_HOST" -p "$DB_PORT" -k "$PGSOCKET_DIR" >"$LOG_DIR/postgres.log" 2>&1 </dev/null &
  else
    nohup postgres -D "$PGDATA_DIR" -h "$DB_HOST" -p "$DB_PORT" -k "$PGSOCKET_DIR" >"$LOG_DIR/postgres.log" 2>&1 </dev/null &
  fi
  echo "$!" >"$POSTGRES_PID_FILE"

  for _ in $(seq 1 30); do
    if postgres_server_ok; then
      break
    fi
    sleep 1
  done

  if ! postgres_server_ok; then
    echo "Ephemeral Postgres did not become ready. See $LOG_DIR/postgres.log" >&2
    return 1
  fi

  PGPASSWORD="$POSTGRES_PASSWORD" createdb -h "$DB_HOST" -p "$DB_PORT" -U "$POSTGRES_USER" "$POSTGRES_DATABASE" >/dev/null 2>&1 || true

  if ! postgres_ok; then
    echo "Ephemeral Postgres is running, but target database is not reachable. See $LOG_DIR/postgres.log" >&2
    return 1
  fi

  echo "Started ephemeral Postgres at $DB_HOST:$DB_PORT."
}

start_backend_if_needed() {
  if health_ok; then
    echo "Backend is already healthy at $BASE_URL."
    return 0
  fi

  if pid_running "$BACKEND_PID_FILE"; then
    echo "Backend PID is recorded but health check failed. See $LOG_DIR/backend.log" >&2
    return 1
  fi

  if ! has_command go; then
    echo "go is required to start the backend but is not installed." >&2
    return 1
  fi

  (
    cd "$BACKEND_DIR"
    if has_command setsid; then
      setsid env \
      DB_HOST="$DB_HOST" \
      DB_PORT="$DB_PORT" \
      DB_USER="$POSTGRES_USER" \
      DB_PASSWORD="$POSTGRES_PASSWORD" \
      DB_NAME="$POSTGRES_DATABASE" \
      POSTGRES_USER="$POSTGRES_USER" \
      POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
      POSTGRES_DATABASE="$POSTGRES_DATABASE" \
      BACKEND_PORT="$BACKEND_PORT" \
      GOPATH="$GOPATH" \
      GOMODCACHE="$GOMODCACHE" \
      GOCACHE="$GOCACHE" \
      GOTMPDIR="$GOTMPDIR" \
      go run . >"$LOG_DIR/backend.log" 2>&1 </dev/null &
    else
      nohup env \
      DB_HOST="$DB_HOST" \
      DB_PORT="$DB_PORT" \
      DB_USER="$POSTGRES_USER" \
      DB_PASSWORD="$POSTGRES_PASSWORD" \
      DB_NAME="$POSTGRES_DATABASE" \
      POSTGRES_USER="$POSTGRES_USER" \
      POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
      POSTGRES_DATABASE="$POSTGRES_DATABASE" \
      BACKEND_PORT="$BACKEND_PORT" \
      GOPATH="$GOPATH" \
      GOMODCACHE="$GOMODCACHE" \
      GOCACHE="$GOCACHE" \
      GOTMPDIR="$GOTMPDIR" \
      go run . >"$LOG_DIR/backend.log" 2>&1 </dev/null &
    fi
    echo "$!" >"$BACKEND_PID_FILE"
  )

  for _ in $(seq 1 60); do
    if health_ok; then
      echo "Started backend at $BASE_URL."
      return 0
    fi
    sleep 1
  done

  echo "Backend did not become healthy. See $LOG_DIR/backend.log" >&2
  return 1
}

stop_pid() {
  local label="$1"
  local pid_file="$2"
  if [ ! -f "$pid_file" ]; then
    rm -f "$pid_file"
    echo "$label is not running from recorded state."
    return 0
  fi
  local pid
  pid="$(cat "$pid_file")"
  if [ -z "$pid" ]; then
    rm -f "$pid_file"
    echo "$label is not running from recorded state."
    return 0
  fi
  kill -- "-$pid" >/dev/null 2>&1 || true
  kill "$pid" >/dev/null 2>&1 || true
  for _ in $(seq 1 10); do
    if ! process_running "$pid" && ! process_group_running "$pid"; then
      break
    fi
    sleep 1
  done
  rm -f "$pid_file"
  echo "Stopped $label PID $pid."
}

case "$COMMAND" in
  check)
    print_config
    if health_ok; then
      echo "Backend health: PASS"
    else
      echo "Backend health: not running"
    fi
    if postgres_ok; then
      echo "Postgres readiness: PASS"
    else
      echo "Postgres readiness: not reachable"
    fi
    for cmd in go curl initdb postgres pg_isready createdb; do
      if has_command "$cmd"; then
        echo "Command $cmd: present"
      else
        echo "Command $cmd: missing"
      fi
    done
    ;;
  start)
    start_postgres_if_needed
    start_backend_if_needed
    echo "SCHEMATHESIS_BASE_URL=$BASE_URL"
    ;;
  status)
    print_config
    if pid_running "$POSTGRES_PID_FILE"; then
      echo "Recorded Postgres PID: $(cat "$POSTGRES_PID_FILE")"
    else
      echo "Recorded Postgres PID: none"
    fi
    if pid_running "$BACKEND_PID_FILE"; then
      echo "Recorded backend PID: $(cat "$BACKEND_PID_FILE")"
    else
      echo "Recorded backend PID: none"
    fi
    if health_ok; then
      echo "Backend health: PASS"
    else
      echo "Backend health: not healthy"
    fi
    if postgres_ok; then
      echo "Postgres readiness: PASS"
    else
      echo "Postgres readiness: not reachable"
    fi
    ;;
  stop)
    stop_pid "backend" "$BACKEND_PID_FILE"
    stop_pid "Postgres" "$POSTGRES_PID_FILE"
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
