#!/system/bin/sh
# OPlus hayalet PD: resmi yol /proc/charger_cycle
# connect_disable yok. toybox/android sh.

USB=/sys/class/oplus_chg/usb
CYCLE=/proc/charger_cycle
VBUS_UV=3700000
POLL=2
WAIT=2
MODDIR=${MODDIR:-/data/adb/modules/oplus_phantom_chg}
LOG=$MODDIR/phantom.log

last=""
prev_hw=""

trim_log() {
	[ -f "$LOG" ] || return 0
	# ~80 satır tut
	wc -l < "$LOG" 2>/dev/null | grep -q '^[0-9][0-9][0-9]' || return 0
	tail -n 60 "$LOG" > "$LOG.tmp" 2>/dev/null && mv "$LOG.tmp" "$LOG"
}

log() {
	echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "$LOG" 2>/dev/null
	trim_log
}

write_cycle() {
	cmd=$1
	[ "$cmd" = "$last" ] && return 0
	[ -e "$CYCLE" ] || return 1
	if printf '%s\n' "$cmd" > "$CYCLE" 2>/dev/null; then
		last=$cmd
		log "$cmd hw=$hw online=$online present=$present vbus=$vbus"
	fi
}

while [ ! -f "$USB/hw_detect" ] || [ ! -e "$CYCLE" ]; do
	sleep "$WAIT"
done

log "start pid=$$"

while :; do
	if [ ! -f "$USB/hw_detect" ] || [ ! -e "$CYCLE" ]; then
		sleep "$WAIT"
		continue
	fi

	hw=$(cat "$USB/hw_detect" 2>/dev/null)
	online=$(cat "$USB/online" 2>/dev/null)
	present=$(cat "$USB/present" 2>/dev/null)
	vbus=$(cat "$USB/voltage_now" 2>/dev/null)

	case "$hw" in ''|*[!0-9]*) hw=0 ;; esac
	case "$online" in ''|*[!0-9]*) online=0 ;; esac
	case "$present" in ''|*[!0-9]*) present=0 ;; esac
	case "$vbus" in ''|*[!0-9]*) vbus=0 ;; esac

	phantom=0
	if [ "$hw" -eq 0 ]; then
		if [ "$online" -eq 1 ] || [ "$present" -eq 1 ] || [ "$vbus" -gt "$VBUS_UV" ]; then
			phantom=1
		fi
	fi

	if [ "$hw" -eq 1 ]; then
		write_cycle wakelock
	elif [ "$phantom" -eq 1 ]; then
		write_cycle unwakelock
	elif [ "$prev_hw" = "1" ]; then
		write_cycle unwakelock
	fi

	prev_hw=$hw
	sleep "$POLL"
done
