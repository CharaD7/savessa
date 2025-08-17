#!/usr/bin/env bash
# flutter_auto_reload.sh
# Run Flutter with a stable VM service port and automatic hot reload on file changes,
# keeping the session interactive for r (hot reload) and R (hot restart), even when piping output.
#
# Dependencies:
#   - inotifywait (sudo apt-get install -y inotify-tools)
#   - adb, flutter, script (usually preinstalled on Ubuntu)
#
# Environment variables (optional):
#   HOST_PORT        Host port for the VM service (default: 8123)
#   DEVICE_PORT      Device-side port for the VM service (default: same as HOST_PORT)
#   DEVICE_ID        Android device ID (default: emulator-5554)
#   PIDFILE          File where Flutter writes its PID (default: /tmp/flutter_run.pid)
#   PIPE_TO_CAT      If set to 1, pipe output to `command cat` while keeping TTY via `script` (default: 0)
#   RESTART_ON_CHANGE If set to 1, send SIGUSR2 (hot restart) instead of SIGUSR1 (hot reload) (default: 0)
#
# Positional args (optional):
#   Additional paths to watch (defaults: lib assets pubspec.yaml)

set -euo pipefail

HOST_PORT="${HOST_PORT:-8123}"
DEVICE_PORT="${DEVICE_PORT:-$HOST_PORT}"
DEVICE_ID="${DEVICE_ID:-emulator-5554}"
PIDFILE="${PIDFILE:-/tmp/flutter_run.pid}"
PIPE_TO_CAT="${PIPE_TO_CAT:-0}"
RESTART_ON_CHANGE="${RESTART_ON_CHANGE:-0}"

# Determine watch paths
if [[ $# -gt 0 ]]; then
  WATCH_PATHS=("$@")
else
  WATCH_PATHS=(lib assets pubspec.yaml)
fi

# Check for inotifywait
if ! command -v inotifywait >/dev/null 2>&1; then
  echo "ERROR: 'inotifywait' is required. Install with: sudo apt-get install -y inotify-tools" >&2
  exit 1
fi

cleanup() {
  local ec=$?
  if [[ -n "${WATCHER_PID:-}" ]]; then
    kill "${WATCHER_PID}" 2>/dev/null || true
    wait "${WATCHER_PID}" 2>/dev/null || true
  fi
  rm -f "$PIDFILE" 2>/dev/null || true
  # Keep the adb reverse in place across runs; remove if you prefer:
  # adb reverse --remove "tcp:${HOST_PORT}" 2>/dev/null || true
  exit "$ec"
}
trap cleanup EXIT INT TERM

# Start file watcher to trigger hot reload/hot restart via signals to flutter tool
(
  # -m: monitor recursively, -r: recursive
  inotifywait -mr -e modify,create,delete,move "${WATCH_PATHS[@]}" 2>/dev/null |
  while read -r _; do
    if [[ -f "$PIDFILE" ]]; then
      if [[ "$RESTART_ON_CHANGE" == "1" ]]; then
        # SIGUSR2 triggers hot restart
        kill -USR2 "$(cat "$PIDFILE")" 2>/dev/null || true
      else
        # SIGUSR1 triggers hot reload
        kill -USR1 "$(cat "$PIDFILE")" 2>/dev/null || true
      fi
    fi
  done
) &
WATCHER_PID=$!

# Ensure ADB reverse so device can connect back to host VM service
adb reverse "tcp:${HOST_PORT}" "tcp:${DEVICE_PORT}" >/dev/null || true

# Build the flutter command
FLUTTER_CMD=(
  flutter run
  -d "$DEVICE_ID"
  --device-vmservice-port "$DEVICE_PORT"
  --host-vmservice-port "$HOST_PORT"
  --no-dds
  --pid-file "$PIDFILE"
)

# Run under a PTY so r/R work even if output is piped
if [[ "$PIPE_TO_CAT" == "1" ]]; then
  # Preserve interactivity (script allocates a PTY) and allow piping for log consumers
  script -qfec "${FLUTTER_CMD[*]}" /dev/null | command cat
else
  script -qfec "${FLUTTER_CMD[*]}" /dev/null
fi

