#!/usr/bin/env bash
# Measure what the SoC actually does during suspend, in the form the
# linux-arm-msm thread on the hamoa system power domain needs.
#
#   sudo ./scripts/suspend-measure.sh begin     # snapshot, then suspend yourself
#   sudo ./scripts/suspend-measure.sh suspend   # snapshot and suspend immediately
#   sudo ./scripts/suspend-measure.sh end       # after resuming: snapshot + report
#
# The pm8xxx RTC on this machine exposes no wakealarm, so rtcwake cannot drive
# this; suspend and resume by hand (lid or power button).
#
# The qcom_stats counters give a binary answer in ~60 s: if aosd/cxsd/ddr stay
# at 0 the SoC never left its always-on state. A trustworthy *power* number
# needs longer -- the battery gauge quantises at ~10 mWh, so aim for 30 min+.

set -uo pipefail

STATS=/sys/kernel/debug/qcom_stats
BAT=/sys/class/power_supply/qcom-battmgr-bat
STATE=/var/tmp/suspend-measure.state
TICK_HZ=19200000   # RPMh sleep-stat timebase (XO), verified against wall clock

usage() { sed -n '2,14p' "$0" | sed 's/^# \?//'; }

case "${1:-}" in
begin | suspend | end) ;;
*)
	usage
	exit 1
	;;
esac

[ "$(id -u)" -eq 0 ] || exec sudo -- "$0" "$@"

snapshot() {
	echo "time $(date +%s)"
	echo "bootid $(cat /proc/sys/kernel/random/boot_id)"
	echo "kernel $(uname -r)"
	echo "memsleep $(sed 's/.*\[\(.*\)\].*/\1/' /sys/power/mem_sleep 2>/dev/null)"
	if [ -e /proc/device-tree/psci/power-domain-system/domain-idle-states ]; then
		echo "syspd patched"
	else
		echo "syspd stock"
	fi
	[ -r "$BAT/energy_now" ] && echo "energy $(cat "$BAT/energy_now")"
	[ -r "$BAT/status" ] && echo "status $(cat "$BAT/status")"
	# Interrupt counts, summed across CPUs. Under s2idle the CPUs stay online
	# and any IRQ prevents the domain hierarchy from powering down, so the
	# delta across a suspend names whatever is keeping the AP awake.
	awk '$1 ~ /^[0-9]+:$/ {
		irq = $1; sub(/:$/, "", irq)
		sum = 0; i = 2
		while (i <= NF && $i ~ /^[0-9]+$/) { sum += $i; i++ }
		name = ""
		for (; i <= NF; i++) name = name (name ? "_" : "") $i
		print "irq", irq, sum, name
	}' /proc/interrupts
	for f in aosd cxsd ddr apss adsp cdsp adsp_island; do
		[ -r "$STATS/$f" ] || continue
		awk -v n="$f" '
			/^Count:/                {c=$2}
			/^Accumulated Duration:/ {d=$3}
			END {print "stat", n, c+0, d+0}
		' "$STATS/$f"
	done
}

# Total time actually spent suspended since $1, from the kernel's own
# PM: suspend entry/exit records. The begin->end wall window also covers
# however long you took to reach the power menu, so percentages computed
# against it understate how well the SoC did.
susp_window() {
	journalctl -k -o short-unix --since "@$1" --no-pager 2>/dev/null | awk '
		/PM: suspend entry/ { t=$1; sub(/\..*/,"",t); ent=t }
		/PM: suspend exit/  { if (ent) { t=$1; sub(/\..*/,"",t); tot += t-ent; n++; ent=0 } }
		END { printf "%d %d\n", tot+0, n+0 }'
}

require_stats() {
	if [ ! -d "$STATS" ]; then
		echo "error: $STATS missing -- is the qcom_stats module loaded?" >&2
		exit 1
	fi
}

