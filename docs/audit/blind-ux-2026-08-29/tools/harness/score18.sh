#!/bin/zsh
cd /private/tmp/claude-501/-Users-fischbeck3-cup-season/8472110b-9333-460b-8c1c-e243ac7cb2f3/scratchpad/harness
P=(0 1 0 0 1 0 1 0 -1 1 0 1 0 0 1 1 0 0)
C=(1 2 1 0 2 1 1 2 0 1 2 1 1 0 2 1 1 2)
M=(1 1 0 2 1 0 1 1 1 2 0 1 1 1 0 2 1 1)
J=(2 1 2 1 3 1 2 1 2 2 2 1 3 1 2 2 1 2)
tap(){ node bx.mjs comp click "role=button name=$1" >/dev/null 2>&1; }
score(){ # name delta firsttap(1/0)
  local n=$1 d=$2 first=$3
  [[ $first == 1 ]] && tap "Plus $n"
  if (( d > 0 )); then for ((k=0;k<d;k++)); do tap "Plus $n"; done
  elif (( d < 0 )); then for ((k=0;k<-d;k++)); do tap "Minus $n"; done; fi
}
for ((h=1;h<=18;h++)); do
  i=$h
  if (( h == 1 )); then score Priya ${P[$i]} 0; else score Priya ${P[$i]} 1; fi
  score Casey ${C[$i]} 1; score Marcus ${M[$i]} 1; score Jordan ${J[$i]} 1
  if (( h == 1 || h == 9 || h == 18 )); then echo "=== after hole $h ==="; date -u; node bx.mjs comp text | grep -E "THRU|WORTH|SKIN|PRIYA|CASEY|MARCUS|JORDAN|SQUARE|owes|\\$" | head -24; node bx.mjs comp shotfull live-hole$h; fi
  (( h < 18 )) && tap "Next hole"
done
