$ErrorActionPreference = 'Stop';

$meta = Get-Content -Path "$($env:ChocolateyPackageFolder)\tools\packageArgs.csv" -Raw
$packageArgs = @{}
(ConvertFrom-Csv $meta -Delimiter ';').psobject.properties | ForEach-Object { $packageArgs[$_.Name] = $_.Value }

$filename = if ((Get-OSArchitectureWidth 64) -and $env:chocolateyForceX86 -ne $true) {
       Split-Path $packageArgs["url64bit"] -Leaf }
else { Split-Path $packageArgs["url"] -Leaf }

$packageArgs["packageName"] = "$($env:ChocolateyPackageName)"
$packageArgs["fileFullPath"] = "$(Join-Path (Split-Path -parent $MyInvocation.MyCommand.Definition) $filename)"

$archiveLocation = Get-ChocolateyWebFile @packageArgs
$extractLocation = "$(Join-Path (Split-Path -parent $archiveLocation) "Codecs")"

$spliter = "path to executable:"
$7zLocation = "$(Split-Path -parent ((7z --shimgen-noop | Select-String $spliter) -split $spliter | ForEach-Object Trim)[1])"
$installLocation = "$(Join-Path $7zLocation "Codecs")"

Write-Output "Install libraries"

New-Item -ItemType directory -Path $installLocation -Force | Out-Null
Get-ChocolateyUnzip -FileFullPath $archiveLocation -Destination $extractLocation | Out-Null
if ((Get-OSArchitectureWidth 64) -and $env:chocolateyForceX86 -ne $true) {
       $extractLocationArch = Join-Path $extractLocation '*.64.dll'
} else {
       $extractLocationArch = Join-Path $extractLocation '*.32.dll'
}

Get-ChildItem -Recurse $extractLocationArch | Select-Object Name | ConvertTo-Csv -Delimiter ';' | Out-File "$($env:ChocolateyPackageFolder)\tools\installed.csv"
Copy-Item "$($extractLocationArch)" "$($installLocation)" -Recurse -Force
Copy-Item "$(Join-Path $extractLocation '*.ini')" "$($installLocation)" -Recurse -Force

Write-Output "Install completed"