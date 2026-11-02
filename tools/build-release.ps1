param([string]$Python = 'python', [string]$Node = 'node')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Push-Location $projectRoot
try {
    & $Python tools/make_data.py
    if ($LASTEXITCODE -ne 0) { throw 'Data build failed.' }
    & $Python tools/compile_catalogue.py
    if ($LASTEXITCODE -ne 0) { throw 'Class/spec catalogue build failed.' }
    & $Python tools/compile_enchants.py
    if ($LASTEXITCODE -ne 0) { throw 'Enchant data build failed.' }
    & $Python tools/compile_efficiency.py
    if ($LASTEXITCODE -ne 0) { throw 'Efficiency data build failed.' }
    & $Python tools/compile_professions.py
    if ($LASTEXITCODE -ne 0) { throw 'Profession build failed.' }
    & $Python tools/build_route_converter.py
    if ($LASTEXITCODE -ne 0) { throw 'Route converter build failed.' }
    & $Python tools/build_usage.py
    if ($LASTEXITCODE -ne 0) { throw 'Usage guide build failed.' }
    & $Python tools/inspect_sources.py | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'API evidence build failed.' }
    $results = & $Node tools/test.js
    if ($LASTEXITCODE -ne 0) { throw 'Lua grammar / behavior / source tests failed; no release packaged.' }
    $nativeResults = & $Python tools/test_lua51.py
    if ($LASTEXITCODE -ne 0) { throw 'Native Lua 5.1 tests failed; no release packaged.' }
    @($results) + @($nativeResults) | Set-Content -LiteralPath output/test-results.txt -Encoding utf8
    & $Python tools/build_offline_report.py
    if ($LASTEXITCODE -ne 0) { throw 'Offline release report failed.' }
    & $Python tools/build_prd.py
    if ($LASTEXITCODE -ne 0) { throw 'PDF build failed.' }
    & $Python tools/render_pdf.py | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'PDF rendering failed.' }
    & $Python tools/package.py
    if ($LASTEXITCODE -ne 0) { throw 'Packaging checks failed.' }
    Write-Output 'Build checks passed. Visually review the current rendered PDF before delivery. Run audit_release.py after staging.'
} finally { Pop-Location }
