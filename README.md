# mipad-programmable-completion

## 模块简介
该Magisk模块用于补全小米/红米平板系列的大文件夹、恢复工作台默认行为、进游戏三倍速、高级材质、平滑圆角、极致模式、柔和阴影、双线程动画、智能IO调度及屏幕旋转建议提示按钮等。

## 模块都做了什么？

通过修改build.prop补全以下系统体验:

- 开启高级材质1.0
```bash
persist.sys.background_blur_supported=true
persist.sys.background_blur_status_default=true
persist.sys.background_blur_mode=0
```
- 开启高级材质2.0
```bash
persist.sys.background_blur_version=2
```

- 开启平滑圆角
```bash
persist.sys.support_view_smoothcorner=true
persist.sys.support_window_smoothcorner=true
```

- 开启进游戏三倍速
```bash
debug.game.video.support=true
debug.game.video.speed=true
```

- 禁用系统针对低内存设备的判断(仅红米平板)
```bash
ro.config.low_ram_.threshold_gb=
```

- 恢复工作台默认行为(仅红米平板，需额外搭配"星旅"添加工作台磁贴)
```bash
ro.config.miui_desktop_mode_enabled=true
```

"星旅"网盘下载地址：
https://caiyun.139.com/m/i?135CmnIeqzokl
(登录后下载不限速)

红米平板工作台模式磁贴添加指引：
在Magisk授予"星旅"Root权限(不需要在LSPosed激活模块)-控制中心找到"工作台模式"-添加磁贴-完成

- 开启柔和阴影效果(仅红米平板)
```bash
persist.sys.mi_shadow_supported=true
```

- 开启双线程动画(仅红米平板)
```bash
persist.sys.miui_animator_sched.sched_threads=2
```

- 开启智能IO调度(仅骁龙8+Gen1机型)
```bash
persist.sys.stability.smartfocusio=on
```


通过ADB命令补全以下系统体验:

- 开启屏幕旋转建议
```bash
settings put secure show_rotation_suggestions 1
```

- 开启极致模式
```bash
settings put secure speed_mode_enable 1
```

## 模块注意事项
如果不需要屏幕旋转建议可以手动关闭，通过MT管理器的终端模拟器输入如下命令:

- 关闭屏幕旋转建议
```bash
su
settings put secure show_rotation_suggestions 0
```

- 关闭极致模式
```bash
su
settings put secure speed_mode_enable 0
```

## 其他

《小米平板功能补全计划》允许个人在非盈利用途下的安装和使用本Magisk模块，禁止用于任何商业性或其他未经许可用途，作为项目的主要维护者将保留对项目的所有权利。

有关模块库的更多信息请查看Github (https://github.com/sothx/mipad-programmable-completion)
