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

set_perm() {
  chown $2:$3 $1 || return 1
  chmod $4 $1 || return 1
  local CON=$5
  [ -z $CON ] && CON=u:object_r:system_file:s0
  chcon $CON $1 || return 1
}

set_perm_recursive() {
  find $1 -type d 2>/dev/null | while read dir; do
    set_perm $dir $2 $3 $4 $6
  done
  find $1 -type f -o -type l 2>/dev/null | while read file; do
    set_perm $file $2 $3 $5 $6
  done
}

grep_prop() {
  local REGEX="s/^$1=//p"
  shift
  local FILES=$@
  [ -z "$FILES" ] && FILES='/system/build.prop'
  cat $FILES 2>/dev/null | dos2unix | sed -n "$REGEX" | head -n 1
}

update_system_prop() {
  local prop="$1"
  local value="$2"
  local file="$3"

  if grep -q "^$prop=" "$file"; then
    # 如果找到匹配行，使用 sed 进行替换
    sed -i "s/^$prop=.*/$prop=$value/" "$file"
  else
    # 如果没有找到匹配行，追加新行
    printf "$prop=$value\n" >> "$file"
  fi
}

remove_system_prop() {
  local prop="$1"
  local file="$2"
  sed -i "/^$prop=/d" "$file"
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
    if grep -q '<integer name="support_max_fps">144<\/integer>' $MODULE_DEVICE_FEATURES_PATH; then
      sed -i "$(awk '/<integer name="smart_fps_value">120<\/integer>/{print NR+2; exit}' $MODULE_DEVICE_FEATURES_PATH)i \    \    <item>144</item>" $MODULE_DEVICE_FEATURES_PATH
      sed -i 's/<integer name="smart_fps_value">120<\/integer>/<integer name="smart_fps_value">144<\/integer>/g' $MODULE_DEVICE_FEATURES_PATH
      sed -i '/<integer name="support_max_fps">144<\/integer>/d' $MODULE_DEVICE_FEATURES_PATH
    else
      sed -i "$(awk '/<integer name="smart_fps_value">144<\/integer>/{print NR+3; exit}' $MODULE_DEVICE_FEATURES_PATH)i \    \    <item>120</item>" $MODULE_DEVICE_FEATURES_PATH
    fi
  fi
}

