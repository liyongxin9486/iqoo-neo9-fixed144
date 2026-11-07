#!/system/bin/sh
MODDIR=${0%/*}
[ -f "$MODDIR/disable" ] && { echo '模块已停用，未执行校正。'; exit 0; }
[ -f "$MODDIR/remove" ] && { echo '模块已标记卸载，未执行校正。'; exit 0; }
echo '正在检查后台服务并校正当前显示状态……'
nohup sh "$MODDIR/service.sh" >/dev/null 2>&1 </dev/null &
sh "$MODDIR/reconcile.sh" force
RESULT=$?
if [ "$RESULT" = 0 ]; then
 echo '已提交状态校正，后台将继续检查并自动恢复。'
 echo '亮屏目标：144赫兹；息屏目标：驱动报告的1赫兹低功耗模式。'
else
 echo '本次校正未完成，请检查超级用户权限或稍后重试。'
fi
exit "$RESULT"
