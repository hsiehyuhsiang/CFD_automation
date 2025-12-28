# CFD_automation

School project for automating CFD workflows:  
mesh generation → simulation → post-processing

## Overview

This project aims to automate a basic Computational Fluid Dynamics (CFD) workflow,
including mesh generation, solver execution, and post-processing.

The goal is to reduce manual intervention and improve reproducibility for CFD simulations
in a school project setting.

## Requirements

- Windows OS
- Rhino + Grasshopper (for mesh generation)
- BlueCFD (OpenFOAM environment)
- Bash shell (via BlueCFD)
- OpenFOAM utilities:
  - blockMesh
  - snappyHexMesh
  - checkMesh
  - buoyantPimpleFoam
- Python 3 (for post-processing scripts)

## Workflow

The automated workflow follows these steps:

1. Mesh generation  
2. CFD simulation  
3. Post-processing and result extraction

## Project Structure

```text
CFD_automation/
├── meshes/                     # STL files generated from Grasshopper
├── hotRoom template/           # OpenFOAM case template
├── auto.sh                     # Batch CFD automation script
├── render_streamlines.sh       # Streamline rendering script
├── auto_temperature.sh         # Temperature post-processing script
├── snapshot_template_streamline.py
├── README.md
└── LICENSE
```
## Quick Start

1. Generate STL files using Grasshopper  
   - Export STL files to the `meshes/` directory

2. Open BlueCFD Shell and navigate to the project directory
  -download at [BlueCFD](https://bluecfd.github.io/Core/Downloads/#bluecfd-core-2024-1)
3. Make scripts executable (first time only)
```bash
chmod +x auto.sh render_streamlines.sh auto_temperature.sh
```
4. Run CFD batch simulation
```bash
./auto.sh
```
5.Render streamlines
```bash
./render_streamlines.sh
```
6.Run temperature post-processing
```bash
./auto_temperature.sh
```

## Pipeline Details

1. **Mesh Generation (Grasshopper)**
   - Grasshopper components generate geometry
   - Python scripts export STL files
   - Geometry volume information is logged for reference

2. **CFD Simulation (BlueCFD)**
   - `auto.sh` reads STL files from `meshes/`
   - A new case folder is created from `hotRoom template`
   - `buoyantPimpleFoam` is executed automatically

3. **Streamline Rendering**
   - `render_streamlines.sh` runs Python-based streamline rendering

4. **Temperature Post-processing**
   - `auto_temperature.sh` extracts and processes temperature data
