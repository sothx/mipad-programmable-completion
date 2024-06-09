SKIPUNZIP=0
. "$MODPATH"/util_functions.sh
api_level_arch_detect
magisk_path=/data/adb/modules/
module_id=$(grep_prop id $MODPATH/module.prop)

if [[ "$KSU" == "true" ]]; then
  ui_print "- KernelSU 用户空间当前的版本号: $KSU_VER_CODE"
  ui_print "- KernelSU 内核空间当前的版本号: $KSU_KERNEL_VER_CODE"
else
  ui_print "- Magisk 版本: $MAGISK_VER_CODE"
  if [ "$MAGISK_VER_CODE" -lt 26000 ]; then
    ui_print "*********************************************"
    ui_print "! 请安装 Magisk 26.0+"
    abort "*********************************************"
  fi
fi

# 环境配置
touch "$MODPATH"/system.prop
rm -rf /data/system/package_cache
device_code="$(getprop ro.product.device)"
device_soc_name="$(getprop ro.vendor.qti.soc_name)"
device_soc_model="$(getprop ro.vendor.qti.soc_model)"
# 红米平板判断
redmi_pad_list="xun dizi yunluo ruan"
device_type=$(check_device_type "$redmi_pad_list" "$device_code")

# 补全120hz判断
need_patch_120hz_fps_pad_list="pipa liuqin sheng"
is_need_patch_120hz_fps=$(check_device_is_need_patch "$device_code" "$need_patch_120hz_fps_pad_list")
# 节律护眼判断
need_patch_eyecare_mode_pad_list="pipa liuqin yudi zizhan babylon dagu yunluo xun"
is_need_patch_eyecare_mode=$(check_device_is_need_patch "$device_code" "$need_patch_eyecare_mode_pad_list")
# 工作台模式判断
need_patch_desktop_mode_pad_list="yunluo xun"
is_need_patch_desktop_mode=$(check_device_is_need_patch "$device_code" "$need_patch_desktop_mode_pad_list")


# 基础函数
add_props() {
  local line="$1"
  echo "$line" >>"$MODPATH"/system.prop
}

add_post_fs_data() {
  local line="$1"
  printf "\n$line\n" >>"$MODPATH"/post-fs-data.sh
}

key_check() {
  while true; do
    key_check=$(/system/bin/getevent -qlc 1)
    key_event=$(echo "$key_check" | awk '{ print $3 }' | grep 'KEY_')
    key_status=$(echo "$key_check" | awk '{ print $4 }')
    if [[ "$key_event" == *"KEY_"* && "$key_status" == "DOWN" ]]; then
      keycheck="$key_event"
      break
    fi
  done
  while true; do
    key_check=$(/system/bin/getevent -qlc 1)
    key_event=$(echo "$key_check" | awk '{ print $3 }' | grep 'KEY_')
    key_status=$(echo "$key_check" | awk '{ print $4 }')
    if [[ "$key_event" == *"KEY_"* && "$key_status" == "UP" ]]; then
      break
    fi
  done
}

if [[ -d "$magisk_path$module_id" ]];then
    ui_print "*********************************************"
    ui_print "模块不支持覆盖更新，请卸载模块并重启平板后再尝试安装！"
    abort "*********************************************"
fi

