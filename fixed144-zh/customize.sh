SKIPMOUNT=true
ui_print '正在安装：iQOO Neo9 亮屏144赫兹与息屏1赫兹'
ui_print '已包含中文说明、设置备份与恢复脚本。'
set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/action.sh" 0 0 0755
