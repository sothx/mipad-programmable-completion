api_level_arch_detect() {
  API=$(getprop ro.build.version.sdk)
  ABI=$(getprop ro.product.cpu.abi)
  if [ "$ABI" = "x86" ]; then
    ARCH=x86
    ABI32=x86
    IS64BIT=false
  elif [ "$ABI" = "arm64-v8a" ]; then
    ARCH=arm64
    ABI32=armeabi-v7a
    IS64BIT=true
  elif [ "$ABI" = "x86_64" ]; then
    ARCH=x64
    ABI32=x86
    IS64BIT=true
  else
    ARCH=arm
    ABI=armeabi-v7a
    ABI32=armeabi-v7a
    IS64BIT=false
  fi
}

# 获取设备类型
check_device_type() {
  local redmi_pad_list=$1
  local device_code=$2
  local result="xiaomi"
  for i in $redmi_pad_list; do
    if [[ "$device_code" == "$i" ]]; then
      result=redmi
      break
    fi
  done
  echo $result
}

# 根据机型列表判断是否需要补全对应机型的功能
check_device_is_need_patch() {
  local device_code=$1
  local pad_list=$2
  local result=0

  for i in $pad_list; do
    if [[ "$device_code" == "$i" ]]; then
      result=1
      break
    fi
  done

  echo $result
}

patch_device_features() {
  DEVICE_CODE="$(getprop ro.product.device)"
  SYSTEM_DEVICE_FEATURES_PATH=/system/product/etc/device_features/${DEVICE_CODE}.xml
  MODULE_DEVICE_FEATURES_PATH="$1"/system/product/etc/device_features/${DEVICE_CODE}.xml

  if [[ ! -d "$1"/system/product/etc/device_features/ ]]; then
    mkdir -p "$1"/system/product/etc/device_features/
  fi

  # 移除旧版补丁文件
  rm -rf "$MODULE_DEVICE_FEATURES_PATH"

  # 复制系统内配置到模块内
  cp -f "$SYSTEM_DEVICE_FEATURES_PATH" "$MODULE_DEVICE_FEATURES_PATH"
}

