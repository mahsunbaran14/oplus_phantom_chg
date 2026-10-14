#!/system/bin/sh
MODDIR=${0%/*}
if [ -f "$MODDIR/daemon.pid" ]; then
	kill "$(cat "$MODDIR/daemon.pid")" 2>/dev/null
fi
rm -f /data/adb/service.d/99-phantom-unwakelock.sh