report() {
	awk -v tick="$TICK_HZ" '
		FNR==NR {
			if ($1=="stat")     { bc[$2]=$3; bd[$2]=$4 }
			else if ($1=="irq") { bi[$2]=$3 }
			else                { b[$1]=$2 }
			next
		}
		{
			if ($1=="stat")     { ac[$2]=$3; ad[$2]=$4 }
			else if ($1=="irq") { ai[$2]=$3; an[$2]=$4 }
			else                { a[$1]=$2 }
		}
		END {
			dur = a["time"] - b["time"]
			if (dur <= 0) { print "error: non-positive duration"; exit 1 }
			if (a["bootid"] != b["bootid"]) {
				print "error: rebooted between begin and end -- the qcom_stats"
				print "       counters reset at boot, so these deltas are meaningless."
				print "       Re-run 'begin', suspend, then 'end' without rebooting."
				exit 1
			}

			printf "\n=== suspend measurement =======================================\n"
			printf "kernel        : %s\n", a["kernel"]
			printf "mem_sleep     : %s\n", a["memsleep"]
			printf "system_pd DT  : %s\n", a["syspd"]
			susp = a["susptotal"] + 0
			nsusp = a["suspcount"] + 0
			base = (susp > 0) ? susp : dur
			printf "measured window: %.0f s (%.2f h)\n", dur, dur/3600
			if (susp > 0)
				printf "actually suspended: %.0f s in %d cycle(s); %.0f s awake\n", \
					susp, nsusp, dur - susp
			else
				printf "actually suspended: no PM: suspend entry/exit found in window\n"

			if ("energy" in b && "energy" in a) {
				de = (b["energy"] - a["energy"]) / 1000000.0     # uWh -> Wh
				printf "battery       : %.3f Wh drawn -> %.3f W average\n", de, de/(dur/3600)
				if (b["status"] != "Discharging" || a["status"] != "Discharging")
					printf "  WARNING: battery status was %s -> %s; power figure is meaningless on AC\n", \
						b["status"], a["status"]
				if (de < 0.05)
					printf "  WARNING: only %.3f Wh consumed; below gauge resolution, run longer\n", de
			}

			printf "\n%-12s %8s %8s %12s %10s\n", "counter", "before", "after", "delta(s)", "%susp"
			split("aosd cxsd ddr apss adsp cdsp adsp_island", order, " ")
			for (i=1; i<=7; i++) {
				k = order[i]
				if (!(k in ac)) continue
				dsec = (ad[k] - bd[k]) / tick
				printf "%-12s %8d %8d %12.2f %9.1f%%\n", k, bc[k], ac[k], dsec, 100*dsec/base
			}

			printf "\n(aosd/cxsd/ddr/apss are the states of interest. adsp/cdsp accumulate\n"
			printf " independently of the suspend window and may exceed 100%%.)\n"

			tot = 0
			for (k in ai) { d = ai[k] - bi[k]; if (d > 0) tot += d }
			if (tot > 0) {
				printf "\ntop interrupt sources over the window (%d total, %.1f/s while suspended):\n", \
					tot, tot/base
				cmd = "sort -k2 -rn | head -12"
				for (k in ai) {
					d = ai[k] - bi[k]
					if (d > 0) printf "  %-6s %9d  %s\n", k, d, an[k] | cmd
				}
				close(cmd)
			}

			ok = (ac["aosd"] > bc["aosd"]) && (ac["cxsd"] > bc["cxsd"]) && (ac["ddr"] > bc["ddr"])
			printf "\nverdict: "
			if (ok)
				print "PASS -- aosd/cxsd/ddr all advanced; the SoC reached system sleep."
			else
				print "FAIL -- aosd/cxsd/ddr did not all advance; SoC stayed powered."
			printf "===============================================================\n\n"
		}
	' "$STATE" "$STATE.after"
}

case "${1:-}" in
begin)
	require_stats
	snapshot > "$STATE"
	echo "snapshot saved to $STATE"
	echo "now suspend the machine; after resuming run: sudo $0 end"
	;;
suspend)
	require_stats
	snapshot > "$STATE"
	echo "snapshot saved; suspending. After resuming run: sudo $0 end"
	sync
	systemctl suspend
	;;
end)
	require_stats
	if [ ! -s "$STATE" ]; then
		echo "error: no snapshot at $STATE -- run '$0 begin' first" >&2
		exit 1
	fi
	snapshot > "$STATE.after"
	read -r sw sn < <(susp_window "$(awk '$1=="time"{print $2}' "$STATE")")
	{ echo "susptotal $sw"; echo "suspcount $sn"; } >> "$STATE.after"
	report
	;;
esac
