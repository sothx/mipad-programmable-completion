SKIPUNZIP=0
. "$MODPATH"/util_functions.sh
api_level_arch_detect
magisk_path=/data/adb/modules/
module_id=$(grep_prop id $MODPATH/module.prop)

if [[ "$KSU" == "true" ]]; then
  ui_print "- KernelSU 用户空间版本号: $KSU_VER_CODE"
  ui_print "- KernelSU 内核空间版本号: $KSU_KERNEL_VER_CODE"
  if [ "$KSU_KERNEL_VER_CODE" -lt 11089 ]; then
    ui_print "*********************************************"
    ui_print "! 请安装 KernelSU 管理器 v0.6.2 或更高版本"
    abort "*********************************************"
  fi
elif [[ "$APATCH" == "true" ]]; then
  ui_print "- APatch 版本名: $APATCH_VER"
  ui_print "- APatch 版本号: $APATCH_VER_CODE"
else
  ui_print "- Magisk 版本名: $MAGISK_VER"
  ui_print "- Magisk 版本号: $MAGISK_VER_CODE"
  if [ "$MAGISK_VER_CODE" -lt 26000 ]; then
    ui_print "*********************************************"
    ui_print "! 请安装 Magisk 26.0+"
    abort "*********************************************"
  fi
fi

# 赋予文件夹权限
set_perm_recursive "$MODPATH" 0 0 0755 0777 u:object_r:system_file:s0

