#!/system/bin/sh
# late_start: hayalet şarj daemon. Parent hemen çıkar (ksud services bekler).
MODDIR=${0%/*}
export MODDIR

[ -f /data/adb/service.d/99-phantom-unwakelock.sh ] && rm -f /data/adb/service.d/99-phantom-unwakelock.sh

if [ -f "$MODDIR/daemon.pid" ]; then
	old=$(cat "$MODDIR/daemon.pid")
	kill "$old" 2>/dev/null
	rm -f "$MODDIR/daemon.pid"
fi

# setsid: su/ksud süreç grubundan kop
setsid /system/bin/sh "$MODDIR/daemon.sh" </dev/null >/dev/null 2>&1 &
echo $! > "$MODDIR/daemon.pid"
exit 0
