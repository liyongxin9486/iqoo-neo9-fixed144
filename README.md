# iQOO Neo9 亮屏 144Hz / 息屏 1Hz 模块

一个面向 **iQOO Neo9** 的 KernelSU / Magisk 模块：亮屏关闭 LTPO 自适应降刷并锁定 144Hz，息屏释放高刷请求、启用低功耗 1Hz 策略。全部通过系统设置项与厂商显示服务接口完成，**不挂载、不修改系统分区**。

- **版本**：1.6.1 中文版（`versionCode=8`）
- **形态**：Magisk / KernelSU 模块（刷入用 zip，不是 APK）
- **前置条件**：已获取 root 的 iQOO Neo9，且系统提供 vivo 私有显示服务 `dumpsys rms`
- **适用范围**：仅在该机型与对应系统版本上验证过；其他机型或系统升级后不保证生效

---

## 一、功能

### 亮屏：固定 144Hz
- 关闭 LTPO（`vivo_ltpo_setting=0`），把 `min_refresh_rate` 与 `peak_refresh_rate` 都设为 `144.0`
- 通过 `dumpsys rms --display --set-fps` 请求 144Hz 显示模式
- 为当前前台应用设置 144 帧出帧控制（frame pacing）

### 息屏：请求 1Hz 低功耗模式
- 释放亮屏的固定刷新率请求与应用出帧控制
- 恢复 LTPO（`vivo_ltpo_setting=1`），把刷新率上下限设为 `1.0`
- 监听 `DOZE_SUSPEND` 事件，驱动报告 `doze_suspend_fps=1`

### 自动恢复与自愈
- **事件驱动**：显示状态回调、任务栈回调、设置变更通知（无需安装额外 App）
- **分级复查**：亮屏后第 1 / 3 / 6 秒短时复查；稳定亮屏每 30 秒兜底，稳定息屏每 120 秒兜底
- **核对实际请求**：即使设置值仍显示 144，也会检查厂商服务中的真实刷新率请求和应用出帧控制
- **进程自愈**：监听进程或工作进程退出后，守护进程会尝试重建；管理器的「执行」按钮可手动校正
- **已知边界**：root 授权整体失效或整个进程树被终止时，模块无法自行重新取得权限

---

## 二、目录结构

```
├─ iQOO-Neo9-亮屏144赫兹与息屏1赫兹-中文版.zip   可直接刷入的完整模块包
├─ fixed144-zh/                                  精简源码目录（运行文件 + 事件监听源码）
│  ├─ module.prop                               模块名称、版本、简介
│  ├─ customize.sh / skip_mount                 安装配置与禁止挂载标记
│  ├─ action.sh                                 管理器「执行」按钮入口
│  ├─ service.sh / worker.sh / events.dex       守护进程、工作进程、系统事件监听
│  ├─ reconcile.sh                              状态判定与校正调度
│  ├─ apply.sh / sleep.sh / pacing.sh           亮屏策略 / 息屏策略 / 应用出帧控制
│  ├─ restore.sh / uninstall.sh                 原值回滚 / 卸载
│  ├─ status.sh / aod-status.sh                 中文状态检查 / 息屏 1Hz 验证
│  ├─ backup.json                               原始设置备份
│  └─ 源代码/                                   Fixed144Events.java + 编译时桩类
├─ 模块使用说明.txt                             完整中文使用说明
├─ 息屏1赫兹验证说明.md                         1Hz 证据与测量口径修正
└─ 原始设置备份.json                            单独留存的原始设置值
```

刷入包内还带有 `原始备份与记录/`（历史测试与系统原始诊断输出）以及 `源代码/` 两份 Java 源文件。`events.dex` 是模块运行必需的已编译文件，不是缓存，不能删除。

| 脚本 | 职责 |
| --- | --- |
| `service.sh` | 用文件锁保证单实例；启动并看护 `worker.sh`，退出后自动重建 |
| `worker.sh` | 以 `app_process` 启动 `events.dex` 监听器，通过 FIFO 接收事件并触发校正 |
| `reconcile.sh` | 依据 `dumpsys power` 判定亮屏 / 息屏，比对设置与实际请求，决定是否修复 |
| `apply.sh` / `sleep.sh` | 分别写入亮屏 144Hz、息屏 1Hz 的设置与厂商服务请求 |
| `pacing.sh` | 为栈顶应用设置 144 帧出帧控制，应用切换时更新 |
| `status.sh` | 中文输出刷新率设置、屏幕状态、后台进程号；`--raw` 追加原始诊断 |
| `aod-status.sh` | 只读采集 DOZE_SUSPEND 与 `doze_suspend_fps`，写入 `aod-status.txt` |
| `restore.sh` | 标记停用，释放请求，恢复原始设置值 |
| `uninstall.sh` | 卸载时调用 `restore.sh` |

