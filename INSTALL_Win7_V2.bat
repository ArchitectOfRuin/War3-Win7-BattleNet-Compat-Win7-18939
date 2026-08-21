@echo off
setlocal EnableExtensions
set "SELF=%~f0"
set "OUT=%~dp0INSTALL_REPORT.txt"
set "PS1=%TEMP%\War3Win7CompatInstall_%RANDOM%_%RANDOM%.ps1"
title Warcraft III - Windows 7 Battle.net compatibility v1.0
cd /d "%~dp0"

net session >nul 2>&1
if errorlevel 1 (
  echo ERROR: Run INSTALL.bat as Administrator.
  pause
  exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$c=Get-Content -LiteralPath $env:SELF; $i=[Array]::IndexOf($c,'#===PRECHECK_PS==='); if($i -lt 0){exit 91}; $c[($i+1)..($c.Length-1)] | Set-Content -LiteralPath $env:PS1 -Encoding UTF8"
if errorlevel 1 (echo ERROR extracting precheck.& pause& exit /b 1)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS1%"
set "PRE=%ERRORLEVEL%"
del /q "%PS1%" >nul 2>&1
if not "%PRE%"=="0" (
  echo.
  echo PRECHECK FAILED. Nothing was installed. See INSTALL_REPORT.txt.
  pause
  exit /b %PRE%
)

echo.
echo Installing the Windows 7 Schannel compatibility provider...
"War3Win7BattleNetCompatInstall.exe" >> "%OUT%" 2>&1
set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" (
  echo INSTALLER RETURNED %RC%. Do not launch Warcraft III.
  echo INSTALLER RETURNED %RC%. >> "%OUT%"
  pause
  exit /b %RC%
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$p='%SystemRoot%\System32\War3Win7BattleNetCompat.dll'; $expected='4b0ad5a8b9295b976a443c4969b6ad69915081e2865d86535d3889af9c032b8e'; $bytes=[IO.File]::ReadAllBytes($p); $sha=New-Object System.Security.Cryptography.SHA256Managed; $h=([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-','').ToLowerInvariant(); $sha.Clear(); Add-Content -LiteralPath '%OUT%' -Value ('System32 DLL SHA256='+$h); if($h-ne$expected){exit 7}"
set "POST=%ERRORLEVEL%"
if not "%POST%"=="0" (
  echo POST-INSTALL HASH VERIFY FAILED. Run REMOVE.bat before further testing.
  pause
  exit /b %POST%
)

echo INSTALL/PRECHECK/HASH VERIFY PASS >> "%OUT%"
echo.
echo Installation verified.
echo REBOOT WINDOWS ONCE before launching Battle.net.
echo After reboot, launch Warcraft III only from the official Battle.net launcher.
echo.
pause
exit /b 0

#===PRECHECK_PS===
$ErrorActionPreference='Stop'
$Out=$env:OUT
$L=New-Object Collections.Generic.List[string]
function O([string]$s=''){[void]$L.Add($s);Write-Host $s}
function S{[IO.File]::WriteAllLines($Out,[string[]]$L.ToArray(),(New-Object Text.ASCIIEncoding))}
function HashFile([string]$p){
  $bytes = [IO.File]::ReadAllBytes($p)
  $sha = New-Object System.Security.Cryptography.SHA256Managed
  $hash = $sha.ComputeHash($bytes)
  $sha.Clear()   # вместо Dispose
  return ([BitConverter]::ToString($hash)).Replace('-','').ToLowerInvariant()
}
try{
 if(Test-Path -LiteralPath $Out){Remove-Item -LiteralPath $Out -Force}
 O 'Warcraft III Windows 7 Battle.net compatibility v1.0 - PRECHECK'
 O '======================================================================='
 O 'No network/authentication data is accessed by this precheck.'
 $ok=$true
 $v=[Environment]::OSVersion.Version
 $os=($v.Major-eq6-and$v.Minor-eq1)
 O ('Windows version='+$v.ToString()+'; Windows 7 family='+$os)
 if(-not$os){$ok=$false}
 $os64=Test-Path -LiteralPath (Join-Path $env:WINDIR 'SysWOW64') -PathType Container
 $proc64=([IntPtr]::Size-eq8)
 O ('64-bit operating system='+$os64)
 O ('64-bit PowerShell process='+$proc64)
 if(-not$os64-or-not$proc64){$ok=$false}
 $checks=@(
   @((Join-Path $env:WINDIR 'System32\schannel.dll'),'227000ed75a96e127855925ee8c1439eaf15e450ecd0533a3dace38c01acadbc','schannel.dll'),
   @((Join-Path $env:WINDIR 'System32\ncrypt.dll'),'c80e8599a2427846112f7dae4902a1242062cd20b05c9989b0f5467fd9bb411c','ncrypt.dll'),
   @((Join-Path $env:WINDIR 'System32\bcrypt.dll'),'ddb4cb575139233efaf2c59b7e9b04af36bbccc63190181f3b2a7e6bfc86e77e','bcrypt.dll'),
   @((Join-Path $env:WINDIR 'System32\bcryptprimitives.dll'),'3b5ed1a030bfd0bb73d4ffcd67a6a0b8501ef70293f223efaa12f430adf270f9','bcryptprimitives.dll'),
   @((Join-Path (Split-Path -Parent $env:SELF) 'War3Win7BattleNetCompat.dll'),'4b0ad5a8b9295b976a443c4969b6ad69915081e2865d86535d3889af9c032b8e','package DLL')
 )
 foreach($c in $checks){
   $exists=Test-Path -LiteralPath $c[0] -PathType Leaf
   if($exists){$h=HashFile $c[0]}else{$h='<missing>'}
   $match=($exists-and$h-eq$c[1])
   O ($c[2]+' SHA256='+$h+'; expected='+$match)
   if(-not$match){$ok=$false}
 }
 O ''
 O ('PRECHECK PASS='+$ok)
 if(-not$ok){
   O 'This build targets the supplied Windows 7 x64 crypto DLL set and keeps the provider on the v2 interface.'
   O 'Do not bypass the precheck on a different binary set.'
 }
 S
 if($ok){exit 0}else{exit 2}
}catch{O ('ERROR: '+$_.Exception.Message);try{S}catch{};exit 1}