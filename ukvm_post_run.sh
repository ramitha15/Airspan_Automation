#!/usr/bin/env bash
# Post-run analysis on the UK VM for a test's results folder.
#   ./ukvm_post_run.sh <date> <tag>        e.g. ./ukvm_post_run.sh 2026-10-20 4G_ATG_ENB9_RSRP_SWEEP_UDP_BIDI
# - lists the bs / ac / L1 logs stored on the UK VM
# - runs the eNB log analyser (summary, diagnose, errors) on each *_bs.log -> <bs>_analysis.txt
# - counts UE failure keywords in each *_ac.log
# - generates Q2 plots for each *_ac.log -> <ac>_q2_page<N>.png
set -u
UK_VM=kvramesh@10.80.1.77
HERE="$(cd "$(dirname "$0")" && pwd)"
DIR="automation/Latest/Results/$1/$2"

echo "===== FILES on $UK_VM:~/$DIR ====="
ssh -o BatchMode=yes "$UK_VM" "ls -la ~/$DIR" || { echo "Results folder missing on UK VM"; exit 1; }

echo; echo "===== eNB bs.log ANALYSIS ====="
ssh -o BatchMode=yes "$UK_VM" bash -s "$DIR" <<'EOF'
cd ~/LogAnalyser-v3/enb_log_analyzer || exit 1
shopt -s nullglob
for bs in ~/"$1"/*_bs.log; do
  out="${bs%.log}_analysis.txt"
  { for opt in --summary --diagnose --errors; do
      echo "################ $opt"; python3 -m cli "$bs" $opt 2>&1
    done; } > "$out"
  echo "### $(basename "$bs")  (full report: $out)"
  sed -n '/Overview/,/No obvious\|Issues Found/p' "$out" | head -40
  sed -n '/Auto-Diagnosis/,/################ --errors/p' "$out" | head -60
done
EOF

echo; echo "===== UE ac.log FAILURE KEYWORDS ====="
ssh -o BatchMode=yes "$UK_VM" bash -s "$DIR" <<'EOF'
shopt -s nullglob
for ac in ~/"$1"/*_ac.log; do
  echo "### $(basename "$ac")  lines=$(wc -l < "$ac")"
  for k in "RLF" "Radio Problem" "REESTABLISH" "RRC_CONN_REL" "T310" "RACH fail" "Detach" "ATTACH_REJ" "OUT_OF_SYNC" "assert"; do
    printf '  %-16s %s\n' "$k" "$(grep -ci -- "$k" "$ac")"
  done
done
EOF

echo; echo "===== Q2 PLOTS ====="
for ac in $(ssh -o BatchMode=yes "$UK_VM" "ls ~/$DIR/*_ac.log 2>/dev/null"); do
  ssh -o BatchMode=yes "$UK_VM" "cd ~/GCTQLogParser/linux_build/app && QT_QPA_PLATFORM=offscreen MPLBACKEND=Agg PYTHONPATH=. ../buildenv/bin/python - '$ac'" < "$HERE/q2_plot.py"
done
