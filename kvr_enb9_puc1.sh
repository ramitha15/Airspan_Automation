#!/bin/bash

# Total test duration: 20 minutes
DURATION=1200

# Port 20 (first): 101 dB -> 117 dB (RSRP ~ -117)  => +16 dB over the run
PORT1_START=101
PORT1_END=117
PORT1_RANGE=$((PORT1_END - PORT1_START))

# Port 21 (second): 105 dB -> 129 dB (RSRP ~ -129) => +24 dB over the run
PORT2_START=105
PORT2_END=129
PORT2_RANGE=$((PORT2_END - PORT2_START))

# Loop granularity is set by the larger ramp: 24 x 1 dB steps
STEPS=$PORT2_RANGE                  # 1200 s / 24 steps = 50 s per step

prev1=-1
prev2=-1
SECONDS=0

for ((i = 0; i <= STEPS; i++)); do
    # Port 20 interpolated with rounding: 16 dB spread over 24 steps (~1 dB / 75 s)
    port1_att=$((PORT1_START + (PORT1_RANGE * i + STEPS / 2) / STEPS))
    port2_att=$((PORT2_START + i))

    if [ "$port1_att" -ne "$prev1" ]; then
        echo "$(date '+%H:%M:%S')  Setting Port 20 attenuation to ${port1_att} dB"
        ./setGain1port.sh "$port1_att" 20
        prev1=$port1_att
    fi

    if [ "$port2_att" -ne "$prev2" ]; then
        echo "$(date '+%H:%M:%S')  Setting Port 21 attenuation to ${port2_att} dB"
        ./setGain1port.sh "$port2_att" 21
        prev2=$port2_att
    fi

    # Drift-free sleep: wake at the exact scheduled time of the next step
    if [ "$i" -lt "$STEPS" ]; then
        target=$(((i + 1) * DURATION / STEPS))
        sleep_for=$((target - SECONDS))
        [ "$sleep_for" -gt 0 ] && sleep "$sleep_for"
    fi
done

echo "Completed ramp: Port 20 at ${PORT1_END} dB (RSRP ~ -117), Port 21 at ${PORT2_END} dB (RSRP ~ -129) in $((SECONDS / 60)) min"
