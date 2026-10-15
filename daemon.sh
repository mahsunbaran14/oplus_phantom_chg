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
last_ui=""
last_cap=""

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

# SystemUI şimşek: Health AC (usb/online + OCP). connect_disable YASAK.
sync_ui() {
	want=$1
	[ "$want" = "$last_ui" ] && return 0
	case "$want" in
	unplug)
		cmd battery unplug -f >/dev/null 2>&1 || return 1
		;;
	reset)
		cmd battery reset -f >/dev/null 2>&1 || return 1
		last_cap=""
		;;
	*) return 1 ;;
	esac
	last_ui=$want
	log "ui $want hw=$hw online=$online present=$present vbus=$vbus"
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
		sync_ui reset
	elif [ "$phantom" -eq 1 ]; then
		write_cycle unwakelock
		sync_ui unplug
		cap=$(cat /sys/class/power_supply/battery/capacity 2>/dev/null)
		case "$cap" in ''|*[!0-9]*) ;; *)
			if [ "$cap" != "$last_cap" ]; then
				cmd battery set level "$cap" >/dev/null 2>&1 && last_cap=$cap
			fi
			;;
		esac
	else
		if [ "$prev_hw" = "1" ]; then
			write_cycle unwakelock
		fi
		sync_ui reset
	fi

	prev_hw=$hw
	sleep "$POLL"
done
