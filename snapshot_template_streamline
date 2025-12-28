from paraview.simple import *
import os
import re

# ============================================================
# Output directory (writable path)
# ============================================================
run_dir = os.path.abspath(os.path.join(os.getcwd(), ".."))
OUT_DIR = os.path.join(run_dir, "snapshots")
if not os.path.exists(OUT_DIR):
    os.makedirs(OUT_DIR)
print("OUT_DIR =", OUT_DIR)


# ============================================================
# Load FOAM
# ============================================================
foam_file = os.path.join(os.getcwd(), "__CASE__")
print("Loading FOAM:", foam_file)

base = os.path.splitext(os.path.basename(foam_file))[0]
m = re.search(r"hotRoom_mesh(\d+)$", base)
if m:
    idx = m.group(1).zfill(2)
else:
    idx = "00"

print("Case base:", base, " -> stream index:", idx)

case = OpenFOAMReader(FileName=foam_file)
case.MeshRegions = ['internalMesh']
case.UpdatePipeline()

available = case.CellArrays
valid = [f for f in ['U', 'T', 'p'] if f in available]
case.CellArrays = valid
print("Using fields:", valid)

# ============================================================
# Last timestep
# ============================================================
anim = GetAnimationScene()
anim.UpdateAnimationUsingDataTimeSteps()
anim.GoToLast()

view = GetActiveViewOrCreate('RenderView')
view.Update()

# ============================================================
# Background color (rgb 219)
# ============================================================
g = 0 / 255.0
view.UseGradientBackground = 0
view.Background = [g, g, g]

# ============================================================
# Cell -> Point data
# ============================================================
c2p = CellDatatoPointData(Input=case)
c2p.UpdatePipeline()

# ============================================================
# Surface shell (30% opacity)
# ============================================================
surf = ExtractSurface(Input=c2p)
surf.UpdatePipeline()

surfRep = Show(surf, view)
surfRep.Representation = 'Surface'
surfRep.Opacity = 0.30
ColorBy(surfRep, None)
surfRep.DiffuseColor = [0.6, 0.6, 0.6]
surfRep.AmbientColor = [0.6, 0.6, 0.6]

# ============================================================
# Seeds
# ============================================================
seed = PointSource()
seed.Center = [5.0, 2.5, 5.0]
seed.Radius = 7.5
seed.NumberOfPoints = 4000
seed.UpdatePipeline()

# ============================================================
# Stream tracer
# ============================================================
stream = StreamTracerWithCustomSource()
stream.Input = c2p
stream.SeedSource = seed
stream.Vectors = ['POINTS', 'U']
stream.IntegrationDirection = 'FORWARD'
stream.MaximumStreamlineLength = 40.0
stream.UpdatePipeline()

# ============================================================
# Stream display
# ============================================================
streamRep = Show(stream, view)
ColorBy(streamRep, ('POINTS', 'U', 'Magnitude'))
streamRep.RescaleTransferFunctionToDataRange(True, False)

# ============================================================
# Save screenshots
# ============================================================
def save_view(view_name, cam_pos, cam_fp, cam_up):
    view.CameraPosition = cam_pos
    view.CameraFocalPoint = cam_fp
    view.CameraViewUp = cam_up
    view.CameraParallelScale = 12.0
    view.Update()

    fn = os.path.join(
        OUT_DIR,
        "stream{0}_{1}.png".format(idx, view_name)
    )
    print("Saving:", fn)
    SaveScreenshot(fn, view, ImageResolution=[1920, 1080])

center = [5.0, 2.5, 5.0]

save_view("front", [5.0, -35.0, 5.0], center, [0.0, 0.0, 1.0])
save_view("side",  [35.0, 2.5, 5.0],  center, [0.0, 0.0, 1.0])
save_view("top",   [5.0, 2.5, 35.0],  center, [0.0, 1.0, 0.0])

print("Done.")
