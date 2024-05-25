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

patch_eyecare_mode() {
  DEVICE_CODE="$(getprop ro.product.device)"
  SYSTEM_DEVICE_FEATURES_PATH=/system/product/etc/device_features/${DEVICE_CODE}.xml
  MODULE_DEVICE_FEATURES_PATH="$1"/system/product/etc/device_features/${DEVICE_CODE}.xml
  if [[ -f "$MODULE_DEVICE_FEATURES_PATH" ]]; then
    # 节律护眼
    sed -i "$(awk '/<\/features>/{print NR-0; exit}' $MODULE_DEVICE_FEATURES_PATH)i \    <integer name=\"default_eyecare_mode\">2</integer>" $MODULE_DEVICE_FEATURES_PATH
  fi
}