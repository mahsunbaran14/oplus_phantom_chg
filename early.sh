#!/system/bin/sh
# post-fs-data setsid çocuğu. Boot'u bloklamaz. Sysfs gelince bir kez yazar.

USB=/sys/class/oplus_chg/usb
CYCLE=/proc/charger_cycle
MODDIR=${MODDIR:-/data/adb/modules/oplus_phantom_chg}
LOG=$MODDIR/phantom.log

log() {
	echo "$(date '+%Y-%m-%d %H:%M:%S') pfs $*" >> "$LOG" 2>/dev/null
}

log "early pid=$$"

i=0
while [ "$i" -lt 75 ]; do
	if [ -e "$CYCLE" ] && [ -f "$USB/hw_detect" ]; then
		hw=$(cat "$USB/hw_detect" 2>/dev/null)
		online=$(cat "$USB/online" 2>/dev/null)
		present=$(cat "$USB/present" 2>/dev/null)
		vbus=$(cat "$USB/voltage_now" 2>/dev/null)
		case "$hw" in ''|*[!0-9]*) hw=0 ;; esac
		case "$online" in ''|*[!0-9]*) online=0 ;; esac
		case "$present" in ''|*[!0-9]*) present=0 ;; esac
		case "$vbus" in ''|*[!0-9]*) vbus=0 ;; esac
		if [ "$hw" -eq 1 ]; then
			cmd=wakelock
		else
			cmd=unwakelock
		fi
		if printf '%s\n' "$cmd" > "$CYCLE" 2>/dev/null; then
			log "$cmd hw=$hw online=$online present=$present vbus=$vbus i=$i"
		else
			log "write-fail cmd=$cmd i=$i"
		fi
		exit 0
	fi
	sleep 0.2
	i=$((i + 1))
done

log "timeout no-sysfs"
exit 0
