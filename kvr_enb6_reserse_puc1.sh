#!/bin/bash

# Total test duration: 30 minutes
DURATION=1800

# Port 9: starts at 30 dB attenuation, ramps down to 0 dB
PORT9_START=30
PORT9_END=0
PORT9_RANGE=$((PORT9_START - PORT9_END))    # 30 dB decrease

# Port 8: starts at port9 start + 10 (40 dB), ramps down to 2 dB
PORT8_START=$((PORT9_START + 10))
PORT8_END=2
PORT8_RANGE=$((PORT8_START - PORT8_END))    # 38 dB decrease

# Loop granularity is set by the larger ramp
STEPS=$PORT8_RANGE                          # 1800 s / 38 steps ~= 47.4 s per step

prev9=-1
prev8=-1
SECONDS=0

for ((i = 0; i <= STEPS; i++)); do
    # Port 9 interpolated with rounding: 30 dB spread over 38 steps, decreasing
    port9_att=$((PORT9_START - (PORT9_RANGE * i + STEPS / 2) / STEPS))
    port8_att=$((PORT8_START - i))

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

echo "Completed reverse ramp: Port 9 at ${PORT9_END} dB, Port 8 at ${PORT8_END} dB in $((SECONDS / 60)) min"
