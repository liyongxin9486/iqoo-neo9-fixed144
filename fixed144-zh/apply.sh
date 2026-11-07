#!/system/bin/sh
MODDIR=${0%/*}
[ -f "$MODDIR/disable" ] && exit 0
su 2000 -c 'settings put system vivo_ltpo_setting 0' >/dev/null 2>&1
su 2000 -c 'settings put system min_refresh_rate 144.0' >/dev/null 2>&1
su 2000 -c 'settings put system peak_refresh_rate 144.0' >/dev/null 2>&1
OLD_DUMP=$(getprop persist.sys.rms.allow_dump)
setprop persist.sys.rms.allow_dump true
dumpsys rms --display --set-fps 0 144 0 3
setprop persist.sys.rms.allow_dump "$OLD_DUMP"
