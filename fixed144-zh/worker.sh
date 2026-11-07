#!/system/bin/sh
MODDIR=${0%/*}
exec 7> "$MODDIR/worker.lock"
flock -n 7 7>&7 || exit 0
FIFO="$MODDIR/power-events.fifo"
rm -f "$FIFO"
mkfifo "$FIFO" || exit 1
CLASSPATH="$MODDIR/events.dex" app_process /system/bin Fixed144Events > "$FIFO" 2> "$MODDIR/listener.log" &
EVENT_PID=$!
echo "$EVENT_PID" > "$MODDIR/events.pid"
trap 'kill "$EVENT_PID" 2>/dev/null; rm -f "$MODDIR/events.pid" "$FIFO"' EXIT
trap 'exit 0' TERM INT
exec 3< "$FIFO"
sh "$MODDIR/reconcile.sh" 7>&- >/dev/null 2>&1
while [ -d "$MODDIR" ] && [ ! -f "$MODDIR/disable" ] && [ ! -f "$MODDIR/remove" ]; do
 STATE=$(cat "$MODDIR/state" 2>/dev/null)
 case "$STATE" in awake) TIMEOUT=30 ;; *) TIMEOUT=120 ;; esac
 read -r -t "$TIMEOUT" EVENT <&3
 RESULT=$?
 [ "$RESULT" = 1 ] && exit 1
 if [ "$RESULT" = 0 ]; then
  case "$EVENT" in READY|AWAKE|SLEEP|SETTLE|TASK|SETTINGS|DOZE_SUSPEND) ;; *) continue ;; esac
 fi
 sh "$MODDIR/reconcile.sh" 7>&- >/dev/null 2>&1
 if [ "$EVENT" = DOZE_SUSPEND ]; then
  sh "$MODDIR/aod-status.sh" > "$MODDIR/aod-status.txt" 2>/dev/null
 fi
done
