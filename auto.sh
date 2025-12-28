#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Stable batch runner for hotRoom cases
# - One STL per case (fixed name: buildings.stl)
# - Clean triSurface every time
# - Force safe locationInMesh
# - Clean polyMesh before meshing
# - Fail-fast: skip bad cases
# ============================================================

RUN_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATE_DIR="$RUN_DIR/hotRoom template"
MESH_DIR="$RUN_DIR/meshes"

if [ ! -d "$MESH_DIR" ]; then
    echo "ERROR: meshes folder not found: $MESH_DIR"
    exit 1
fi

shopt -s nullglob
mesh_files=("$MESH_DIR"/*.stl)
if [ ${#mesh_files[@]} -eq 0 ]; then
    echo "No STL files found in $MESH_DIR"
    exit 0
fi

i=1
for mesh in "${mesh_files[@]}"; do
    index_padded=$(printf "%02d" "$i")
    sim_dir="$RUN_DIR/hotRoom_mesh${index_padded}"

    echo
    echo "=================================================="
    echo "Preparing case: $(basename "$sim_dir")"
    echo "STL: $(basename "$mesh")"
    echo "=================================================="

    # ------------------------------------------------
    # (1) Prepare case directory
    # ------------------------------------------------
    if [ -d "$sim_dir" ]; then
        echo "Existing case found → backup to ${sim_dir}.bak"
        rm -rf "${sim_dir}.bak"
        mv "$sim_dir" "${sim_dir}.bak"
    fi

    mkdir -p "$sim_dir"
    cp -a "$TEMPLATE_DIR"/. "$sim_dir"/

    # ------------------------------------------------
    # (2) Prepare triSurface (clean + single STL)
    # ------------------------------------------------
    mkdir -p "$sim_dir/constant/triSurface"
    rm -f "$sim_dir/constant/triSurface/"*.stl \
          "$sim_dir/constant/triSurface/"*.vtk \
          "$sim_dir/constant/triSurface/"*.obj \
          "$sim_dir/constant/triSurface/"problemFaces 2>/dev/null || true

    cp "$mesh" "$sim_dir/constant/triSurface/buildings.stl"

    # ------------------------------------------------
    # (3) Force safe locationInMesh
    # ------------------------------------------------
    if [ -f "$sim_dir/system/snappyHexMeshDict" ]; then
        sed -i 's/locationInMesh.*/locationInMesh (0.1 0.1 9.9);/' \
            "$sim_dir/system/snappyHexMeshDict"
    else
        echo "WARNING: snappyHexMeshDict not found → skipping case"
        i=$((i+1))
        continue
    fi

    pushd "$sim_dir" >/dev/null

    # ------------------------------------------------
    # (4) Clean old mesh
    # ------------------------------------------------
    rm -rf constant/polyMesh processor* postProcessing log.*

    # ------------------------------------------------
    # (5) blockMesh
    # ------------------------------------------------
    echo "Running blockMesh..."
    if ! blockMesh > log.blockMesh 2>&1; then
        echo "blockMesh FAILED → skipping case"
        popd >/dev/null
        i=$((i+1))
        continue
    fi

    # ------------------------------------------------
    # (6) snappyHexMesh
    # ------------------------------------------------
    echo "Running snappyHexMesh..."
    if ! snappyHexMesh -overwrite > log.snappyHexMesh 2>&1; then
        echo "snappyHexMesh FAILED → skipping case"
        popd >/dev/null
        i=$((i+1))
        continue
    fi

    # ------------------------------------------------
    # (7) checkMesh (post-snappy sanity check)
    # ------------------------------------------------
    echo "Running checkMesh..."
    checkMesh > log.checkMesh 2>&1

    if ! grep -q "floor" constant/polyMesh/boundary; then
    echo "WARNING: outer boundary missing → skipping solver"
    popd >/dev/null
    i=$((i+1))
    continue
    fi

    # ------------------------------------------------
    # (8) buoyantPimpleFoam
    # ------------------------------------------------
    echo "Running buoyantPimpleFoam..."
    if ! buoyantPimpleFoam > log.buoyantPimpleFoam 2>&1; then
        echo "Solver FAILED"
    fi

    # ------------------------------------------------
    # (9) Create .foam file
    # ------------------------------------------------
    touch "$(basename "$sim_dir").foam"

    popd >/dev/null
    echo "Case completed: $(basename "$sim_dir")"

    i=$((i+1))
done

echo
echo "==============================================="
echo "Batch finished. Total cases processed: $((i-1))"
echo "==============================================="
