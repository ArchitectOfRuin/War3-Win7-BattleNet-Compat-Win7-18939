@echo off
setlocal EnableExtensions
cd /d "%~dp0"

set "OUT=%~dp0REMOVE_REPORT.txt"
set "PS1=%TEMP%\War3Win7CompatRemove_%RANDOM%_%RANDOM%.ps1"

title Warcraft III - Win7 Battle.net compatibility V2 removal

net session >nul 2>&1
if errorlevel 1 (
  echo ERROR: Run Remove_Win7_v2.bat as Administrator.
  pause
  exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$c=Get-Content -LiteralPath '%~f0'; $i=[Array]::IndexOf($c,'#===REMOVE_PS==='); if($i -lt 0){exit 91}; $c[($i+1)..($c.Length-1)] | Set-Content -LiteralPath '%PS1%' -Encoding UTF8"
if errorlevel 1 (
  echo ERROR: Failed to extract removal code.
  pause
  exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS1%"
set "RC=%ERRORLEVEL%"
del /q "%PS1%" >nul 2>&1

echo.
if "%RC%"=="0" (
  echo Removal completed successfully.
  echo Reboot Windows once before testing Warcraft III again.
) else (
  echo Removal finished with errors. See REMOVE_REPORT.txt.
)
echo.
pause
exit /b %RC%

#===REMOVE_PS===
$ErrorActionPreference = 'Stop'
$Out = Join-Path (Split-Path -Parent $env:PS1) 'REMOVE_REPORT.txt'
$Report = New-Object System.Collections.Generic.List[string]

function O([string]$s='') {
    [void]$Report.Add($s)
    Write-Host $s
}
function SaveReport {
    [IO.File]::WriteAllLines($Out, [string[]]$Report.ToArray(), (New-Object Text.ASCIIEncoding))
}

Add-Type @'
using System;
using System.Runtime.InteropServices;

public static class CngRemove
{
    [DllImport("bcrypt.dll", CharSet=CharSet.Unicode)]
    public static extern int BCryptEnumContexts(
        uint dwTable, ref uint pcbBuffer, out IntPtr ppBuffer);

    [DllImport("bcrypt.dll", CharSet=CharSet.Unicode)]
    public static extern int BCryptEnumContextFunctions(
        uint dwTable, string pszContext, uint dwInterface,
        ref uint pcbBuffer, out IntPtr ppBuffer);

    [DllImport("bcrypt.dll", CharSet=CharSet.Unicode)]
    public static extern int BCryptEnumContextFunctionProviders(
        uint dwTable, string pszContext, uint dwInterface,
        string pszFunction, ref uint pcbBuffer, out IntPtr ppBuffer);

    [DllImport("bcrypt.dll", CharSet=CharSet.Unicode)]
    public static extern int BCryptRemoveContextFunctionProvider(
        uint dwTable, string pszContext, uint dwInterface,
        string pszFunction, string pszProvider);

    [DllImport("bcrypt.dll", CharSet=CharSet.Unicode)]
    public static extern int BCryptUnregisterProvider(string pszProvider);

    [DllImport("bcrypt.dll")]
    public static extern void BCryptFreeBuffer(IntPtr pvBuffer);

    public static string[] ReadStringList(IntPtr p)
    {
        if (p == IntPtr.Zero) return new string[0];

        int count = Marshal.ReadInt32(p, 0);
        int offset = IntPtr.Size == 8 ? 8 : 4;
        string[] result = new string[count];

        for (int i = 0; i < count; i++)
        {
            IntPtr sp = Marshal.ReadIntPtr(p, offset + i * IntPtr.Size);
            result[i] = sp == IntPtr.Zero ? "" : Marshal.PtrToStringUni(sp);
        }
        return result;
    }
}
'@

# CNG constants
$CRYPT_LOCAL = 1
$NCRYPT_SCHANNEL_INTERFACE = 5
$STATUS_SUCCESS = 0

# This is the provider name used by the original installer/provider.
$ProviderName = 'War3 Win7 Battle.net Compat v1.0'
$ProviderDll = Join-Path $env:WINDIR 'System32\War3Win7BattleNetCompat.dll'

try {
    if (Test-Path -LiteralPath $Out) {
        Remove-Item -LiteralPath $Out -Force
    }

    O 'Warcraft III Windows 7 Battle.net compatibility V2 - REMOVE'
    O '======================================================================='
    O 'This removal only targets the compatibility provider registration and its installed provider DLL.'
    O 'Microsoft system cryptographic DLLs are not replaced or modified.'
    O ('Provider name=' + $ProviderName)
    O ('Provider DLL=' + $ProviderDll)
    O ''

    $allContextsSize = 0
    $contextsPtr = [IntPtr]::Zero
    $status = [CngRemove]::BCryptEnumContexts(
        $CRYPT_LOCAL, [ref]$allContextsSize, [ref]$contextsPtr)

    O ('BCryptEnumContexts = 0x{0:X8}' -f ([uint32]$status))

    $removed = 0
    $foundMappings = 0

    if ($status -eq $STATUS_SUCCESS -and $contextsPtr -ne [IntPtr]::Zero) {
        try {
            $contexts = [CngRemove]::ReadStringList($contextsPtr)

            foreach ($context in $contexts) {
                if ([string]::IsNullOrWhiteSpace($context)) { continue }

                $funcSize = 0
                $funcPtr = [IntPtr]::Zero
                $fs = [CngRemove]::BCryptEnumContextFunctions(
                    $CRYPT_LOCAL, $context, $NCRYPT_SCHANNEL_INTERFACE,
                    [ref]$funcSize, [ref]$funcPtr)

                if ($fs -ne $STATUS_SUCCESS -or $funcPtr -eq [IntPtr]::Zero) {
                    continue
                }

                try {
                    $functions = [CngRemove]::ReadStringList($funcPtr)

                    foreach ($function in $functions) {
                        if ([string]::IsNullOrWhiteSpace($function)) { continue }

                        $provSize = 0
                        $provPtr = [IntPtr]::Zero
                        $ps = [CngRemove]::BCryptEnumContextFunctionProviders(
                            $CRYPT_LOCAL, $context, $NCRYPT_SCHANNEL_INTERFACE,
                            $function, [ref]$provSize, [ref]$provPtr)

                        if ($ps -ne $STATUS_SUCCESS -or $provPtr -eq [IntPtr]::Zero) {
                            continue
                        }

                        try {
                            $providers = [CngRemove]::ReadStringList($provPtr)

                            foreach ($provider in $providers) {
                                if ($provider -eq $ProviderName) {
                                    $foundMappings++
                                    $rs = [CngRemove]::BCryptRemoveContextFunctionProvider(
                                        $CRYPT_LOCAL, $context, $NCRYPT_SCHANNEL_INTERFACE,
                                        $function, $ProviderName)

                                    O ('Remove mapping: context="{0}", function="{1}" -> 0x{2:X8}' -f
                                        $context, $function, ([uint32]$rs))

                                    if ($rs -eq $STATUS_SUCCESS) {
                                        $removed++
                                    }
                                }
                            }
                        }
                        finally {
                            [CngRemove]::BCryptFreeBuffer($provPtr)
                        }
                    }
                }
                finally {
                    [CngRemove]::BCryptFreeBuffer($funcPtr)
                }
            }
        }
        finally {
            [CngRemove]::BCryptFreeBuffer($contextsPtr)
        }
    }

    O ''
    O ('Mappings found=' + $foundMappings)
    O ('Mappings removed=' + $removed)

    $u = [CngRemove]::BCryptUnregisterProvider($ProviderName)
    O ('BCryptUnregisterProvider = 0x{0:X8}' -f ([uint32]$u))

    if (Test-Path -LiteralPath $ProviderDll) {
        try {
            Remove-Item -LiteralPath $ProviderDll -Force -ErrorAction Stop
            O 'Provider DLL delete = True'
        }
        catch {
            O ('Provider DLL delete = False; ' + $_.Exception.Message)
            O 'If the DLL is still mapped, reboot Windows and run Remove_Win7_v2.bat again.'
            $u = 1
        }
    }
    else {
        O 'Provider DLL delete = Not needed (file not present)'
    }

    O ''
    O 'Windows system DLLs were not modified.'
    O 'Affected system DLLs: schannel.dll, ncrypt.dll, bcrypt.dll, bcryptprimitives.dll'
    O ''

    $stillThere = Test-Path -LiteralPath $ProviderDll
    O ('Provider DLL still present=' + $stillThere)

    if ($stillThere -or $u -ne $STATUS_SUCCESS) {
        O 'RESULT: PARTIAL/FAILED - keep REMOVE_REPORT.txt and do not reinstall yet.'
        SaveReport
        exit 2
    }

    O 'RESULT: PASS - compatibility provider registration removed.'
    O 'Reboot Windows once before testing Warcraft III again.'
    SaveReport
    exit 0
}
catch {
    O ('ERROR: ' + $_.Exception.Message)
    try { SaveReport } catch {}
    exit 1
}