# 骁龙8+Gen1机型判断
if [[ "$device_soc_model" == "SM8475" && "$device_soc_name" == "cape" ]]; then
  # 调整I/O调度
  ui_print "*********************************************"
  ui_print "- 检测到你的设备处理器属于骁龙8+Gen1"
  ui_print "- 目前骁龙8+Gen1机型的小米平板存在系统IO调度异常的问题，容易导致系统卡顿或者无响应，模块可以为你开启合适的I/O调度规则"
  ui_print "- 是否调整系统I/O调度？"
  ui_print "  音量+ ：是"
  ui_print "  音量- ：否"
  ui_print "*********************************************"
  key_check
  if [[ "$keycheck" == "KEY_VOLUMEUP" ]]; then
    ui_print "*********************************************"
    ui_print "- 请选择需要使用的系统I/O调度？"
    ui_print "  音量+ ：启用智能I/O调度"
    ui_print "  音量- ：启用系统默认I/O调度"
    ui_print "*********************************************"
    key_check
    if [[ "$keycheck" == "KEY_VOLUMEUP" ]]; then
      ui_print "*********************************************"
      ui_print "- 已开启智能I/O调度(Android 14+ 生效)"
      add_props "# 开启智能I/O调度"
      add_props "persist.sys.stability.smartfocusio=on"
      ui_print "*********************************************"
    else
      ui_print "*********************************************"
      ui_print "- 已启用系统默认I/O调度(Android 14+ 生效)"
      add_props "# 开启系统默认I/O调度"
      add_props "persist.sys.stability.smartfocusio=off"
      ui_print "*********************************************"
    fi
  else
    ui_print "- 你选择不调整系统I/O调度"
  fi
fi

# 红米平板判断
if [[ "$device_type" == "redmi" ]]; then
  ui_print "- 你的设备属于红米平板系列"
  # 清空系统桌面低内存设备检测
  ui_print "- 已清空系统桌面的低内存设备检测"
  add_props "# 清空系统桌面的\"低内存\"设备检测"
  add_props "ro.config.low_ram_.threshold_gb="
  # 开启柔和阴影效果
  ui_print "*********************************************"
  ui_print "- 是否开启柔和阴影效果"
  ui_print "  音量+ ：是"
  ui_print "  音量- ：否"
  ui_print "*********************************************"
  key_check
  if [[ "$keycheck" == "KEY_VOLUMEUP" ]]; then
    ui_print "- 已开启柔和阴影效果"
    add_props "# 开启柔和阴影效果"
    add_props "persist.sys.mi_shadow_supported=true"
  else
    ui_print "- 你选择不开启柔和阴影效果"
  fi
  # 开启双线程动画
  ui_print "*********************************************"
  ui_print "- 是否开启双线程动画"
  ui_print "  音量+ ：是"
  ui_print "  音量- ：否"
  ui_print "*********************************************"
  key_check
  if [[ "$keycheck" == "KEY_VOLUMEUP" ]]; then
    ui_print "- 已开启双线程动画"
    add_props "# 开启双线程动画"
    add_props "persist.sys.miui_animator_sched.sched_threads=2"
  else
    ui_print "- 你选择不开启双线程动画"
  fi
fi

# 解锁工作台模式
if [[ "$is_need_patch_desktop_mode" == 1 && "$API" -ge 34  ]]; then
  ui_print "*********************************************"
  ui_print "- 是否解锁工作台模式?(仅Android 14 下生效)"
  ui_print "  音量+ ：是"
  ui_print "  音量- ：否"
  ui_print "*********************************************"
  key_check
  if [[ "$keycheck" == "KEY_VOLUMEUP" ]]; then
    add_props "# 解锁工作台模式"
    add_props "ro.config.miui_desktop_mode_enabled=true"
    ui_print "*********************************************"
    ui_print "- 已经自动为你补齐工作台模式的功能参数"
    ui_print "- [重要提醒]由于系统强判断物理运行内存低于8G的设备不显示工作台磁贴，如需要使用工作台模式，还需要需搭配\"星旅\"添加工作台磁贴，是否需要了解该应用的获取和使用方式?"
    ui_print "  音量+ ：是"
    ui_print "  音量- ：否"
    ui_print "*********************************************"
    key_check
    if [[ "$keycheck" == "KEY_VOLUMEUP" ]]; then
      ui_print "- 星旅网盘下载地址： https://caiyun.139.com/m/i?135CmnIeqzokl (登录后下载不限速)"
      ui_print "- 红米平板工作台模式磁贴添加指引："
      ui_print "- 在Magisk授予星旅Root权限(不需要在LSPosed激活模块)-控制中心找到工作台模式-添加磁贴-完成"
    else
      ui_print "- 你选择不了解如何添加工作台磁贴"
      ui_print "- 请注意，由于系统强判断物理运行内存低于8G的设备不显示工作台磁贴,如果没有添加工作台磁贴，工作台模式仍然无法正常开启"
    fi
  else
    ui_print "- 你选择不解锁工作台模式"
  fi
