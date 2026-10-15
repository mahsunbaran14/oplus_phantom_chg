#!/system/bin/sh
# post-fs-data: hemen çık. early.sh setsid ile sysfs bekler (boot blok yok).
MODDIR=${0%/*}
export MODDIR
setsid /system/bin/sh "$MODDIR/early.sh" </dev/null >/dev/null 2>&1 &
exit 0
