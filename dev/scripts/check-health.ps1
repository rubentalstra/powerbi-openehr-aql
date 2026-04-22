#!/usr/bin/env pwsh
# Probe EHRbase endpoints the connector relies on.
# Windows-friendly mirror of check-health.sh.
$ErrorActionPreference = 'Stop'

$envFile = Join-Path $PSScriptRoot '..' '.env'
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
$base = "http://localhost:$port/ehrbase"

$pair = "${user}:${pass}"
$b64 = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($pair))
$headers = @{ Authorization = "Basic $b64" }

function Probe([string]$label, [string]$method, [string]$path, [string]$body) {
    $url = "$base$path"
    try {
        $args = @{
            Uri = $url; Method = $method; Headers = $headers
            SkipHttpErrorCheck = $true
        }
        if ($body) {
            $args.ContentType = 'application/json'
            $args.Body = $body
        }
        $res = Invoke-WebRequest @args
        '{0,-32} {1} {2}' -f $label, $res.StatusCode, $url
    } catch {
        Write-Error "FAIL $label $url - $($_.Exception.Message)"
        throw
    }
}

Write-Host "Checking EHRbase at $base"
Probe 'management/health'   'GET'  '/management/health' $null
Probe 'definition/template' 'GET'  '/rest/openehr/v1/definition/template/adl1.4' $null
Probe 'query/aql'           'POST' '/rest/openehr/v1/query/aql' '{"q":"SELECT e/ehr_id/value FROM EHR e LIMIT 1"}'
Write-Host 'All probes OK.'
