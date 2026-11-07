#!/system/bin/sh
MODDIR=${0%/*}
[ -f "$MODDIR/disable" ] && exit 0
PKG=$(dumpsys activity activities | sed -n 's/.*topResumedActivity=.* u[0-9]* \([^/ ]*\)\/.*/\1/p' | head -n 1)
[ -n "$PKG" ] || exit 0
PID=$(pidof "$PKG" | cut -d ' ' -f 1)
case "$PID" in ''|*[!0-9]*) exit 0 ;; esac
[ "$1" != force ] && [ "$(cat "$MODDIR/pacing.pid" 2>/dev/null)" = "$PID" ] && exit 0
OLD_DUMP=$(getprop persist.sys.rms.allow_dump)
setprop persist.sys.rms.allow_dump true
dumpsys rms --display --set-frame-pacing "$PID" 144 144 1 1
dumpsys rms --display --set-fps 0 0 0 3
dumpsys rms --display --set-fps 0 144 0 3
setprop persist.sys.rms.allow_dump "$OLD_DUMP"
echo "$PID" > "$MODDIR/pacing.pid"