# 重置缓存
rm -rf /data/system/package_cache/*
rm -rf /data/resource-cache
# 环境配置
touch "$MODPATH"/system.prop
device_code="$(getprop ro.product.device)"
device_soc_name="$(getprop ro.vendor.qti.soc_name)"
device_soc_model="$(getprop ro.vendor.qti.soc_model)"
# 移植包补全144hz
project_treble_support_144hz="$(getprop ro.config.sothx_project_treble_support_144hz)"
ui_print "project_treble_support_144hz=$project_treble_support_144hz"
# 红米平板判断
redmi_pad_list="xun dizi yunluo ruan"
device_type=$(check_device_type "$redmi_pad_list" "$device_code")

has_been_patch_device_features=0
has_been_patch_perfinit_bdsize_zram=0

# 补全多档高刷判断
need_patch_full_fps_pad_list="pipa liuqin sheng"
is_need_patch_full_fps=$(check_device_is_need_patch "$device_code" "$need_patch_full_fps_pad_list")
# 补全120hz判断
need_patch_120hz_fps_pad_list="uke muyu"
is_need_patch_120hz_fps=$(check_device_is_need_patch "$device_code" "$need_patch_120hz_fps_pad_list")
# 节律护眼判断
need_patch_eyecare_mode_pad_list="pipa liuqin yudi zizhan babylon dagu yunluo xun"
is_need_patch_eyecare_mode=$(check_device_is_need_patch "$device_code" "$need_patch_eyecare_mode_pad_list")
# 工作台模式判断
need_patch_desktop_mode_pad_list="yunluo xun"
is_need_patch_desktop_mode=$(check_device_is_need_patch "$device_code" "$need_patch_desktop_mode_pad_list")
# 不支持高级材质机型判断
un_need_patch_background_blur_pad_list="dizi ruan"
is_un_need_patch_background_blur=$(check_device_is_need_patch "$device_code" "$un_need_patch_background_blur_pad_list")
# 优化线程判断
need_patch_threads_pad_list="nabu enuma elish dagu pipa"
is_need_patch_threads_pad_list=$(check_device_is_need_patch "$device_code" "$need_patch_threads_pad_list")
# ZRAM:RAM 1:1内存优化
need_patch_zram_pad_list="liuqin yudi pipa nabu elish dagu enuma"
is_need_patch_zram=$(check_device_is_need_patch "$device_code" "$need_patch_zram_pad_list")
# 需要启用DM设备映射器的机型
need_patch_dm_opt_pad_list="liuqin yudi pipa nabu elish dagu enuma"
is_need_patch_dm_opt=$(check_device_is_need_patch "$device_code" "$need_patch_dm_opt_pad_list")
# # 需要补全通信共享的机型
# need_patch_celluar_shared_pad_list="dagu"
# is_need_patch_celluar_shared=$(check_device_is_need_patch "$device_code" "$need_patch_celluar_shared_pad_list")
# 需要开启Ultra HDR的设备
need_patch_hdr_supportd_pad_list="liuqin yudi pipa sheng"
is_need_patch_hdr_supportd_pad_list=$(check_device_is_need_patch "$device_code" "$need_patch_hdr_supportd_pad_list")
# 小米澎湃AI功能补全
need_patch_eyecare_mode_pad_list="pipa liuqin yudi zizhan babylon dagu yunluo xun"
is_need_patch_eyecare_mode=$(check_device_is_need_patch "$device_code" "$need_patch_eyecare_mode_pad_list")

# 基础函数
add_props() {
  local line="$1"
  echo "$line" >>"$MODPATH"/system.prop
}

add_post_fs_data() {
  local line="$1"
  printf "\n$line\n" >>"$MODPATH"/post-fs-data.sh
}

add_service() {
  local line="$1"
  printf "\n$line\n" >>"$MODPATH"/service.sh
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

if [[ -d "$magisk_path$module_id" ]]; then
  ui_print "*********************************************"
  ui_print "模块不支持覆盖更新，请卸载模块并重启平板后再尝试安装！"
  ui_print "强行覆盖更新会导致模块数据异常，可能导致系统出现不可预料的异常问题！"
  ui_print "(APatch可能首次安装也会出现覆盖更新的提醒，这种情况下可以选择忽略)"
  ui_print "  音量+ ：哼，我偏要装(强制安装)"
  ui_print "  音量- ：否"
  ui_print "*********************************************"
  key_check
  if [[ "$keycheck" == "KEY_VOLUMEUP" ]]; then
    ui_print "*********************************************"
    ui_print "- 你选择了强制安装！！！"
    ui_print "*********************************************"
  else
    ui_print "*********************************************"
    ui_print "- 请卸载模块并重启平板后再尝试安装QwQ！！！"
    abort "*********************************************"
  fi
fi

# 骁龙8+Gen1机型判断
has_been_enabled_smartfocusio=0
if [[ $(grep_prop persist.sys.stability.smartfocusio $magisk_path"MIUI_MagicWindow+/system.prop") ]]; then
  has_been_enabled_smartfocusio=1
fi
if [[ "$device_soc_model" == "SM8475" && "$device_soc_name" == "cape" && "$API" -ge 34 && $has_been_enabled_smartfocusio == 0 ]]; then
  # 调整I/O调度
  ui_print "*********************************************"
  ui_print "- 检测到你的设备处理器属于骁龙8+Gen1"
  ui_print "- 目前骁龙8+Gen1机型的小米平板存在系统IO调度异常的问题，容易导致系统卡顿或者无响应，模块可以为你开启合适的I/O调度规则"
  ui_print "- 是否调整系统I/O调度？"
  ui_print "- [重要提醒]在Hyper OS 2 小米已经修复此问题，Hyper OS 2下非部分特殊移植包一般不推荐开启。"
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
  add_props "ro.config.low_ram.threshold_gb="
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
fi

# 优化动画线程调度
if [[ "$device_type" == "redmi" || "$is_need_patch_threads_pad_list" == 1 ]]; then
  ui_print "*********************************************"
  ui_print "- 是否优化动画线程调度"
  ui_print "- [重要提醒]可以一定程度改善系统动画渲染时线程调度的流畅度"
  ui_print "  音量+ ：是"
  ui_print "  音量- ：否"
  ui_print "*********************************************"
  key_check
  if [[ "$keycheck" == "KEY_VOLUMEUP" ]]; then
    ui_print "- 已优化动画线程调度"
    add_props "# 优化动画线程调度"
    add_props "persist.sys.miui_animator_sched.sched_threads=2"
    add_props "persist.vendor.display.miui.composer_boost=4-7"
  else
    ui_print "- 你选择不优化动画线程调度"
  fi
fi

# 解锁工作台模式
if [[ "$is_need_patch_desktop_mode" == 1 && "$API" -ge 34 ]]; then
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

# ZRAM:RAM=1:1 内存优化
if [[ "$is_need_patch_zram" == 1 && "$API" -ge 35 ]]; then
  ui_print "*********************************************"
  ui_print "- 是否启用 ZRAM:RAM=1:1 内存优化?（第三方内核可能不生效）"
  ui_print "- [重要提醒]内存优化最大兼容 ZRAM 为 16G"
  ui_print "- [重要提醒]可能会与其他内存相关模块冲突导致不生效"
  ui_print "  音量+ ：是"
  ui_print "  音量- ：否"
  ui_print "*********************************************"
  key_check
  if [[ "$keycheck" == "KEY_VOLUMEUP" ]]; then
    ui_print "- 已启用 ZRAM:RAM=1:1 内存优化"
    ui_print "- [重要提醒]内存优化最大兼容 ZRAM 为 16G"
    ui_print "- [重要提醒]可能会与其他内存相关模块冲突导致不生效"
    if [[ "$has_been_patch_perfinit_bdsize_zram" == 0 ]]; then
      has_been_patch_perfinit_bdsize_zram=1
      patch_perfinit_bdsize_zram $MODPATH
      add_service 'patch_perfinit_bdsize_zram $MODDIR'
    fi
    patch_zram_config $MODPATH
    add_service 'patch_zram_config $MODDIR'
  else
    ui_print "- 你选择不启用 ZRAM:RAM=1:1 内存优化"
  fi
fi

if [[ "$is_need_patch_dm_opt" == 1 && "$API" -ge 35 ]]; then
  ui_print "*********************************************"
  ui_print "- 是否启用dm设备映射器？（第三方内核可能不生效）"
  ui_print "- [重要提醒]一般推荐启用，通常用于将设备上的冷数据压缩并迁移到硬盘上"
  ui_print "- [重要提醒]需要开启内存扩展才会生效"
  ui_print "  音量+ ：是"
  ui_print "  音量- ：否"
  ui_print "*********************************************"
  key_check
  if [[ "$keycheck" == "KEY_VOLUMEUP" ]]; then
    ui_print "- 已开启dm设备映射器"
    ui_print "- [重要提醒]需要开启内存扩展才会生效"
    add_props "# 开启dm设备映射器"
    add_props "persist.miui.extm.dm_opt.enable=true"
  else
    ui_print "- 你选择不开启dm设备映射器"
  fi
fi

# if [[ "$is_need_patch_celluar_shared" == 1 && "$API" -ge 34 ]]; then
#   ui_print "*********************************************"
#   ui_print "- 是否启用通信共享？(仅在默认主题下生效)"
#   ui_print "- [重要提醒]需要Hyper OS 2才会生效"
#   ui_print "  音量+ ：是"
#   ui_print "  音量- ：否"
#   ui_print "*********************************************"
#   key_check
#   if [[ "$keycheck" == "KEY_VOLUMEUP" ]]; then
#     ui_print "- 已启用通信共享，仅在默认主题下生效"
#     ui_print "- [重要提醒]需要Hyper OS 2才会生效"
#     patch_celluar_shared $MODPATH
#   else
#     ui_print "- 你选择不启用通信共享"
#   fi
# fi

# 移除OTA验证
ui_print "*********************************************"
ui_print "- 是否移除OTA验证？"
ui_print "- [你已知晓]可绕过 ROM 权限校验"
ui_print "- [你已知晓]不支持任何非官方 ROM 使用"
ui_print "- [你已知晓]此功能有一定危险性，请在了解 Fastboot 操作后再评估是否开启"
ui_print "  音量+ ：是"
ui_print "  音量- ：否"
ui_print "*********************************************"
key_check
if [[ "$keycheck" == "KEY_VOLUMEUP" ]]; then
  ui_print "- 已移除OTA验证"
  if [[ "$has_been_patch_device_features" == 0 ]]; then
    has_been_patch_device_features=1
    patch_device_features $MODPATH
    add_post_fs_data 'patch_device_features $MODDIR'
  fi
  patch_disabled_ota_validate $MODPATH
  add_post_fs_data 'patch_disabled_ota_validate $MODDIR'
else
  ui_print "- 你选择不移除OTA验证"
fi

# PC级WPS字体目录自动创建
is_need_create_fonts_dir=0
XIAOMI_MSLGRDP_PATH=/data/rootfs/home/xiaomi
WPS_OFFICE_PC_FONTS_DIR="$XIAOMI_MSLGRDP_PATH/.fonts"
if [[ -d "$XIAOMI_MSLGRDP_PATH" && ! -d "$WPS_OFFICE_PC_FONTS_DIR" ]]; then
  is_need_create_fonts_dir=1
fi
if [[ -d "$WPS_OFFICE_PC_FONTS_DIR" ]]; then
  is_need_create_fonts_dir=1
fi
if [[ "$API" -ge 34 && "$is_need_create_fonts_dir" -eq 1 ]]; then
  ui_print "*********************************************"
  ui_print "- 检测到您的系统已存在PC框架的运行环境"
  ui_print "- 是否需要为WPS Office PC 创建字体扩展目录？"
  ui_print "- [重要提醒]需要将字体文件放入$WPS_OFFICE_PC_FONTS_DIR文件夹内"
  ui_print "  音量+ ：是"
  ui_print "  音量- ：否"
  ui_print "*********************************************"
  key_check
  if [[ "$keycheck" == "KEY_VOLUMEUP" ]]; then
    ui_print "- 已生成WPS Office PC字体扩展目录"
    ui_print "- [重要提醒]需要将字体文件放入$WPS_OFFICE_PC_FONTS_DIR文件夹内"
    create_fonts_dir $MODPATH
    add_post_fs_data 'create_fonts_dir $MODDIR'
  else
    ui_print "*********************************************"
    ui_print "- 你选择不创建WPS Office PC字体扩展目录"
    ui_print "*********************************************"
  fi
fi

if [[ "$API" -ge 33 && -f "/system/product/etc/permissions/cn.google.services.xml" ]]; then
  # 解除GMS区域限制
  ui_print "*********************************************"
  ui_print "- 是否解除谷歌服务框架的区域限制？"
  ui_print "- [重要提醒]解除谷歌服务框架区域限制后可以使用 Google Play 快速分享等功能~"
  ui_print "  音量+ ：是"
  ui_print "  音量- ：否"
  ui_print "*********************************************"
  key_check
  if [[ "$keycheck" == "KEY_VOLUMEUP" ]]; then
    ui_print "- 已解除谷歌服务框架的区域限制"
    patch_cn_google_services $MODPATH
    add_post_fs_data 'patch_cn_google_services $MODDIR'
  else
    ui_print "- 你选择不解除谷歌服务框架的区域限制"
  fi
fi

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
  patch_remove_screen_off_hold_on $MODPATH
  add_post_fs_data 'patch_remove_screen_off_hold_on $MODDIR'
else
  ui_print "- 你选择不解锁熄屏挂机/熄屏听剧"
fi

# 解锁视频工具箱智能刷新率
ui_print "*********************************************"
ui_print "- 是否解锁视频工具箱智能刷新率(移植包可能不兼容)"
ui_print "  音量+ ：是"
ui_print "  音量- ：否"
ui_print "*********************************************"
key_check
if [[ "$keycheck" == "KEY_VOLUMEUP" ]]; then
  ui_print "- 已解锁视频工具箱智能刷新率"
  if [[ "$has_been_patch_device_features" == 0 ]]; then
    has_been_patch_device_features=1
    patch_device_features $MODPATH
    add_post_fs_data 'patch_device_features $MODDIR'
  fi
  patch_support_video_dfps $MODPATH
  add_post_fs_data 'patch_support_video_dfps $MODDIR'
else
  ui_print "- 你选择不解锁视频工具箱智能刷新率"
fi

# 解锁多档高刷
if [[ "$is_need_patch_full_fps" == 1 && "$project_treble_support_144hz" != 'true' ]]; then
  ui_print "*********************************************"
  ui_print "- 是否解锁多档高刷(移植包可能不兼容)"
  ui_print "- [重要提示]\"最高到144hz\"的机型实际最高刷新率为120hz"
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
    patch_full_fps $MODPATH
    add_post_fs_data 'patch_full_fps $MODDIR'
    ui_print "- 已解锁多档高刷"
  else
    ui_print "- 你选择不解锁多档高刷"
  fi
fi

# 解锁120hz
if [[ "$is_need_patch_120hz_fps" == 1 && "$project_treble_support_144hz" != 'true' ]]; then
  ui_print "*********************************************"
  ui_print "- 是否解锁120hz高刷(移植包可能不兼容)"
  ui_print "- [重要提示]在Android 15+会将高刷选项的默认行为还原为Android14时的显示效果"
  ui_print "- [重要提示]解锁后不会出现\"最高到144hz\"的高刷选项，是正常的模块行为"
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
if [[ "$API" -le 34 ]]; then
  ui_print "*********************************************"
  ui_print "- 静置时是否保持当前应用刷新率上限？"
  ui_print "- [重要提示]此功能会增加系统功耗，耗电量和发热都会比日常系统策略激进，请谨慎开启！！！"
  ui_print "- [重要提示]静置保持144hz刷新率会导致小米触控笔无法正常工作，使用触控笔请务必调整到120hz！！！"
  ui_print "- [重要提示]此功能非必要情况下不推荐开启~"
  ui_print "  音量+ ：是，且了解该功能会影响小米触控笔"
  ui_print "  音量- ：否"
  ui_print "*********************************************"
  key_check
  if [[ "$keycheck" == "KEY_VOLUMEUP" ]]; then
    ui_print "- 你选择静置时保持当前应用刷新率上限"
    ui_print "- [你已知晓]静置保持144hz刷新率会导致小米触控笔无法正常工作，使用触控笔请务必调整到120hz！！！"
    add_props "# 静置保持当前应用刷新率上限"
    add_props "ro.surface_flinger.use_content_detection_for_refresh_rate=true"
    add_props "ro.surface_flinger.set_idle_timer_ms=2147483647"
    add_props "ro.surface_flinger.set_touch_timer_ms=2147483647"
    add_props "ro.surface_flinger.set_display_power_timer_ms=2147483647"
  else
    ui_print "- 你选择静置时使用系统默认配置，不需要保持当前应用刷新率上限"
  fi
fi

# 解锁节律护眼
if [[ "$is_need_patch_eyecare_mode" == 1 && "$API" -ge 34 ]]; then
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
ui_print "  音量+ ：是"
ui_print "  音量- ：否"
ui_print "*********************************************"
key_check
if [[ "$keycheck" == "KEY_VOLUMEUP" ]]; then
  ui_print "- 已开启屏幕旋转建议提示按钮"
  show_rotation_suggestions $MODPATH
  add_post_fs_data 'show_rotation_suggestions $MODDIR'
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
if [[ "$API" -ge 33 ]]; then
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

# 解锁游戏工具箱狂暴引擎UI界面
if [[ "$API" -ge 33 ]]; then
  ui_print "*********************************************"
  ui_print "- 是否解锁游戏工具箱\"狂暴引擎\"UI界面？(移植包可能不兼容)"
  ui_print "- [重要提示]该功能仅为开启\"狂暴引擎\"的UI界面，并非真的添加\"狂暴引擎\"功能，也无法开启feas！！！"
  ui_print "  音量+ ：是"
  ui_print "  音量- ：否"
  ui_print "*********************************************"
  key_check
  if [[ "$keycheck" == "KEY_VOLUMEUP" ]]; then
    ui_print "- 已解锁游戏工具箱\"狂暴引擎\"UI界面"
    ui_print "- [你已知晓]该功能仅为开启\"狂暴引擎\"的UI界面，并非真的添加\"狂暴引擎\"功能，也无法开启feas！！！"
    if [[ "$has_been_patch_device_features" == 0 ]]; then
      has_been_patch_device_features=1
      patch_device_features $MODPATH
      add_post_fs_data 'patch_device_features $MODDIR'
    fi
    patch_wild_boost $MODPATH
    add_post_fs_data 'patch_wild_boost $MODDIR'
  else
    ui_print "- 你选择不解锁游戏工具箱\"狂暴引擎\"UI界面"
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

# 解锁宽高比（实验）功能
if [[ "$API" -ge 34 ]]; then
  ui_print "*********************************************"
  ui_print "- 是否解锁\"实验室\"-\"宽高比（实验）\"功能？"
  ui_print "- [你已知晓]目前该功能小米尚未开放，是否开启暂无任何区别"
  ui_print "  音量+ ：是"
  ui_print "  音量- ：否"
  ui_print "*********************************************"
  key_check
  if [[ "$keycheck" == "KEY_VOLUMEUP" ]]; then
    ui_print "- 已解锁\"实验室\"-\"宽高比（实验）\"功能"
    ui_print "- [你已知晓]目前该功能小米尚未开放，是否开启暂无任何区别"
    if [[ "$has_been_patch_device_features" == 0 ]]; then
      has_been_patch_device_features=1
      patch_device_features $MODPATH
      add_post_fs_data 'patch_app_compat_aspect_ratio_user_settings $MODDIR'
    fi
    patch_app_compat_aspect_ratio_user_settings $MODPATH
    add_post_fs_data 'patch_app_compat_aspect_ratio_user_settings $MODDIR'
  else
    ui_print "- 你选择不解锁\"实验室\"-\"宽高比（实验）\"功能"
  fi
fi

if [[ "$API" -le 34 ]]; then
  ui_print "*********************************************"
  ui_print "- 是否禁用应用预加载？"
  ui_print "  音量+ ：是"
  ui_print "  音量- ：否"
  ui_print "*********************************************"
  key_check
  if [[ "$keycheck" == "KEY_VOLUMEUP" ]]; then
    ui_print "- 已禁用应用预加载"
    add_props "# 禁用应用预加载"
    add_props "persist.sys.prestart.proc=false"
  else
    ui_print "- 你选择不禁用应用预加载"
  fi
fi

if [[ "$API" -le 33 ]]; then
  # 隐藏手势提示线
  ui_print "*********************************************"
  ui_print "- 是否隐藏手势提示线？(仅在默认主题下生效，Android 13 可用)"
  ui_print "  音量+ ：是"
  ui_print "  音量- ：否"
  ui_print "*********************************************"
  key_check
  if [[ "$keycheck" == "KEY_VOLUMEUP" ]]; then
    ui_print "- 已隐藏手势提示线，仅在默认主题下生效"
    settings put global hide_gesture_line 0
    hide_gesture_cue_line $MODPATH
  else
    ui_print "- 你选择不隐藏手势提示线"
  fi
fi

if [[ "$API" -ge 34 ]]; then
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
    ui_print "- [重要提醒]沉浸手势提示线可能会导致部分应用底部有细小白边"
    ui_print "- [重要提醒]如果不生效请尝试给予系统框架和系统桌面的ROOT权限"
    ui_print "  音量+ ：沉浸"
    ui_print "  音量- ：隐藏"
    ui_print "*********************************************"
    key_check
    if [[ "$keycheck" == "KEY_VOLUMEUP" ]]; then
      ui_print "- 已沉浸手势提示线，仅在默认主题下生效"
      ui_print "- [重要提醒]沉浸手势提示线可能会导致部分应用底部有细小白边"
      ui_print "- [重要提醒]如果不生效请尝试给予系统框架和系统桌面的ROOT权限"
      immerse_gesture_cue_line $MODPATH
    else
      ui_print "- 已隐藏手势提示线，仅在默认主题下生效"
      ui_print "- [重要提醒]如果不生效请尝试给予系统框架和系统桌面的ROOT权限"
      hide_gesture_cue_line $MODPATH
    fi
  else
    ui_print "- 你选择不优化手势提示线"
  fi
fi

# 启用动态壁纸景深
# if [[ "$API" -ge 35 ]]; then
#   ui_print "*********************************************"
#   ui_print "- 是否启用动态壁纸景深"
#   ui_print "  音量+ ：是"
#   ui_print "  音量- ：否"
#   ui_print "*********************************************"
#   key_check
#   if [[ "$keycheck" == "KEY_VOLUMEUP" ]]; then
#     ui_print "- 已启用动态壁纸景深"
#     enable_video_depth $MODPATH
#   else
#     ui_print "- 你选择不启用动态壁纸景深"
#   fi
# fi

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
if [[ "$API" -ge 34 && "$is_un_need_patch_background_blur" == '0' ]]; then
  ui_print "*********************************************"
  ui_print "- 是否开启高级材质"
  ui_print "  音量+ ：是"
  ui_print "  音量- ：否"
  ui_print "*********************************************"
  key_check
  if [[ "$keycheck" == "KEY_VOLUMEUP" ]]; then
    ui_print "- 已开启高级材质"
    add_props "# 开启高级材质"
    add_props "persist.sys.background_blur_supported=true"
    add_props "persist.sys.background_blur_status_default=true"
    add_props "persist.sys.background_blur_version=2"
    add_props "persist.sys.advanced_visual_release=3"
  else
    ui_print "*********************************************"
    ui_print "- 你选择不开启高级材质"
    ui_print "*********************************************"
  fi
fi

if [[ "$API" -le 34 ]]; then
  # 解锁小米澎湃AI功能
  ui_print "*********************************************"
  ui_print "- 是否解锁小米系统应用Hyper AI功能？"
  ui_print "- (包括小米笔记AI、小米录音机AI和AI动态壁纸)"
  ui_print "- (不生效请给予对应系统应用root权限或关闭默认卸载)"
  ui_print "  音量+ ：是"
  ui_print "  音量- ：否"
  ui_print "*********************************************"
  key_check
  if [[ "$keycheck" == "KEY_VOLUMEUP" ]]; then
    ui_print "- 已解锁小米系统应用Hyper AI功能"
    unlock_system_app_hyper_ai $MODPATH
  else
    ui_print "- 你选择不解锁小米系统应用Hyper AI功能"
  fi
fi

if [[ "$API" -ge 34 ]]; then
  # 解锁小米天气动态效果
  ui_print "*********************************************"
  ui_print "- 是否解锁小米天气动态效果？"
  ui_print "- (不生效请给予对应小米天气root权限或关闭默认卸载)"
  ui_print "  音量+ ：是"
  ui_print "  音量- ：否"
  ui_print "*********************************************"
  key_check
  if [[ "$keycheck" == "KEY_VOLUMEUP" ]]; then
    ui_print "- 已解锁小米天气动态效果"
    weather_animation_support $MODPATH
  else
    ui_print "- 你选择不解锁小米天气动态效果"
  fi
fi

#开启HDR支持
if [[ "$is_need_patch_hdr_supportd_pad_list" == 1 && "$API" -ge 35 ]]; then
  ui_print "*********************************************"
  ui_print "- 是否开启 HDR 支持？"
  ui_print "- [重要提醒]不支持小米相册的HDR"
  ui_print "  音量+ ：是"
  ui_print "  音量- ：否"
  ui_print "*********************************************"
  key_check

  if [[ "$keycheck" == "KEY_VOLUMEUP" ]]; then
    ui_print "- 已开启 HDR 支持"
    ui_print "- [重要提醒]不支持小米相册的HDR"
    add_props "# 开启 Ultra HDR"
    add_props "persist.sys.support_ultra_hdr=true"
    if [[ "$has_been_patch_device_features" == 0 ]]; then
      has_been_patch_device_features=1
      patch_device_features $MODPATH
      add_post_fs_data 'patch_device_features $MODDIR'
    fi
    patch_hdr_support $MODPATH
    add_post_fs_data 'patch_hdr_support $MODDIR'
  else
    ui_print "- 你选择不开启 HDR 支持"
  fi
fi

# 应用启动延迟优化
if [[ "$API" -ge 35 ]]; then
  # 应用启动延迟优化
  ui_print "*********************************************"
  ui_print "- 是否启用应用启动延迟优化？"
  ui_print "  音量+ ：是"
  ui_print "  音量- ：否"
  ui_print "*********************************************"
  key_check
  if [[ "$keycheck" == "KEY_VOLUMEUP" ]]; then
    ui_print "- 启用应用启动延迟优化"
    ui_print "- (旗舰机型是否启用无明显区别，对中低端机型效果明显)"
    ui_print "- (部分机型处于系统桌面黑名单限制，需搭配修改版系统桌面)"
    add_props "persist.sys.hyper_transition_v=2"
    add_props "persist.sys.hyper_transition=true"
    add_props "ro.miui.shell_anim_enable_fcb=2"
  else
    ui_print "- 你选择不启用应用启动延迟优化"
  fi
fi

ui_print "*********************************************"
ui_print "- 好诶w，模块已经安装完成了，重启平板后生效"
ui_print "- 功能具体支持情况以系统为准"
ui_print "*********************************************"
