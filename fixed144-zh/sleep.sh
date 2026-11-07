#!/system/bin/sh
MODDIR=${0%/*}
[ -f "$MODDIR/disable" ] && exit 0
OLD_DUMP=$(getprop persist.sys.rms.allow_dump)
setprop persist.sys.rms.allow_dump true
dumpsys rms --display --set-frame-pacing 0 0 0
dumpsys rms --display --set-fps 0 0 0 3
rm -f "$MODDIR/pacing.pid"
setprop persist.sys.rms.allow_dump "$OLD_DUMP"
su 2000 -c 'settings put system vivo_ltpo_setting 1' >/dev/null 2>&1
su 2000 -c 'settings put system min_refresh_rate 1.0' >/dev/null 2>&1
su 2000 -c 'settings put system peak_refresh_rate 1.0' >/dev/null 2>&1
