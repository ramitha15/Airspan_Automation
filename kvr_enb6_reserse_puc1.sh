#!/bin/bash

# Total test duration: 30 minutes
DURATION=1800

# Port 8 (stronger path): RSRP -126 -> -94 => 34 dB down to 2 dB attenuation
PORT8_START=34
PORT8_END=2
PORT8_RANGE=$((PORT8_START - PORT8_END))    # 32 dB decrease

# Port 9 (weaker path): RSRP -140 -> -94 => 48 dB down to 2 dB attenuation
PORT9_START=48
PORT9_END=2
PORT9_RANGE=$((PORT9_START - PORT9_END))    # 46 dB decrease

# Loop granularity is set by the larger ramp: 46 x 1 dB steps
STEPS=$PORT9_RANGE                          # 1800 s / 46 steps ~= 39.1 s per step

prev9=-1
prev8=-1
SECONDS=0

for ((i = 0; i <= STEPS; i++)); do
    # Port 8 decrement floored so its attenuation never exceeds port 9's (stays stronger throughout)
    port8_att=$((PORT8_START - PORT8_RANGE * i / STEPS))
    port9_att=$((PORT9_START - i))

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

echo "Completed reverse ramp: Port 8 at ${PORT8_END} dB (RSRP ~ -94), Port 9 at ${PORT9_END} dB (RSRP ~ -94) in $((SECONDS / 60)) min"
