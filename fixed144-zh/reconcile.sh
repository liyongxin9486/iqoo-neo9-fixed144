#!/system/bin/sh
MODDIR=${0%/*}
exec 8> "$MODDIR/update.lock"
flock -n 8 8>&8 || exit 0
[ -f "$MODDIR/disable" ] && exit 0
[ -f "$MODDIR/remove" ] && exit 0
read CHECKS < "$MODDIR/checks.count" 2>/dev/null || CHECKS=0
case "$CHECKS" in ''|*[!0-9]*) CHECKS=0 ;; esac
echo "$((CHECKS + 1))" > "$MODDIR/checks.count"
STATE=$(dumpsys power | grep 'mWakefulness=')
LAST=$(cat "$MODDIR/state" 2>/dev/null)
case "$STATE" in
 *Awake*) TARGET=awake; EXPECT_LTPO=0; RATE=144.0 ;;
 *Dozing*|*Asleep*) TARGET=sleep; EXPECT_LTPO=1; RATE=1.0 ;;
 *) exit 0 ;;
esac
LTPO=$(su 2000 -c 'settings get system vivo_ltpo_setting' 2>/dev/null)
MIN=$(su 2000 -c 'settings get system min_refresh_rate' 2>/dev/null)
MAX=$(su 2000 -c 'settings get system peak_refresh_rate' 2>/dev/null)
[ -n "$LTPO" ] || exit 1
REPAIR=0
if [ "$TARGET" != "$LAST" ] || [ "$LTPO" != "$EXPECT_LTPO" ] || [ "$MIN" != "$RATE" ] || [ "$MAX" != "$RATE" ]; then REPAIR=1; fi
if [ "$TARGET" = awake ]; then
 OLD_DUMP=$(getprop persist.sys.rms.allow_dump)
 setprop persist.sys.rms.allow_dump true
 REPORT=$(dumpsys rms --display)
 setprop persist.sys.rms.allow_dump "$OLD_DUMP"
 ACTIVE=$(printf '%s\n' "$REPORT" | sed -n '/  ActiveRequest:/,/  ValidRequests:/p')
 printf '%s\n' "$ACTIVE" | grep -q 'reason=setFpsByAdb.*fps=144,' || REPAIR=1
 printf '%s\n' "$REPORT" | grep -q 'ActiveConfig:.*fps=144,' || REPAIR=1
 PKG=$(dumpsys activity activities | sed -n 's/.*topResumedActivity=.* u[0-9]* \([^/ ]*\)\/.*/\1/p' | head -n 1)
 PID=$(pidof "$PKG" | cut -d ' ' -f 1)
 if [ -n "$PID" ]; then
  printf '%s\n' "$REPORT" | grep -F "{pid=$PID,appFps=[144," | grep -q 'limitFps=\[144,.*flags=0x1}' || REPAIR=1
 fi
 [ "$1" = force ] && REPAIR=1
 if [ "$REPAIR" = 1 ]; then
  echo "$(date '+%Y-%m-%d %H:%M:%S') 正在校正亮屏刷新率和应用出帧控制" >> "$MODDIR/repair.log"
  sh "$MODDIR/apply.sh" >/dev/null 2>&1
  sh "$MODDIR/pacing.sh" force >/dev/null 2>&1
 else
  sh "$MODDIR/pacing.sh" >/dev/null 2>&1
 fi
else
 if [ "$REPAIR" = 1 ] || [ "$1" = force ]; then
  echo "$(date '+%Y-%m-%d %H:%M:%S') 正在应用息屏低刷新率策略" >> "$MODDIR/repair.log"
  sh "$MODDIR/sleep.sh" >/dev/null 2>&1
 fi
fi
echo "$TARGET" > "$MODDIR/state"