patch_cn_google_services() {
  MODULE_CN_GOOGLE_SERVICES_PATH="$1"/system/product/etc/permissions/

  if [[ ! -d $MODULE_CN_GOOGLE_SERVICES_PATH ]]; then
    mkdir -p $MODULE_CN_GOOGLE_SERVICES_PATH
  fi

  # 移除旧版补丁文件
  rm -rf "$MODULE_DEVICE_FEATURES_PATH"cn.google.services.xml

  cp -rf "$1"/common/cn_google_services/* "$MODULE_CN_GOOGLE_SERVICES_PATH"
}

patch_120hz_fps() {
  DEVICE_CODE="$(getprop ro.product.device)"
  SYSTEM_DEVICE_FEATURES_PATH=/system/product/etc/device_features/${DEVICE_CODE}.xml
  MODULE_DEVICE_FEATURES_PATH="$1"/system/product/etc/device_features/${DEVICE_CODE}.xml
  if [[ -f "$MODULE_DEVICE_FEATURES_PATH" ]]; then
    # 补全120hz
    sed -i "$(awk '/<integer name="smart_fps_value">144<\/integer>/{print NR+3; exit}' $MODULE_DEVICE_FEATURES_PATH)i \    \    <item>120</item>" $MODULE_DEVICE_FEATURES_PATH
  fi
}

patch_remove_screen_off_hold_on() {
  DEVICE_CODE="$(getprop ro.product.device)"
  SYSTEM_DEVICE_FEATURES_PATH=/system/product/etc/device_features/${DEVICE_CODE}.xml
  MODULE_DEVICE_FEATURES_PATH="$1"/system/product/etc/device_features/${DEVICE_CODE}.xml
  if [[ -f "$MODULE_DEVICE_FEATURES_PATH" ]]; then
    # 启用熄屏听剧/熄屏挂机
    sed -i 's/<bool name="remove_screen_off_hold_on">true<\/bool>/<bool name="remove_screen_off_hold_on">false<\/bool>/g' $MODULE_DEVICE_FEATURES_PATH
  fi
}

patch_support_video_dfps() {
  DEVICE_CODE="$(getprop ro.product.device)"
  SYSTEM_DEVICE_FEATURES_PATH=/system/product/etc/device_features/${DEVICE_CODE}.xml
  MODULE_DEVICE_FEATURES_PATH="$1"/system/product/etc/device_features/${DEVICE_CODE}.xml
  if [[ -f "$MODULE_DEVICE_FEATURES_PATH" ]]; then
    # 解锁视频工具箱智能刷新率
    sed -i "$(awk '/<\/features>/{print NR-0; exit}' $MODULE_DEVICE_FEATURES_PATH)i \    <bool name=\"support_video_dfps\">true</bool>" $MODULE_DEVICE_FEATURES_PATH
  fi
}

patch_eyecare_mode() {
  DEVICE_CODE="$(getprop ro.product.device)"
  SYSTEM_DEVICE_FEATURES_PATH=/system/product/etc/device_features/${DEVICE_CODE}.xml
  MODULE_DEVICE_FEATURES_PATH="$1"/system/product/etc/device_features/${DEVICE_CODE}.xml
  if [[ -f "$MODULE_DEVICE_FEATURES_PATH" ]]; then
    # 节律护眼
    sed -i "$(awk '/<\/features>/{print NR-0; exit}' $MODULE_DEVICE_FEATURES_PATH)i \    <integer name=\"default_eyecare_mode\">2</integer>" $MODULE_DEVICE_FEATURES_PATH
  fi
}

patch_wild_boost() {
  DEVICE_CODE="$(getprop ro.product.device)"
  SYSTEM_DEVICE_FEATURES_PATH=/system/product/etc/device_features/${DEVICE_CODE}.xml
  MODULE_DEVICE_FEATURES_PATH="$1"/system/product/etc/device_features/${DEVICE_CODE}.xml
  if [[ -f "$MODULE_DEVICE_FEATURES_PATH" ]]; then
    # 游戏工具箱狂暴引擎UI
    sed -i "$(awk '/<\/features>/{print NR-0; exit}' $MODULE_DEVICE_FEATURES_PATH)i \    <bool name=\"support_wild_boost\">true</bool>" $MODULE_DEVICE_FEATURES_PATH
    # 设置、控制中心狂暴引擎UI(安全管家 9.0+)
    sed -i "$(awk '/<\/features>/{print NR-0; exit}' $MODULE_DEVICE_FEATURES_PATH)i \    <bool name=\"support_wild_boost_bat_perf\">true</bool>" $MODULE_DEVICE_FEATURES_PATH
  fi
}

immerse_gesture_cue_line() {
  
  if [[ ! -d "$1"/system/product/media/theme/default/ ]]; then
    mkdir -p "$1"/system/product/media/theme/default/
  fi
  
  # 沉浸手势提示线
  cp -rf "$1"/common/immerse_gesture_cue_line/* "$1"/system/product/media/theme/default/
}

hide_gesture_cue_line() {

  if [[ ! -d "$1"/system/product/media/theme/default/ ]]; then
    mkdir -p "$1"/system/product/media/theme/default/
  fi
  
  # 隐藏手势提示线
  cp -rf "$1"/common/hide_gesture_cue_line/* "$1"/system/product/media/theme/default/
}

grep_prop() {
  local REGEX="s/^$1=//p"
  shift
  local FILES=$@
  [ -z "$FILES" ] && FILES='/system/build.prop'
  cat $FILES 2>/dev/null | dos2unix | sed -n "$REGEX" | head -n 1
}

show_rotation_suggestions() {
  # 开启旋转建议提示按钮
  settings put secure show_rotation_suggestions 1
}

create_fonts_dir() {
  XIAOMI_MSLGRDP_PATH=/data/rootfs/home/xiaomi
  WPS_OFFICE_PC_FONTS_DIR="$XIAOMI_MSLGRDP_PATH/.fonts"
  if [[ -d "$XIAOMI_MSLGRDP_PATH" && ! -d "$WPS_OFFICE_PC_FONTS_DIR" ]]; then
    /bin/mkdir -p "$WPS_OFFICE_PC_FONTS_DIR"
  fi
  if [[ -d "$WPS_OFFICE_PC_FONTS_DIR" ]]; then
    /bin/chmod -R 777 "$FONTS_DIR"
  fi
}

patch_app_compat_aspect_ratio_user_settings() {
  DEVICE_CODE="$(getprop ro.product.device)"
  SYSTEM_DEVICE_FEATURES_PATH=/system/product/etc/device_features/${DEVICE_CODE}.xml
  MODULE_DEVICE_FEATURES_PATH="$1"/system/product/etc/device_features/${DEVICE_CODE}.xml
  if [[ -f "$MODULE_DEVICE_FEATURES_PATH" ]]; then
    # 宽高比实验
    sed -i "$(awk '/<\/features>/{print NR-0; exit}' $MODULE_DEVICE_FEATURES_PATH)i \    <bool name=\"enable_app_compat_aspect_ratio_user_settings\">true</bool>" $MODULE_DEVICE_FEATURES_PATH
  fi
}
