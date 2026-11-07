#!/system/bin/sh
MODDIR=${0%/*}
echo '【刷新率设置】'
echo "LTPO设置（0为关闭，1为开启）：$(su 2000 -c 'settings get system vivo_ltpo_setting' 2>/dev/null)"
echo "标准刷新率下限：$(su 2000 -c 'settings get system min_refresh_rate' 2>/dev/null) 赫兹"
echo "标准刷新率上限：$(su 2000 -c 'settings get system peak_refresh_rate' 2>/dev/null) 赫兹"
echo '【屏幕与息屏状态】'
STATE=$(dumpsys power | grep 'mWakefulness=')
case "$STATE" in
 *Awake*)
  echo '当前为亮屏状态。'
  cat /sys/lcm/lcm_fps | sed 's/software fps=/系统刷新率：/g; s/hardware fps=/同步采样频率：/g; s/te fps=/同步信号频率：/g; s/HZ/赫兹/g; s/Hz/赫兹/g'
  ;;
 *) echo '当前为非交互状态，已跳过主动频率测量。'; sh "$MODDIR/aod-status.sh" ;;
esac
echo '【后台服务】'
echo "守护进程编号：$(cat "$MODDIR/service.pid" 2>/dev/null)"
echo "工作进程编号：$(cat "$MODDIR/worker.pid" 2>/dev/null)"
echo "系统事件监听进程编号：$(cat "$MODDIR/events.pid" 2>/dev/null)"
echo "当前应用出帧控制进程编号：$(cat "$MODDIR/pacing.pid" 2>/dev/null)"
echo "累计检查次数：$(cat "$MODDIR/checks.count" 2>/dev/null)"
if [ "$1" = --raw ]; then
 echo '【系统原始诊断数据：保留接口原文，供排查使用】'
 OLD_DUMP=$(getprop persist.sys.rms.allow_dump)
 setprop persist.sys.rms.allow_dump true
 dumpsys rms --display
 setprop persist.sys.rms.allow_dump "$OLD_DUMP"
fi