fi

has_been_patch_device_features=0
# 解锁熄屏挂机/熄屏听剧
ui_print "*********************************************"
ui_print "- 是否解锁熄屏挂机/熄屏听剧(移植包可能不兼容)"
ui_print "  音量+ ：是"
ui_print "  音量- ：否"
ui_print "*********************************************"
key_check
if [[ "$keycheck" == "KEY_VOLUMEUP" ]]; then
  ui_print "- 已解锁熄屏挂机/熄屏听剧"
  if [[ "$has_been_patch_device_features" == 0 ]]; then
    has_been_patch_device_features=1
    patch_device_features $MODPATH
    add_post_fs_data 'patch_device_features $MODDIR'
  fi
  patch_remove_screen_off_hold_on  $MODPATH
  add_post_fs_data 'patch_remove_screen_off_hold_on $MODDIR'
else
  ui_print "- 你选择不解锁熄屏挂机/熄屏听剧"
fi

# 解锁120hz
if [[ "$is_need_patch_120hz_fps" == 1 ]]; then
  ui_print "*********************************************"
  ui_print "- 是否解锁120hz高刷(移植包可能不兼容)"
  ui_print "  音量+ ：是"
  ui_print "  音量- ：否"
  ui_print "*********************************************"
  key_check
  if [[ "$keycheck" == "KEY_VOLUMEUP" ]]; then
    if [[ "$has_been_patch_device_features" == 0 ]]; then
      has_been_patch_device_features=1
      patch_device_features $MODPATH
      add_post_fs_data 'patch_device_features $MODDIR'
    fi
    patch_120hz_fps $MODPATH
    add_post_fs_data 'patch_120hz_fps $MODDIR'
    ui_print "- 已解锁120hz高刷"
  else
    ui_print "- 你选择不解锁120hz高刷"
  fi
fi

# 静置保持当前应用刷新率上限
ui_print "*********************************************"
ui_print "- 静置时是否保持当前应用刷新率上限？"
ui_print "- [重要提示]此功能会增加系统功耗，耗电量和发热都会比日常系统策略激进，请谨慎开启！！！"
if [[ "$is_need_patch_120hz_fps" == 1 ]]; then
  ui_print "- [重要提示]静置保持144hz刷新率会导致小米触控笔无法正常工作，使用触控笔请务必调整到120hz及以下！！！"
fi
ui_print "  音量+ ：是"
ui_print "  音量- ：否"
ui_print "*********************************************"
key_check
if [[ "$keycheck" == "KEY_VOLUMEUP" ]]; then
  ui_print "- 你选择静置时保持当前应用刷新率上限"
  if [[ "$is_need_patch_120hz_fps" == 1 ]]; then
    ui_print "- [你已知晓]静置保持144hz刷新率会导致小米触控笔无法正常工作，使用触控笔请务必调整到120hz及以下！！！"
  fi
  add_props "# 静置保持当前应用刷新率上限"
  add_props "ro.surface_flinger.use_content_detection_for_refresh_rate=true"
  add_props "ro.surface_flinger.set_idle_timer_ms=2147483647"
  add_props "ro.surface_flinger.set_touch_timer_ms=2147483647"
  add_props "ro.surface_flinger.set_display_power_timer_ms=2147483647"
else
  ui_print "- 你选择静置时使用系统默认配置，不需要保持当前应用刷新率上限"
fi