---

## 三、安装

1. 在 KernelSU / Magisk 管理器中选择「安装 → 从本地」，选中 `iQOO-Neo9-亮屏144赫兹与息屏1赫兹-中文版.zip`。
2. 安装完成后按管理器提示重启。
3. `module.prop` 位于 zip 根目录，`customize.sh` 会设置脚本权限；`skip_mount` 为空标记，模块不会挂载任何系统文件。

自行重打包时，保证 `module.prop` 位于 zip **根目录**（不要把 `fixed144-zh` 这层目录压进去）即可。

---

## 四、使用与验证

- 在模块管理器中点击「执行」：检查后台服务并强制校正一次当前显示状态。
- 中文状态检查：

```sh
adb shell su -c 'sh /data/adb/modules/iqoo_fixed144/status.sh'
```

- 查看系统原始诊断数据：在上述命令末尾加 `--raw`。
- 息屏验证：进入息屏挂起状态后由 `aod-status.sh` 自动采集，结果记录在模块目录的 `aod-status.txt`。
- 若电脑同时连接多台设备，先 `adb devices` 查出序列号，再自行加 `adb -s <设备序列号>` 前缀。

> 视频播放帧率取决于片源，不能等同于屏幕刷新率；不同应用也可能受自身渲染或内容帧率限制。建议结合实际滑动手感核对，而非只看设置值。

---

## 五、关于「息屏 1Hz」的验证口径（请勿误读）

「驱动报告 1Hz」**不等于**用外部光学 / 电气设备测得面板每秒扫描一次。本模块没有伪造读数，也不能给原本 30 帧的视频增加真实画面。

只读证据：
- `/sys/lcm/aod_disp_info`：`doze_suspend_fps=1`
- Android 显示服务内置屏幕：`state DOZE_SUSPEND`、`committedState DOZE_SUSPEND`
- 内核日志：`panel_doze_suspend: [panel0] doze_suspend_fps(1)`
- `/sys/class/drm/sde-crtc-0/measured_fps`：`fps 0.0 / frame_count 0`，表示该采样窗没有主机画面提交，**不表示面板扫描频率为 0**

对早期约 30Hz 读数的修正：`lcm_fps_show` 会调用等待 vblank 的主动同步采样（先等 1 个 vblank，再等 200 个 vblank 计时），因此它不是独立的低功耗面板扫描率测量，其读数不能单独用来否定 DOZE_SUSPEND 状态。`status.sh` 在非交互状态下已跳过该接口。完整推导见 [`息屏1赫兹验证说明.md`](息屏1赫兹验证说明.md)，Android 官方状态定义见 [Display.STATE_DOZE_SUSPEND](https://developer.android.com/reference/android/view/Display#STATE_DOZE_SUSPEND)。

---

## 六、恢复与卸载

**仅关闭模块开关不会立即恢复已写入的设置**，必须执行回滚：

```sh
adb shell su -c 'sh /data/adb/modules/iqoo_fixed144/restore.sh'
```

回滚会释放本次添加的固定刷新率与应用出帧控制，并恢复原值：LTPO 设置 = `1`、删除新增的 `min_refresh_rate`、`peak_refresh_rate` = `144.0`。卸载模块时 `uninstall.sh` 也会调用 `restore.sh`。原始值保存在 `backup.json` 与 `原始设置备份.json` 中，字段与值未做改动。

---

## 七、改动边界

- 不挂载系统文件，不修改系统分区、系统镜像、系统文件或内核 sysfs 节点
- 不修改 Scene 的其他功能，不关闭温控策略
- 厂商诊断属性 `persist.sys.rms.allow_dump` 只在查询或调整请求时临时开启，用完恢复原值
- v1.6.1 这一轮只把名称、简介、说明与默认诊断输出改为中文，刷新率控制策略保持原样
- 事件监听进程实测分摊内存约 54MB；稳定息屏 15 秒样本中完整检查次数与处理器计数均未增加（这不是完整的待机功耗测试）

---

## 八、隐私与凭据说明

- 本仓库**不含**任何服务器地址、账号、密码、API 密钥或 SSH 运维信息，模块完全在设备本地运行、不联网。
- 原始说明文档里的 adb 设备序列号已替换为通用写法（多台设备时由使用者自行指定）。
- `原始备份与记录/` 是系统显示服务的原始诊断输出，内容仅为刷新率、场景编号与计数器等运行数据。
- `原始设置备份.json` / `backup.json` 记录的是设置项原值（LTPO、刷新率上下限），用于回滚，不含个人数据。

---

## 九、免责声明

修改系统显示设置需要 root 权限，可能影响续航、稳定性或设备保修。本项目仅在该机型与对应系统版本上验证，请自行评估风险、刷入前做好数据备份，因使用本模块造成的任何后果由使用者自行承担。
