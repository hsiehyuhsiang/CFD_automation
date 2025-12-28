#!/usr/bin/env bash
set -euo pipefail

RUN_DIR="$(cd "$(dirname "$0")" && pwd)"

if ! command -v pvbatch >/dev/null 2>&1; then
    echo "pvbatch not found. Cannot render PNG."
    exit 1
fi

if [ ! -f "$RUN_DIR/snapshot_template_streamline.py" ]; then
    echo "snapshot_template_streamline.py missing!"
    exit 1
fi

for case_dir in "$RUN_DIR"/hotRoom_mesh*; do
    [ -d "$case_dir" ] || continue
    case_name="$(basename "$case_dir")"

    foam="$case_dir/${case_name}.foam"
    if [ ! -f "$foam" ]; then
        echo "Creating foam file: $foam"
        touch "$foam"
    fi

    echo "=== Rendering streamline for $case_name ==="

    cp "$RUN_DIR/snapshot_template_streamline.py" "$case_dir/snapshot.py"
    sed -i "s|__CASE__|${case_name}.foam|" "$case_dir/snapshot.py"

    (
        cd "$case_dir"
        pvbatch snapshot.py > log.pvbatch 2>&1 \
            && echo "OK: $case_name" \
            || echo "FAIL: $case_name (see log.pvbatch)"
    )
done

echo "All streamline rendering completed."
