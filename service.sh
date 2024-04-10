#!/system/bin/sh
MODDIR=${0%/*}
# 开启屏幕旋转建议
if [ "$(settings get secure show_rotation_suggestions)" = 0 ]; then
    ui_print "- 开启屏幕旋转建议"
    settings put secure show_rotation_suggestions 1
fi
