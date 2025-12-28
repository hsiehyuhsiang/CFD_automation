# run_hourly_sim.ps1 (UPDATED VERSION)
# Note: Execute in blueCFD's 'MSYS2 MinGW 64-bit' Shell or PowerShell

# --- Simulation Settings ---
$casePath = "C:/PROGRA~1/BLUECF~1/ofuser-of8/run/hotRoom" # <-- ***REPLACE with your actual case path***
$solver = "buoyantPimpleFoam"
$deltaTime = 3600.0
$startRunTime = 0.0

# --- File Paths ---
$Ttable = Join-Path $casePath "constant\T_hourly_table"
$Utable = Join-Path $casePath "constant\U_hourly_table"
$Utemplate = Join-Path $casePath "0\U.template"
$Ttemplate = Join-Path $casePath "0\T.template"
$Ktemplate = Join-Path $casePath "0\k.template"
$Otemplate = Join-Path $casePath "0\omega.template"
$Ufile = Join-Path $casePath "0\U"
$Tfile = Join-Path $casePath "0\T"
$Kfile = Join-Path $casePath "0\k"
$Ofile = Join-Path $casePath "0\omega"

# 1. Read and Parse OpenFOAM Table Data
Write-Host "Reading hourly data tables..."

# Read U table: Format is (t (Ux Uy Uz))
$U_lines = Get-Content $Utable | Select-String -Pattern "^\s*\(" -NotMatch
$U_vectors = $U_lines | ForEach-Object { 
    $_.Line.Trim().TrimStart('(').TrimEnd(')').Split(' ', [System.StringSplitOptions]::RemoveEmptyEntries) | Select-Object -Skip 1 
}

# Read T table
$T_lines = Get-Content $Ttable | Select-String -Pattern "^\s*\(" -NotMatch
$T_values = $T_lines | ForEach-Object { 
    $_.Line.Trim().TrimStart('(').TrimEnd(')').Split(' ', [System.StringSplitOptions]::RemoveEmptyEntries) | Select-Object -Skip 1 
}
if ($U_vectors.Count -ne $T_values.Count) {
    Write-Error "Error: U and T hourly data count mismatch!"
    exit 1
}

# 2. Copy templates to initial time step
Copy-Item $Utemplate $Ufile -Force
Copy-Item $Ttemplate $Tfile -Force
Copy-Item $Ktemplate $Kfile -Force
Copy-Item $Otemplate $Ofile -Force

# 3. Loop and Run Simulation (Hour by Hour)
for ($i = 0; $i -lt $U_vectors.Count; $i++) {
    $currentTime = $startRunTime + $i * $deltaTime
    $nextTime = $currentTime + $deltaTime

    if ($i -eq $U_vectors.Count - 1) {
        Write-Host "Reached end of data. Stopping loop."
        break
    }

    # --- Get BC values for the current hour and calculate U Magnitude ---
    $ux = [double]$U_vectors[$i][0]
    $uy = [double]$U_vectors[$i][1]
    $uz = [double]$U_vectors[$i][2]
    $t_k = [double]$T_values[$i][0]

    # Calculate velocity magnitude
    $u_mag = [math]::Sqrt($ux*$ux + $uy*$uy + $uz*$uz)

    $inletVector = "($ux $uy $uz)"

    Write-Host "`n--- Hour $($i + 1): Time $currentTime s to $nextTime s ---"
    Write-Host "Inlet U: $inletVector m/s (Mag: $u_mag) | Inlet T: $t_k K"

    # --- Update 0/U, 0/T files ---
    $U_content = Get-Content $Utemplate -Raw
    $U_new = $U_content -replace "INLET_VALUE", $inletVector
    $U_new | Set-Content $Ufile -Encoding ASCII

    $T_content = Get-Content $Ttemplate -Raw
    $T_new = $T_content -replace "INLET_TEMP", $t_k
    $T_new | Set-Content $Tfile -Encoding ASCII

    # --- Update 0/k, 0/omega files ---
    $K_content = Get-Content $Ktemplate -Raw
    $K_new = $K_content -replace "ABL_U_REF", "$u_mag"
    $K_new | Set-Content $Kfile -Encoding ASCII

    $O_content = Get-Content $Otemplate -Raw
    $O_new = $O_content -replace "ABL_U_REF", "$u_mag"
    $O_new | Set-Content $Ofile -Encoding ASCII

    # --- Set time control in controlDict ---
    (Get-Content (Join-Path $casePath "system\controlDict")) -replace "startTime.*", "startTime    $currentTime;" `
    -replace "endTime.*", "endTime      $nextTime;" `
    | Set-Content (Join-Path $casePath "system\controlDict") -Encoding ASCII

    # --- Run Solver ---
    Write-Host "Running $solver from $currentTime s to $nextTime s..."
    Start-Process -NoNewWindow -Wait -FilePath "cmd.exe" -ArgumentList "/c", "$solver -case `"$casePath`""

    if ($LASTEXITCODE -ne 0) {
        Write-Error "Solver failed at time $currentTime. Stopping simulation."
        exit 1
    }
}

Write-Host "`nSimulation completed successfully for all hourly steps."