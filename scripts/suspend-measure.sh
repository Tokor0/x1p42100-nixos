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
	echo "kernel $(uname -r)"
	echo "memsleep $(sed 's/.*\[\(.*\)\].*/\1/' /sys/power/mem_sleep 2>/dev/null)"
	if [ -e /proc/device-tree/psci/power-domain-system/domain-idle-states ]; then
		echo "syspd patched"
	else
		echo "syspd stock"
	fi
	[ -r "$BAT/energy_now" ] && echo "energy $(cat "$BAT/energy_now")"
	[ -r "$BAT/status" ] && echo "status $(cat "$BAT/status")"
	for f in aosd cxsd ddr apss adsp cdsp adsp_island; do
		[ -r "$STATS/$f" ] || continue
		awk -v n="$f" '
			/^Count:/                {c=$2}
			/^Accumulated Duration:/ {d=$3}
			END {print "stat", n, c+0, d+0}
		' "$STATS/$f"
	done
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
			if ($1=="stat") { bc[$2]=$3; bd[$2]=$4 } else b[$1]=$2
			next
		}
		{ if ($1=="stat") { ac[$2]=$3; ad[$2]=$4 } else a[$1]=$2 }
		END {
			dur = a["time"] - b["time"]
			if (dur <= 0) { print "error: non-positive duration"; exit 1 }

			printf "\n=== suspend measurement =======================================\n"
			printf "kernel        : %s\n", a["kernel"]
			printf "mem_sleep     : %s\n", a["memsleep"]
			printf "system_pd DT  : %s\n", a["syspd"]
			printf "suspend window: %.0f s (%.2f h)\n", dur, dur/3600

			if ("energy" in b && "energy" in a) {
				de = (b["energy"] - a["energy"]) / 1000000.0     # uWh -> Wh
				printf "battery       : %.3f Wh drawn -> %.3f W average\n", de, de/(dur/3600)
				if (b["status"] != "Discharging" || a["status"] != "Discharging")
					printf "  WARNING: battery status was %s -> %s; power figure is meaningless on AC\n", \
						b["status"], a["status"]
				if (de < 0.05)
					printf "  WARNING: only %.3f Wh consumed; below gauge resolution, run longer\n", de
			}

			printf "\n%-12s %8s %8s %12s %10s\n", "counter", "before", "after", "delta(s)", "%window"
			split("aosd cxsd ddr apss adsp cdsp adsp_island", order, " ")
			for (i=1; i<=7; i++) {
				k = order[i]
				if (!(k in ac)) continue
				dsec = (ad[k] - bd[k]) / tick
				printf "%-12s %8d %8d %12.2f %9.1f%%\n", k, bc[k], ac[k], dsec, 100*dsec/dur
			}

			printf "\n(aosd/cxsd/ddr/apss are the states of interest. adsp/cdsp accumulate\n")
			printf (" independently of the suspend window and may exceed 100%%.)\n")

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
	report
	;;
esac
