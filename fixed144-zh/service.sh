#!/system/bin/sh
MODDIR=${0%/*}
exec 9> "$MODDIR/supervisor.lock"
flock -n 9 9>&9 || exit 0
echo $$ > "$MODDIR/service.pid"
OLD_WORKER=$(cat "$MODDIR/worker.pid" 2>/dev/null)
case "$OLD_WORKER" in
 ''|*[!0-9]*) ;;
 *) if tr '\000' ' ' < "/proc/$OLD_WORKER/cmdline" 2>/dev/null | grep -Fq "$MODDIR/worker.sh"; then kill "$OLD_WORKER" 2>/dev/null; sleep 1; fi ;;
esac
trap 'rm -f "$MODDIR/service.pid"' EXIT
trap 'kill "$CHILD" 2>/dev/null; wait "$CHILD" 2>/dev/null; exit 0' TERM INT
cleanup_listener() {
 LISTENER=$(cat "$MODDIR/events.pid" 2>/dev/null)
 case "$LISTENER" in
  ''|*[!0-9]*) return ;;
 esac
 if tr '\000' '\n' < "/proc/$LISTENER/environ" 2>/dev/null | grep -Fxq "CLASSPATH=$MODDIR/events.dex"; then
  kill "$LISTENER" 2>/dev/null
 fi
}
while [ "$(getprop sys.boot_completed)" != 1 ]; do sleep 3; done
while [ -d "$MODDIR" ] && [ ! -f "$MODDIR/disable" ] && [ ! -f "$MODDIR/remove" ]; do
 sh "$MODDIR/worker.sh" 9>&- </dev/null >/dev/null 2>&1 &
 CHILD=$!
 echo "$CHILD" > "$MODDIR/worker.pid"
 wait "$CHILD"
 cleanup_listener
 rm -f "$MODDIR/worker.pid"
 [ -f "$MODDIR/disable" ] && break
 [ -f "$MODDIR/remove" ] && break
 echo "$(date '+%Y-%m-%d %H:%M:%S') 工作进程已退出，正在重新启动" >> "$MODDIR/supervisor.log"
 sleep 2
done
