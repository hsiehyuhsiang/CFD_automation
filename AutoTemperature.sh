#!/bin/bash

BASE=$(pwd)
OUTFILE="temperature_summary.csv"

echo "Case,T_min,T_max,DeltaT" > "$OUTFILE"

for case in hotRoom_mesh*/; do
    [ -d "$case" ] || continue
    echo "Processing $case ..."
    cd "$case"

    # 找最新時間
    LAST=$(ls -1d [0-9]* | sort -n | tail -1)
    TFILE="$LAST/T"

    if [ ! -f "$TFILE" ]; then
        echo "  WARNING: No T file found"
        echo "${case%/},NA,NA,NA" >> "$BASE/$OUTFILE"
        cd "$BASE"
        continue
    fi

    # 只抓 internalField 數值，並排除非物理溫度
    VALUES=$(awk '
  /internalField/ {seenInternal=1}
  seenInternal && /\(/ {inList=1; next}   # 遇到 "(" 那行直接跳過（避免抓到 49039）
  inList && /^\)/ {exit}                 # 到 ")" 結束
  inList {
    for (i=1;i<=NF;i++)
      if ($i ~ /^-?[0-9]+(\.[0-9]+)?([eE][-+]?[0-9]+)?$/) print $i
  }
' "$TFILE" | awk '$1 > 100')

    T_MIN=$(echo "$VALUES" | sort -n | head -1)
    T_MAX=$(echo "$VALUES" | sort -n | tail -1)
    DELTA=$(echo "$T_MAX - $T_MIN" | bc -l)

    echo "${case%/},$T_MIN,$T_MAX,$DELTA" >> "$BASE/$OUTFILE"
    cd "$BASE"
done

echo "------------------------------------------"
echo "Done! Output saved to: $OUTFILE"
