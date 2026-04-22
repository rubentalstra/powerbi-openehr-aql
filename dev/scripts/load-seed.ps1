#!/usr/bin/env pwsh
# Upload OPTs then compositions into a fresh EHRbase. Windows/CI variant.
# Mirrors load-seed.sh.
$ErrorActionPreference = 'Stop'

$DevDir = Resolve-Path (Join-Path $PSScriptRoot '..')
$SeedDir = Join-Path $DevDir 'seed-data'

$envFile = Join-Path $DevDir '.env'
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^\s*([^#=]+)\s*=\s*(.*)$') {
            [Environment]::SetEnvironmentVariable($Matches[1].Trim(), $Matches[2].Trim(), 'Process')
        }
    }
}

$port = $env:EHRBASE_PORT; if (-not $port) { $port = '8080' }
$user = $env:EHRBASE_USER; if (-not $user) { $user = 'ehrbase' }
$pass = $env:EHRBASE_PASSWORD; if (-not $pass) { $pass = 'ehrbase' }
$base = "http://localhost:$port/ehrbase/rest/openehr/v1"

$pair = "${user}:${pass}"
$b64 = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($pair))
$auth = @{ Authorization = "Basic $b64" }

Write-Host "Loading templates from $(Join-Path $SeedDir 'templates')"
$templateCount = 0
Get-ChildItem -Path (Join-Path $SeedDir 'templates') -Filter '*.opt' -File | ForEach-Object {
    Write-Host "  uploading $($_.Name)"
    $bytes = [IO.File]::ReadAllBytes($_.FullName)
    $res = Invoke-WebRequest -Uri "$base/definition/template/adl1.4" -Method Post `
        -Headers ($auth + @{ Accept = 'application/json' }) `
        -ContentType 'application/xml' -Body $bytes -SkipHttpErrorCheck
    if ($res.StatusCode -in 201, 204, 409) {
        $templateCount++
    } else {
        throw "template upload failed: HTTP $($res.StatusCode) - $($res.Content)"
    }
}
Write-Host "Templates processed: $templateCount"

function New-EHR([string]$subjectId, [string]$subjectNs) {
    $payload = @{
        '_type' = 'EHR_STATUS'
        name = @{ value = 'EHR Status' }
        archetype_node_id = 'openEHR-EHR-EHR_STATUS.generic.v1'
        subject = @{
            external_ref = @{
                id = @{ '_type' = 'GENERIC_ID'; value = $subjectId; scheme = 'id_scheme' }
                namespace = $subjectNs
                type = 'PERSON'
            }
        }
        is_queryable = $true
        is_modifiable = $true
    } | ConvertTo-Json -Depth 10
    $res = Invoke-RestMethod -Uri "$base/ehr" -Method Post `
        -Headers ($auth + @{ Accept = 'application/json'; Prefer = 'return=representation' }) `
        -ContentType 'application/json' -Body $payload
    return $res.ehr_id.value
}

Write-Host "Loading compositions from $(Join-Path $SeedDir 'compositions')"
$ehrBySubject = @{}
$compositionCount = 0
Get-ChildItem -Path (Join-Path $SeedDir 'compositions') -Filter '*.json' -File | ForEach-Object {
    $raw = Get-Content $_.FullName -Raw
    $obj = $raw | ConvertFrom-Json -Depth 100
    $subjectId = if ($obj.meta.subject_id) { $obj.meta.subject_id } else { 'seed-subject-000' }
    $subjectNs = if ($obj.meta.subject_namespace) { $obj.meta.subject_namespace } else { 'local-dev' }
    if (-not $ehrBySubject.ContainsKey($subjectId)) {
        $ehrBySubject[$subjectId] = New-EHR -subjectId $subjectId -subjectNs $subjectNs
        Write-Host "  EHR $($ehrBySubject[$subjectId]) for subject $subjectId"
    }
    $ehrId = $ehrBySubject[$subjectId]

    $obj.PSObject.Properties.Remove('meta') | Out-Null
    $body = $obj | ConvertTo-Json -Depth 100

    $res = Invoke-WebRequest -Uri "$base/ehr/$ehrId/composition" -Method Post `
        -Headers ($auth + @{ Accept = 'application/json'; Prefer = 'return=minimal' }) `
        -ContentType 'application/json' -Body $body -SkipHttpErrorCheck
    if ($res.StatusCode -in 201, 204) {
        $compositionCount++
    } else {
        throw "composition $($_.Name) failed: HTTP $($res.StatusCode) - $($res.Content)"
    }
}

Write-Host "Compositions uploaded: $compositionCount"
Write-Host "Distinct EHRs created: $($ehrBySubject.Count)"