# 解锁节律护眼
if [[ "$is_need_patch_eyecare_mode" == 1 && "$API" -ge 34  ]]; then
  ui_print "*********************************************"
  ui_print "- 是否解锁节律护眼(Hyper OS 生效，移植包可能不兼容)"
  ui_print "  音量+ ：是"
  ui_print "  音量- ：否"
  ui_print "*********************************************"
  key_check
  if [[ "$keycheck" == "KEY_VOLUMEUP" ]]; then
    if [[ "$has_been_patch_device_features" == 0 ]]; then
      has_been_patch_device_features=1
      patch_device_features $MODPATH
      add_post_fs_data 'patch_device_features $MODDIR'
    fi
    patch_eyecare_mode $MODPATH
    add_post_fs_data 'patch_eyecare_mode $MODDIR'
    ui_print "- 已解锁节律护眼(Hyper OS 生效)"
  else
    ui_print "- 你选择不解锁节律护眼"
  fi
fi

# 开启屏幕旋转建议提示按钮
ui_print "*********************************************"
ui_print "- 是否开启屏幕旋转建议提示按钮"
if [[ "$API" -le 33  ]]; then
  ui_print "- [重要提醒]此功能无法与\"隐藏手势提示线\"共存"
fi
ui_print "  音量+ ：是"
ui_print "  音量- ：否"
ui_print "*********************************************"
key_check
if [[ "$keycheck" == "KEY_VOLUMEUP" ]]; then
  ui_print "- 已开启屏幕旋转建议提示按钮"
  if [[ "$API" -le 33  ]]; then
    ui_print "- 你已选择知晓此功能无法与\"隐藏手势提示线\"共存"
  fi
  settings put secure show_rotation_suggestions 1
else
  ui_print "- 你选择不开启屏幕旋转建议提示按钮"
  settings put secure show_rotation_suggestions 0
fi

# 开启极致模式
ui_print "*********************************************"
ui_print "- 是否开启极致模式"
ui_print "  音量+ ：是"
ui_print "  音量- ：否"
ui_print "*********************************************"
key_check
if [[ "$keycheck" == "KEY_VOLUMEUP" ]]; then
  ui_print "- 已开启极致模式"
  ui_print "- 极致模式的设置路径位于[开发者选项-极致模式]"
  settings put secure speed_mode_enable 1
else
  ui_print "- 你选择不开启极致模式"
  settings put secure speed_mode_enable 0
fi

# 开启进游戏三倍速
if [[ "$API" -ge 33  ]]; then
  ui_print "*********************************************"
  ui_print "- 是否开启进游戏三倍速"
  ui_print "  音量+ ：是"
  ui_print "  音量- ：否"
  ui_print "*********************************************"
  key_check
  if [[ "$keycheck" == "KEY_VOLUMEUP" ]]; then
    ui_print "- 已开启进游戏三倍速"
    add_props "# 开启进游戏三倍速"
    add_props "debug.game.video.support=true"
    add_props "debug.game.video.speed=true"
  else
    ui_print "- 你选择不开启进游戏三倍速"
  fi
fi

# 解锁游戏音质优化开关
ui_print "*********************************************"
ui_print "- 是否解锁\"游戏音质优化\"开关"
ui_print "  音量+ ：是"
ui_print "  音量- ：否"
ui_print "*********************************************"
key_check
if [[ "$keycheck" == "KEY_VOLUMEUP" ]]; then
  ui_print "- 已解锁\"游戏音质优化\"开关"
  ui_print "- \"游戏音质优化\"开关设置路径位于[游戏工具箱-性能增强]"
  add_props "# 解锁\"游戏音质优化\"开关"
  add_props "ro.vendor.audio.game.effect=true"
else
  ui_print "- 你选择不解锁\"游戏音质优化\"开关"
fi

