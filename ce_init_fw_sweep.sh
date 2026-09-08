#!/bin/bash
# Starts channel_emulator_cli in a tmux session, applies initial gain settings,
# then ramps mimo speed 403->1200 in 50 even steps (36s each, ~30 min total).

SESSION="chanemu"

send() {
    tmux send-keys -t "$SESSION" "$1" C-m
}

# On Ctrl-C/kill, put the emulator back in static mode so the sweep does not keep running
cleanup() {
    echo "Interrupted - restoring static mimo mode"
    send "configure_mimo_mode 20 inf"
    exit 130
}
trap cleanup INT TERM

# --- Clean up any old session/CLI instance ---
tmux kill-session -t "$SESSION" >/dev/null 2>&1 || true
sudo pkill -9 -f '[c]hannel_emulator_cli' >/dev/null 2>&1 || true

# Wait until every old CLI instance is really gone (max ~10s)
for i in $(seq 1 10); do
    pgrep -f '[c]hannel_emulator_cli' >/dev/null || break
    sleep 1
done

# --- Start CLI inside tmux ---
tmux new-session -d -s "$SESSION" "sudo channel_emulator_cli"
sleep 2
if ! tmux has-session -t "$SESSION" >/dev/null 2>&1; then
    echo "ERROR: chanemu tmux session died - channel_emulator_cli exited at startup" >&2
    exit 1
fi

# --- Initial frequency and rx/tx gain settings ---
send "set_freq_rx01 895.27e6"
send "set_freq_tx23 895.27e6"
send "set_freq_rx23 850e6"
send "set_freq_tx01 850e6"
send "set_rx_gain_db 20 2"
send "set_rx_gain_db 20 3"
send "set_tx_gain_db 30 1"
send "set_tx_gain_db 30 0"
send "set_rx_gain_db 20 0"
send "set_rx_gain_db 20 1"
send "set_tx_gain_db 60 2"
send "set_tx_gain_db 60 3"

echo "End of Initialization of CE and ready to do UE sign on"

# --- Ramp 403->1200 in 50 even steps, 36s each (1800s total) ---
for i in $(seq 0 49); do
    sweep_val=$(( 403 + ( (1200 - 403) * i + 24 ) / 49 ))   # +24 for rounding (49/2)
    echo "$(date '+%H:%M:%S') step $((i+1))/50 -> configure_mimo_mode 398 ${sweep_val}"
    send "configure_mimo_mode 398 ${sweep_val}"
    sleep 36
done

echo "FW sweep complete (held at configure_mimo_mode 398 1200)"
