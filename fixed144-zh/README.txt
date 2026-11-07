iQOO Neo9 刷新率模块：精简源码目录
版本：1.6.1 中文版

本目录保留当前模块的运行文件、原始设置备份和事件监听源码，可直接用于继续维护或打包。

运行与安装文件
module.prop：模块名称、版本和简介。
customize.sh、skip_mount：安装配置与禁止挂载标记。
action.sh：手动执行入口。
service.sh、worker.sh、events.dex：守护进程、工作进程和系统事件监听。
reconcile.sh、apply.sh、sleep.sh、pacing.sh：状态校正、亮屏与息屏策略、应用出帧控制。
restore.sh、uninstall.sh：恢复原值与卸载。
status.sh、aod-status.sh：中文状态诊断及息屏驱动状态验证。
backup.json：原始设置备份，保留其原始字段和值。

事件监听源码
源代码/Fixed144Events.java：当前事件监听器源码。
源代码/TaskStackListener.java：编译时需要的系统接口桩类，不是无关代码；运行用的 events.dex 中不包含该桩类。
events.dex 是模块运行必需的已编译文件，不能作为缓存删除。

策略与限制
亮屏请求144赫兹并关闭LTPO；息屏释放高刷请求，并启用1赫兹策略。
已确认驱动报告1赫兹息屏挂起模式，尚未进行外部物理扫描率测量。
模块依赖现有超级用户权限，不修改系统分区、镜像或系统文件。
完整使用说明、验证说明、最终安装包及单独的原始设置备份，均位于本工作区的 outputs 目录。

本次精简仅移除历史测试记录、附加备份副本和重复文档；运行脚本与事件监听源码保持原样。