is_show_rotation_suggestions="$(settings get secure show_rotation_suggestions)"
if [[ "$API" -le 33 && "$is_show_rotation_suggestions" == 0  ]]; then
  # 隐藏手势提示线
  ui_print "*********************************************"
  ui_print "- 是否隐藏手势提示线？(Android 13 可用)"
  ui_print "- [重要提醒]此功能无法与\"旋转建议提示按钮\"共存"
  ui_print "  音量+ ：是"
  ui_print "  音量- ：否"
  ui_print "*********************************************"
  key_check
  if [[ "$keycheck" == "KEY_VOLUMEUP" ]]; then
    ui_print "- 已隐藏手势提示线"
    if [[ "$API" -le 33  ]]; then
      ui_print "- 您已选择知晓此功能无法与\"旋转建议提示按钮\"共存"
    fi
    settings put global hide_gesture_line 1
  else
    ui_print "- 你选择不隐藏手势提示线"
    settings put global hide_gesture_line 0
  fi
fi

if [[ "$API" -ge 34  ]]; then
  # 优化手势提示线
  ui_print "*********************************************"
  ui_print "- 是否优化手势提示线？(仅在默认主题下生效，Android 14+ 可用)"
  ui_print "  音量+ ：是"
  ui_print "  音量- ：否"
  ui_print "*********************************************"
  key_check
  if [[ "$keycheck" == "KEY_VOLUMEUP" ]]; then
    ui_print "*********************************************"
    ui_print "- 需要沉浸还是隐藏优化手势提示线？(仅在默认主题下生效，Android 14+ 可用)"
    ui_print "  音量+ ：沉浸"
    ui_print "  音量- ：隐藏"
    ui_print "*********************************************"
    key_check
    if [[ "$keycheck" == "KEY_VOLUMEUP" ]]; then
      ui_print "- 已沉浸手势提示线，仅在默认主题下生效"
      immerse_gesture_cue_line $MODPATH
    else
      ui_print "- 已隐藏手势提示线，仅在默认主题下生效"
      hide_gesture_cue_line $MODPATH
    fi
  else
    ui_print "- 你选择不优化手势提示线"
  fi
fi

# 开启平滑圆角
ui_print "*********************************************"
ui_print "- 是否开启平滑圆角"
ui_print "  音量+ ：是"
ui_print "  音量- ：否"
ui_print "*********************************************"
key_check
if [[ "$keycheck" == "KEY_VOLUMEUP" ]]; then
  ui_print "- 已开启平滑圆角"
  add_props "# 开启平滑圆角"
  add_props "persist.sys.support_view_smoothcorner=true"
  add_props "persist.sys.support_window_smoothcorner=true"
else
  ui_print "- 你选择不开启平滑圆角"
fi

# 支持高级材质
if [[ "$API" -eq 34 ]]; then
  ui_print "*********************************************"
  ui_print "- 是否开启高级材质1.0"
  ui_print "  音量+ ：是"
  ui_print "  音量- ：否"
  ui_print "*********************************************"
  key_check
  if [[ "$keycheck" == "KEY_VOLUMEUP" ]]; then
    ui_print "- 已开启高级材质1.0"
    add_props "# 开启高级材质1.0"
    add_props "persist.sys.background_blur_supported=true"
    add_props "persist.sys.background_blur_status_default=true"
    add_props "persist.sys.background_blur_mode=0"
    ui_print "*********************************************"
    ui_print "- 是否开启高级材质2.0"
    ui_print "  音量+ ：是"
    ui_print "  音量- ：否"
    ui_print "*********************************************"
    key_check
    if [[ "$keycheck" == "KEY_VOLUMEUP" ]]; then
      ui_print "- 已开启高级材质2.0"
      add_props "# 开启高级材质2.0"
      add_props "persist.sys.background_blur_version=2"
    else
      ui_print "- 你选择不开启高级材质2.0"
    fi
  else
    ui_print "*********************************************"
    ui_print "- 你选择不开启高级材质1.0"
    ui_print "*********************************************"
  fi
fi
ui_print "*********************************************"
ui_print "- 好诶w，模块已经安装完成了，重启平板后生效"
ui_print "- 功能具体支持情况以系统为准"
ui_print "*********************************************"
