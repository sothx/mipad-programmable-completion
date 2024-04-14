# mipad-programmable-completion

## 模块简介
该Magisk模块用于补全小米/红米平板系列的部分系统体验，目前包括大文件夹、工作台模式、进游戏三倍速、高级材质、平滑圆角以及屏幕旋转建议提示按钮。

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

- 强开工作台模式(仅红米平板，需额外搭配"星旅"添加工作台磁贴)
```bash
ro.config.miui_desktop_mode_enabled=true
```

"星旅"网盘下载地址：
https://caiyun.139.com/m/i?135CmnIeqzokl
(登录后下载不限速)

红米平板工作台模式磁贴添加指引：
在Magisk授予"星旅"Root权限-控制中心找到"工作台模式"-添加磁贴-完成


通过ADB命令补全以下系统体验:

- 开启屏幕旋转建议
```bash
settings put secure show_rotation_suggestions 1
```

## 模块注意事项
如果不需要屏幕旋转建议可以手动关闭，通过MT管理器的终端模拟器输入如下命令:

- 关闭屏幕旋转建议
```bash
su
settings put secure show_rotation_suggestions 0
```

## 其他

有关模块库的更多信息请查看Github (https://github.com/sothx/mipad-programmable-completion)