patch_full_fps() {
  DEVICE_CODE="$(getprop ro.product.device)"
  SYSTEM_DEVICE_FEATURES_PATH=/system/product/etc/device_features/${DEVICE_CODE}.xml
  MODULE_DEVICE_FEATURES_PATH="$1"/system/product/etc/device_features/${DEVICE_CODE}.xml
  if [[ -f "$MODULE_DEVICE_FEATURES_PATH" ]]; then
    if grep -q '<integer name="support_max_fps">144<\/integer>' $MODULE_DEVICE_FEATURES_PATH; then
      sed -i "$(awk '/<integer-array name="fpsList">/{print NR+1; exit}' $MODULE_DEVICE_FEATURES_PATH)i \    \    <item>144</item>" $MODULE_DEVICE_FEATURES_PATH
      sed -i "$(awk '/<integer-array name="fpsList">/{print NR+5; exit}' $MODULE_DEVICE_FEATURES_PATH)i \    \    <item>50</item>" $MODULE_DEVICE_FEATURES_PATH
      sed -i "$(awk '/<integer-array name="fpsList">/{print NR+6; exit}' $MODULE_DEVICE_FEATURES_PATH)i \    \    <item>48</item>" $MODULE_DEVICE_FEATURES_PATH
      sed -i "$(awk '/<integer-array name="fpsList">/{print NR+7; exit}' $MODULE_DEVICE_FEATURES_PATH)i \    \    <item>30</item>" $MODULE_DEVICE_FEATURES_PATH
      sed -i 's/<integer name="smart_fps_value">120<\/integer>/<integer name="smart_fps_value">144<\/integer>/g' $MODULE_DEVICE_FEATURES_PATH
      sed -i '/<integer name="support_max_fps">144<\/integer>/d' $MODULE_DEVICE_FEATURES_PATH
    else
      if [[ "$DEVICE_CODE" == 'pipa' ]]; then
        sed -i "$(awk '/<integer name="smart_fps_value">144<\/integer>/{print NR+3; exit}' $MODULE_DEVICE_FEATURES_PATH)i \    \    <item>120</item>" $MODULE_DEVICE_FEATURES_PATH
        sed -i "$(awk '/<integer name="smart_fps_value">144<\/integer>/{print NR+6; exit}' $MODULE_DEVICE_FEATURES_PATH)i \    \    <item>50</item>" $MODULE_DEVICE_FEATURES_PATH
        sed -i "$(awk '/<integer name="smart_fps_value">144<\/integer>/{print NR+7; exit}' $MODULE_DEVICE_FEATURES_PATH)i \    \    <item>48</item>" $MODULE_DEVICE_FEATURES_PATH
        sed -i "$(awk '/<integer name="smart_fps_value">144<\/integer>/{print NR+8; exit}' $MODULE_DEVICE_FEATURES_PATH)i \    \    <item>30</item>" $MODULE_DEVICE_FEATURES_PATH
      else
        sed -i "$(awk '/<integer-array name="fpsList">/{print NR+2; exit}' $MODULE_DEVICE_FEATURES_PATH)i \    \    <item>120</item>" $MODULE_DEVICE_FEATURES_PATH
        sed -i "$(awk '/<integer-array name="fpsList">/{print NR+5; exit}' $MODULE_DEVICE_FEATURES_PATH)i \    \    <item>50</item>" $MODULE_DEVICE_FEATURES_PATH
        sed -i "$(awk '/<integer-array name="fpsList">/{print NR+6; exit}' $MODULE_DEVICE_FEATURES_PATH)i \    \    <item>48</item>" $MODULE_DEVICE_FEATURES_PATH
        sed -i "$(awk '/<integer-array name="fpsList">/{print NR+7; exit}' $MODULE_DEVICE_FEATURES_PATH)i \    \    <item>30</item>" $MODULE_DEVICE_FEATURES_PATH
      fi
    fi
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

unlock_system_app_hyper_ai() {

  if [[ ! -d "$1"/system/product/overlay ]]; then
    mkdir -p "$1"/system/product/overlay/
  fi

  cp -rf "$1"/common/hyper_ai_supported/* "$1"/system/product/overlay/
}

patch_celluar_shared() {

  if [[ ! -d "$1"/system/product/media/theme/default/ ]]; then
    mkdir -p "$1"/system/product/media/theme/default/
  fi

  # 启用通信共享
  cp -rf "$1"/common/celluar_shared/* "$1"/system/product/media/theme/default/
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
  MI_OS_VERSION="$(getprop ro.mi.os.version.code)"
  # 判断 MI_OS_VERSION 是否大于等于 2
  if [ "$MI_OS_VERSION" -ge 2 ]; then
    XIAOMI_MSLGRDP_PATH='/storage/emulated/0/HyperEngine'
    WPS_OFFICE_PC_FONTS_DIR="$XIAOMI_MSLGRDP_PATH/fonts"
  else
    XIAOMI_MSLGRDP_PATH='/data/rootfs/home/xiaomi'
    WPS_OFFICE_PC_FONTS_DIR="$XIAOMI_MSLGRDP_PATH/.fonts"
  fi
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

patch_aon_proximity_available() {
  DEVICE_CODE="$(getprop ro.product.device)"
  SYSTEM_DEVICE_FEATURES_PATH=/system/product/etc/device_features/${DEVICE_CODE}.xml
  MODULE_DEVICE_FEATURES_PATH="$1"/system/product/etc/device_features/${DEVICE_CODE}.xml
  if [[ -f "$MODULE_DEVICE_FEATURES_PATH" ]]; then
    # 解锁视频工具箱智能刷新率
    sed -i "$(awk '/<\/features>/{print NR-0; exit}' $MODULE_DEVICE_FEATURES_PATH)i \    <bool name=\"config_aon_proximity_available\">true</bool>" $MODULE_DEVICE_FEATURES_PATH
  fi
}

patch_perfinit_bdsize_zram() {
  DEVICE_CODE="$(getprop ro.product.device)"
  SYSTEM_PERFINIT_BDSIZE_ZRAM_PATH=/system/system_ext/etc/perfinit_bdsize_zram.conf
  MODULE_PERFINIT_BDSIZE_ZRAM_PATH="$1"/system/system_ext/etc/perfinit_bdsize_zram.conf
  JQ_UTILS="$1"/common/utils/jq

  if [[ ! -d "$1"/system/system_ext/etc/ ]]; then
    mkdir -p "$1"/system/system_ext/etc/
  fi

  # 移除旧版补丁文件
  rm -rf "$MODULE_PERFINIT_BDSIZE_ZRAM_PATH"

  # 复制系统内配置到模块内
  cp -f "$SYSTEM_PERFINIT_BDSIZE_ZRAM_PATH" "$MODULE_PERFINIT_BDSIZE_ZRAM_PATH"
}

patch_zram_config() {
    MODULE_PERFINIT_BDSIZE_ZRAM_PATH="$1"/system/system_ext/etc/perfinit_bdsize_zram.conf
    DEVICE_CODE="$(getprop ro.product.device)"
    MODULE_ZRAM_TEMPLATE="$1"/common/zram_template/"$DEVICE_CODE".json
    $JQ_UTILS '.zram += [input | {product_name, zram_size}]' $MODULE_PERFINIT_BDSIZE_ZRAM_PATH $MODULE_ZRAM_TEMPLATE > temp.json && mv temp.json $MODULE_PERFINIT_BDSIZE_ZRAM_PATH
}

patch_hdr_support() {
  DEVICE_CODE="$(getprop ro.product.device)"
  SYSTEM_DEVICE_FEATURES_PATH=/system/product/etc/device_features/${DEVICE_CODE}.xml
  MODULE_DEVICE_FEATURES_PATH="$1"/system/product/etc/device_features/${DEVICE_CODE}.xml
  if [[ -f "$MODULE_DEVICE_FEATURES_PATH" ]]; then
    # 开启HDR增强
    sed -i "$(awk '/<\/features>/{print NR-0; exit}' $MODULE_DEVICE_FEATURES_PATH)i \    <bool name=\"support_hdr_enhance\">true</bool>" $MODULE_DEVICE_FEATURES_PATH
  fi
}

weather_animation_support() {
  if [[ ! -d "$1"/system/product/overlay ]]; then
    mkdir -p "$1"/system/product/overlay/
  fi

  cp -rf "$1"/common/weather_animateion_support/* "$1"/system/product/weather_animateion_support/
}