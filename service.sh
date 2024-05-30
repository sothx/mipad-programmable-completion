MODDIR=${0%/*}

wait_login() {
  while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 1
  done

  while [ ! -d "/sdcard/Android" ]; do
    sleep 1
  done
}
wait_login

. "$MODDIR"/util_functions.sh
api_level_arch_detect


