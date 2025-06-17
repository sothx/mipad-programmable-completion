mkdir -p "/dev/mount_lib/product_overlay"
cp -af "$MODDIR/overlay.img" "/dev/mount_lib"
mount "/dev/mount_lib/overlay.img" "/dev/mount_lib/product_overlay"
mount -t overlay -o lowerdir="/dev/mount_lib/product_overlay:/product/overlay" overlay /product/overlay
