#!/system/bin/sh
# 仅采集状态证据。息屏时不读取会主动等待垂直同步的 lcm_fps 接口。
DISPLAY_STATE=$(dumpsys display | sed -n '/DisplayDeviceInfo.*type INTERNAL/s/.*state \([A-Z_]*\), committedState.*/\1/p' | head -n 1)
AOD_INFO=$(cat /sys/lcm/aod_disp_info 2>/dev/null)
SUSPEND_FPS=$(printf '%s\n' "$AOD_INFO" | sed -n 's/.*doze_suspend_fps=\([0-9]*\).*/\1/p')
case "$DISPLAY_STATE" in
 DOZE_SUSPEND) TEXT='息屏挂起，处于低功耗显示状态' ;;
 DOZE) TEXT='息屏显示，尚未挂起' ;;
 ON) TEXT='亮屏' ;;
 OFF) TEXT='屏幕已关闭' ;;
 *) TEXT='状态尚未确认或正在切换' ;;
esac
echo "显示状态：$TEXT"
echo "驱动报告的息屏刷新率：${SUSPEND_FPS:-未知} 赫兹"
printf '%s\n' "$AOD_INFO" | sed 's/aod_brightness=/息屏亮度：/g; s/support_full_screen=/全屏息屏支持标志：/g; s/support_1hz=/1赫兹支持标志：/g; s/support_video_aod=/视频息屏支持标志：/g; s/doze_suspend_fps=/驱动息屏刷新率：/g'
echo '外部物理测量：尚未进行，驱动状态不等同于外部扫描率实测。'
if [ "$DISPLAY_STATE" = DOZE_SUSPEND ] && [ "$SUSPEND_FPS" = 1 ]; then
 echo '验证结论：驱动报告已进入1赫兹息屏挂起模式。'
else
 echo '验证结论：当前尚未确认进入1赫兹息屏模式，或显示状态正在切换。'
fi