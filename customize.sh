SKIPUNZIP=0
. "$MODPATH"/util_functions.sh

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
has_been_patch_device_features=0
# 红米平板判断
redmi_pad_list="xun dizi yunluo"
device_type=xiaomi
for i in $redmi_pad_list; do
  if [[ "$device_code" == "$i" ]]; then
    device_type=redmi
    break
  fi
done
# 补全120hz判断
need_patch_120hz_fps_pad_list="pipa liuqin sheng"
is_need_patch_120hz_fps=0
for j in $need_patch_120hz_fps_pad_list; do
  if [[ "$device_code" == "$j" ]]; then
    is_need_patch_120hz_fps=1
    break
  fi
done



# 基础函数
add_props() {
  local line="$1"
  echo "$line" >>"$MODPATH"/system.prop
}

add_post-fs-data() {
  local line="$1"
  echo "$line" >>"$MODPATH"/post-fs-data.sh
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

# 骁龙8+Gen1机型判断
if [[ "$device_soc_model" == "SM8475" && "$device_soc_name" == "cape" ]]; then
  # 智能IO调度
  ui_print "*********************************************"
  ui_print "- 检测到你的设备处理器属于骁龙8+Gen1"
  ui_print "- 目前骁龙8+Gen1机型的小米平板存在系统IO调度异常的问题，容易导致系统卡顿或者无响应，模块可以为你开启合适的IO调度规则"
  ui_print "- 是否开启智能IO调度"
  ui_print "  音量+ ：是"
  ui_print "  音量- ：否"
  ui_print "*********************************************"
  key_check
  if [[ "$keycheck" == "KEY_VOLUMEUP" ]]; then
    # 已开启智能IO调度
    ui_print "- 已开启智能IO调度(Android 14+ 生效)"
    add_props "# 开启智能IO调度"
    add_props "persist.sys.stability.smartfocusio=on"
  else
    ui_print "- 你选择不开启智能IO调度"
  fi
fi

# 红米平板判断
if [[ "$device_type" == "redmi" ]]; then
  ui_print "- 你的设备属于红米平板系列"
  # 清空系统桌面低内存设备检测
  ui_print "- 已清空系统桌面的低内存设备检测"
  add_props "# 清空系统桌面的\"低内存\"设备检测"
  add_props "ro.config.low_ram_.threshold_gb="
  # 恢复工作台默认行为
  add_props "# 恢复工作台默认行为"
  add_props "ro.config.miui_desktop_mode_enabled=true"
  ui_print "*********************************************"
  ui_print "- 已经恢复工作台默认行为"
  ui_print "- （如需要使用工作台模式，仍需搭配\"星旅\"添加工作台磁贴，是否需要了解该应用的获取和使用方式?）"
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
    ui_print "- 请注意，如果没有添加工作台磁贴，工作台模式仍然无法正常开启"
  fi
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

# 解锁熄屏挂机/熄屏看剧
ui_print "*********************************************"
ui_print "- 是否解锁熄屏挂机/熄屏看剧"
ui_print "  音量+ ：是"
ui_print "  音量- ：否"
ui_print "*********************************************"
key_check
if [[ "$keycheck" == "KEY_VOLUMEUP" ]]; then
  ui_print "- 已解锁熄屏挂机/熄屏看剧"
  if [[ "$has_been_patch_device_features" == 0 ]]; then
    ui_print "- 正在修补设备特性"
    has_been_patch_device_features=1
    patch_device_features $MODPATH
    add_post-fs-data 'patch_device_features $MODDIR'
  fi
  patch_remove_screen_off_hold_on  $MODPATH
  add_post-fs-data 'patch_remove_screen_off_hold_on $MODPATH'
else
  ui_print "- 你选择不解锁熄屏挂机/熄屏看剧"
fi

# 解锁120hz
if [[ "$is_need_patch_120hz_fps" == 1 ]]; then
  ui_print "*********************************************"
  ui_print "- 是否解锁120hz高刷"
  ui_print "  音量+ ：是"
  ui_print "  音量- ：否"
  ui_print "*********************************************"
  key_check
  if [[ "$keycheck" == "KEY_VOLUMEUP" ]]; then
    if [[ "$has_been_patch_device_features" == 0 ]]; then
      ui_print "- 正在修补设备特性"
      has_been_patch_device_features=1
      patch_device_features $MODPATH
      add_post-fs-data 'patch_device_features $MODDIR'
    fi
    patch_120hz_fps  $MODPATH
    add_post-fs-data 'patch_120hz_fps $MODPATH'
    ui_print "- 已解锁120hz高刷"
  else
    ui_print "- 你选择不解锁120hz高刷"
  fi
fi

# 开启屏幕旋转建议
ui_print "*********************************************"
ui_print "- 是否开启屏幕旋转建议"
ui_print "  音量+ ：是"
ui_print "  音量- ：否"
ui_print "*********************************************"
key_check
if [[ "$keycheck" == "KEY_VOLUMEUP" ]]; then
  ui_print "- 已开启屏幕旋转建议"
  settings put secure show_rotation_suggestions 1
else
  ui_print "- 你选择不开启屏幕旋转建议"
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
ui_print "- 功能具体支持情况以系统为准"
ui_print "*********************************************"
