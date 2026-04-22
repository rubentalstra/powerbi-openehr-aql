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

$port       = $env:EHRBASE_PORT;           if (-not $port)       { $port       = '8080' }
$user       = $env:EHRBASE_USER;           if (-not $user)       { $user       = 'ehrbase' }
$pass       = $env:EHRBASE_PASSWORD;       if (-not $pass)       { $pass       = 'ehrbase' }
$adminUser  = $env:EHRBASE_ADMIN_USER;     if (-not $adminUser)  { $adminUser  = 'ehrbase_admin' }
$adminPass  = $env:EHRBASE_ADMIN_PASSWORD; if (-not $adminPass)  { $adminPass  = 'ehrbase_admin' }
$base = "http://localhost:$port/ehrbase"

function Get-BasicHeader([string]$u, [string]$p) {
    $b64 = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${u}:${p}"))
    return @{ Authorization = "Basic $b64" }
}

$headers      = Get-BasicHeader $user $pass
$adminHeaders = Get-BasicHeader $adminUser $adminPass

function Probe([string]$label, [string]$method, [string]$path, [string]$body, $hdrs) {
    if (-not $hdrs) { $hdrs = $headers }
    $url = "$base$path"
    try {
        $requestArgs = @{
            Uri = $url; Method = $method; Headers = $hdrs
            SkipHttpErrorCheck = $true
        }
        if ($body) {
            $requestArgs.ContentType = 'application/json'
            $requestArgs.Body = $body
        }
        $res = Invoke-WebRequest @requestArgs
        '{0,-32} {1} {2}' -f $label, $res.StatusCode, $url
    } catch {
        Write-Error "FAIL $label $url - $($_.Exception.Message)"
        throw
    }
}

Write-Output "Checking EHRbase at $base"
# /management/* is admin-only in EHRbase 2.x — use admin credentials for it.
Probe 'management/health'   'GET'  '/management/health' $null $adminHeaders
Probe 'definition/template' 'GET'  '/rest/openehr/v1/definition/template/adl1.4' $null
Probe 'query/aql'           'POST' '/rest/openehr/v1/query/aql' '{"q":"SELECT e/ehr_id/value FROM EHR e LIMIT 1"}'
Write-Output 'All probes OK.'
