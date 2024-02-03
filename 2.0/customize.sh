# 注意 这不是占位符！！这个代码的作用是将模块里的东西全部塞系统里，然后挂上默认权限
SKIPUNZIP=0
# 开启屏幕旋转建议
if [[ $(settings get secure show_rotation_suggestions) == 0 ]]; then
   su -c "settings put secure show_rotation_suggestions 1"
   ui_print "- 开启屏幕旋转建议"
fi