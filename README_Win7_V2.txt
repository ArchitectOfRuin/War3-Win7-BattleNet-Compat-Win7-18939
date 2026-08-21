War3 Win7 Battle.net compatibility - Win7 v2 backport candidate

Target system:
Windows 7 x64
schannel.dll SHA256: 227000ed75a96e127855925ee8c1439eaf15e450ecd0533a3dace38c01acadbc
ncrypt.dll SHA256: c80e8599a2427846112f7dae4902a1242062cd20b05c9989b0f5467fd9bb411c
bcrypt.dll SHA256: ddb4cb575139233efaf2c59b7e9b04af36bbccc63190181f3b2a7e6bfc86e77e
bcryptprimitives.dll SHA256: 3b5ed1a030bfd0bb73d4ffcd67a6a0b8501ef70293f223efaa12f430adf270f9

Provider DLL SHA256: 4b0ad5a8b9295b976a443c4969b6ad69915081e2865d86535d3889af9c032b8e

What changed:
The original author's exported GetSChannelInterface entry point promoted the
wrapped v2 table to interface v3 and then required the two newer native
callbacks SslComputeSessionHash and SslGeneratePreMasterKey. The supplied
ncrypt.dll does not export those callbacks.

This candidate instead tail-jumps to the provider's existing v2 initializer.
That keeps the author's existing 26-slot compatibility table and its C02F->C02B
wrappers, but does not require the missing v3 callbacks.

Microsoft system DLLs are not modified by INSTALL_Win7_V2.bat. The compatibility
provider itself is installed as the registered provider image, as in the
original package.

How to test:
1. Keep War3Win7BattleNetCompat.dll, INSTALL_Win7_V2.bat and the author's
   War3Win7BattleNetCompatInstall.exe in the same folder.
2. Close Battle.net and Warcraft III.
3. Run INSTALL_Win7_V2.bat as Administrator.
4. Confirm INSTALL_REPORT.txt ends with PRECHECK/HASH VERIFY PASS.
5. Reboot once.
6. Test Battle.net / Warcraft III.

If the installer refuses to overwrite an existing provider image, remove the
current provider with the author's REMOVE.bat, reboot once, and then run this
installer.

This is a targeted backport candidate based on the supplied binaries. It has
been statically verified, but it has not been runtime-tested on the user's
Windows 7 machine in this environment.
