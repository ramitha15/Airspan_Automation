#!/bin/bash

# Total test duration: 30 minutes
DURATION=1800

# Port 9: RSRP -92 -> -117  => +25 dB attenuation over the run
PORT9_START=0                      # attenuation that gives RSRP ~ -92 on port 9
PORT9_RANGE=30

# Port 8: starts at port9 RSRP + 2 (-94), ends at -129 => +35 dB attenuation
PORT8_START=$((PORT9_START + 2))
PORT8_RANGE=40

# Loop granularity is set by the larger ramp: 35 x 1 dB steps
STEPS=$PORT8_RANGE                  # 1800 s / 35 steps ~= 51.4 s per step

prev9=-1
prev8=-1
SECONDS=0

for ((i = 0; i <= STEPS; i++)); do
    # Port 9 interpolated with rounding: 25 dB spread over 35 steps (~1 dB / 72 s)
    port9_att=$((PORT9_START + (PORT9_RANGE * i + STEPS / 2) / STEPS))
    port8_att=$((PORT8_START + i))

    if [ "$port9_att" -ne "$prev9" ]; then
        echo "$(date '+%H:%M:%S')  Setting Port 9 attenuation to ${port9_att} dB"
        ./setGain1port.sh "$port9_att" 8
        prev9=$port9_att
    fi

    if [ "$port8_att" -ne "$prev8" ]; then
        echo "$(date '+%H:%M:%S')  Setting Port 8 attenuation to ${port8_att} dB"
        ./setGain1port.sh "$port8_att" 9
        prev8=$port8_att
    fi

    # Drift-free sleep: wake at the exact scheduled time of the next step
    if [ "$i" -lt "$STEPS" ]; then
        target=$(((i + 1) * DURATION / STEPS))
        sleep_for=$((target - SECONDS))
        [ "$sleep_for" -gt 0 ] && sleep "$sleep_for"
    fi
done

echo "Completed ramp: Port 9 at $((PORT9_START + PORT9_RANGE)) dB (RSRP ~ -117), Port 8 at $((PORT8_START + PORT8_RANGE)) dB (RSRP ~ -129) in $((SECONDS / 60)) min"
