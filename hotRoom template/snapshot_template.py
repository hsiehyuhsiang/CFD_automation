from paraview.simple import *


case = OpenFOAMReader(FileName="__CASE__")
case.MeshRegions = ['internalMesh']
case.CellArrays = ['U']

renderView = GetActiveViewOrCreate('RenderView')
caseDisplay = Show(case, renderView)

ColorBy(caseDisplay, ('CELLS', 'U', 'Magnitude'))
caseDisplay.RescaleTransferFunctionToDataRange(True, False)

Render()


streamTracer = StreamTracer(
    Input=case,
    SeedType='LineSource',
    Vectors=['CELLS', 'U'],
    MaximumStreamlineLength=10.0
)

streamTracer.SeedType.Point1 = [0, 0, 0]
streamTracer.SeedType.Point2 = [0, 5, 2]
streamTracer.SeedType.Resolution = 40  # ????

streamDisplay = Show(streamTracer, renderView)

ColorBy(streamDisplay, ('POINTS', 'U', 'Magnitude'))
streamDisplay.RescaleTransferFunctionToDataRange(True, False)


renderView.ResetCamera()


SaveScreenshot("U_streamline.png", renderView, ImageResolution=[2000, 1200])
