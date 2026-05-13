#!/usr/bin/env pwsh
# Install Microsoft.PowerQuery.SdkTools and patch MakePQX.exe.config for the
# System.Threading.Tasks.Extensions binding redirect that SdkTools 2.153.3 needs
# on current GitHub-hosted Windows runners.
[CmdletBinding()]
param(
    [string]$Version = $(if ($env:POWERQUERY_SDKTOOLS_VERSION) { $env:POWERQUERY_SDKTOOLS_VERSION } else { '2.153.3' }),
    [string]$InstallRoot = $(if ($env:RUNNER_TEMP) { $env:RUNNER_TEMP } else { [IO.Path]::GetTempPath() })
)

$ErrorActionPreference = 'Stop'

New-Item -ItemType Directory -Force -Path $InstallRoot | Out-Null

$packageZip = Join-Path $InstallRoot "Microsoft.PowerQuery.SdkTools.$Version.zip"
$packageDir = Join-Path $InstallRoot "Microsoft.PowerQuery.SdkTools.$Version"

Invoke-WebRequest "https://www.nuget.org/api/v2/package/Microsoft.PowerQuery.SdkTools/$Version" -OutFile $packageZip
if (Test-Path $packageDir) {
    Remove-Item -Recurse -Force $packageDir
}
Expand-Archive -Path $packageZip -DestinationPath $packageDir -Force

$tools = Join-Path $packageDir 'tools'
$makePQX = Join-Path $tools 'MakePQX.exe'
if (-not (Test-Path $makePQX)) {
    throw "MakePQX.exe not found at $makePQX"
}

$makePQXConfig = Join-Path $tools 'MakePQX.exe.config'
if (-not (Test-Path $makePQXConfig)) {
    throw "MakePQX.exe.config not found at $makePQXConfig"
}

[xml]$config = Get-Content $makePQXConfig
$nsUri = 'urn:schemas-microsoft-com:asm.v1'
$nsMgr = New-Object System.Xml.XmlNamespaceManager($config.NameTable)
$nsMgr.AddNamespace('asm', $nsUri)
$existingRedirect = $config.SelectSingleNode("//asm:assemblyIdentity[@name='System.Threading.Tasks.Extensions']", $nsMgr)

if (-not $existingRedirect) {
    $assemblyBinding = $config.CreateElement('assemblyBinding', $nsUri)
    $dependentAssembly = $config.CreateElement('dependentAssembly', $nsUri)
    $assemblyIdentity = $config.CreateElement('assemblyIdentity', $nsUri)
    $assemblyIdentity.SetAttribute('name', 'System.Threading.Tasks.Extensions')
    $assemblyIdentity.SetAttribute('publicKeyToken', 'cc7b13ffcd2ddd51')
    $assemblyIdentity.SetAttribute('culture', 'neutral')
    $bindingRedirect = $config.CreateElement('bindingRedirect', $nsUri)
    $bindingRedirect.SetAttribute('oldVersion', '0.0.0.0-4.2.1.0')
    $bindingRedirect.SetAttribute('newVersion', '4.2.1.0')
    $dependentAssembly.AppendChild($assemblyIdentity) | Out-Null
    $dependentAssembly.AppendChild($bindingRedirect) | Out-Null
    $assemblyBinding.AppendChild($dependentAssembly) | Out-Null
    $config.configuration.runtime.AppendChild($assemblyBinding) | Out-Null
    $config.Save($makePQXConfig)
}

if ($env:GITHUB_PATH) {
    $tools | Out-File -FilePath $env:GITHUB_PATH -Append
}

Write-Output "MakePQX available at $makePQX"
