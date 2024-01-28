# mipad-programmable-completion

## 模块简介
该Magisk模块用于补全小米平板、红米平板系列的部分系统体验。

小米平板补全功能列表：
- 高级材质1.0/高级材质2.0
- 平滑圆角
- 屏幕旋转建议提示按钮

红米平板补全功能列表:
- 大文件夹(四宫格)
- 平滑圆角
- 屏幕旋转建议提示按钮

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

- 禁用系统针对低内存设备的判断(仅红米平板)
```bash
ro.config.low_ram_.threshold_gb=
```

通过ADB命令补全以下系统体验:

- 开启屏幕旋转建议
```bash
settings put secure show_rotation_suggestions 1
```

## 模块注意事项
屏幕旋转建议仅在在模块安装过程中启用该原生系统功能，该功能将会一直有效。如果不需要屏幕旋转建议可以手动关闭，通过MT管理器的终端模拟器输入如下命令:

- 关闭屏幕旋转建议
```bash
su
settings put secure show_rotation_suggestions 0
```

## 其他

有关模块和存储库的更多信息请查看 [Magisk 官方文档](https://topjohnwu.github.io/Magisk/guides.html)
