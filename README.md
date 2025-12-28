# CFD_automation

School project for automating CFD workflows:  
mesh generation → simulation → post-processing

## Overview

This project aims to automate a basic Computational Fluid Dynamics (CFD) workflow,
including mesh generation, solver execution, and post-processing.

The goal is to reduce manual intervention and improve reproducibility for CFD simulations
in a school project setting.

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
