#!/bin/bash
# Stops a running FW sweep: restores static mimo mode, then kills the CLI and tmux session.

SESSION="chanemu"

# If the CLI is still up, put the emulator back in static mode first
if tmux has-session -t "$SESSION" >/dev/null 2>&1; then
    tmux send-keys -t "$SESSION" "configure_mimo_mode 20 inf" C-m
    sleep 2
fi

tmux kill-session -t "$SESSION" >/dev/null 2>&1 || true
# CLI runs as root (sudo), so tmux kill-session alone does not stop it
sudo pkill -9 -f '[c]hannel_emulator_cli' >/dev/null 2>&1 || true

for i in $(seq 1 10); do
    pgrep -f '[c]hannel_emulator_cli' >/dev/null || { echo "Sweep stopped, CLI killed."; exit 0; }
    sleep 1
done

echo "ERROR: channel_emulator_cli still running" >&2
exit 1
