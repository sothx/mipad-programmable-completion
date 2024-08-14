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

  # 移除旧版补丁文件
  rm -rf "$MODULE_DEVICE_FEATURES_PATH"

  # 复制系统内配置到模块内
  cp -f "$SYSTEM_DEVICE_FEATURES_PATH" "$MODULE_DEVICE_FEATURES_PATH"
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

immerse_gesture_cue_line() {
  # 沉浸手势提示线
  cp -rf "$1"/common/immerse_gesture_cue_line/* "$1"/system/product/media/theme/default/
}

hide_gesture_cue_line() {
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
