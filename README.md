# Warcraft III Windows 7 Battle.net Compatibility Provider

A compatibility provider intended to restore **Warcraft III Battle.net connectivity on Windows 7 SP1 x64** for the specific Windows binary set on which this project was developed and tested.

> [!IMPORTANT]
> This project is **independent** and is not affiliated with, supported by, or endorsed by Blizzard Entertainment, Microsoft, AVG, or OpenAI.
>
> It is intended for Warcraft III launched normally through the **official Battle.net desktop launcher** and connected to Blizzard's official services.

## Download

Use the archive attached to the latest GitHub Release:

**`War3_Win7_BattleNet_Compat_v1.0.zip`**

Do **not** use GitHub's automatically generated "Source code (zip)" archive as the installer package.

### v1.0 ZIP SHA-256

```text
3db1ba9ccc1b0bcf805b0e849d4df77ffd78d966b50d517187a359b4dc0f85c7

What this tool does

During investigation of the current Warcraft III / Battle.net connection path on Windows 7, the failure was traced to the Windows Schannel / ncrypt provider-interface boundary.

On the validated Windows 7 system, the available compatible provider path exposes a version-2 interface containing slots 0 through 25.

The current ncrypt path expects the version-3 extension, including the real native callback:

SslComputeSessionHash

The compatibility provider preserves the existing provider behavior and exposes a relocated version-3 interface:

slots 0 through 25 are preserved;
the real SslComputeSessionHash callback is provided in slot 26;
the real SslGeneratePreMasterKey callback is provided in slot 27;
existing nonzero error statuses are preserved;
resolver failure remains NTE_NOT_SUPPORTED;
no successful security result is fabricated.

This is a compatibility layer around the affected Windows cryptographic-provider interface.

It does not:

redirect Battle.net traffic;
emulate Blizzard authentication;
fabricate Battle.net tokens or credentials;
bypass account authentication;
patch Warcraft III.exe;
replace Microsoft system DLLs;
modify Blizzard game files;
redirect the game to another server;
convert failed cryptographic operations into artificial success.
Tested result

On the Windows 7 x64 machine used to develop and validate this release:

installation completed successfully;
Windows was rebooted;
Battle.net was launched normally;
Warcraft III was launched from the official Battle.net launcher;
Battle.net connectivity worked normally inside Warcraft III;
Multiplayer opened successfully;
an actual game remained stable;
a map download completed successfully.

The runtime DLL distributed in v1.0 is the same clean compatibility DLL that passed the live multiplayer test.

Important: supported Windows configuration

Public v1.0 was validated on Windows 7 SP1 x64 with the following exact system binaries:

schannel.dll
SHA256: 51dcfaa5fe70d231d609fc7c37a3262c30d613721420efd65f8c33578c371501


ncrypt.dll
SHA256: 962f201ee3b08e3fc4a0849251958c573ebcb3b32f588ec624ebc443a2400be9


bcrypt.dll
SHA256: e101aa09220b126962ed5de00d7f15bcd645890f33afa1728fafd78d2e67ae90


bcryptprimitives.dll
SHA256: 715977e616e206724f91660ef5bd0c4f2c6d66e3891f03c28a864419102ce5b6

INSTALL.bat checks these hashes before making any change.

[!WARNING]
If the precheck fails, do not bypass it.

A different Windows 7 build or binary set has not been validated by this release.

Installation
Recommended method
Close Warcraft III.
Close the Battle.net desktop application.
Extract the complete release ZIP to a normal folder.
Right-click INSTALL.bat.
Choose Run as administrator.
Let the precheck complete.

A valid supported machine should report:

PRECHECK PASS=True

The installer then registers the compatibility provider and verifies the installed DLL hash.

After a successful installation:

Keep INSTALL_REPORT.txt.
Reboot Windows once.
Start the official Battle.net desktop launcher normally.
Launch Warcraft III from Battle.net.
Use Battle.net normally inside the game.
Manual installation

The automatic installation is strongly recommended because it performs all compatibility checks.

For advanced users who understand what they are doing:

Close Warcraft III and Battle.net.
Verify the four Windows system hashes listed above.
Verify:
War3Win7BattleNetCompat.dll
SHA256: d2dc7f30344f2f4482196301835fdc45231619fc4df3d74bf49bf809b5fcbc90
Only if every hash matches exactly, run:
War3Win7BattleNetCompatInstall.exe

as Administrator.

Verify that:
%SystemRoot%\System32\War3Win7BattleNetCompat.dll

has SHA-256:

d2dc7f30344f2f4482196301835fdc45231619fc4df3d74bf49bf809b5fcbc90
Reboot Windows once.
Launch Warcraft III through the official Battle.net launcher.

Do not use manual installation to bypass a failed automatic precheck.

Removal
Close Warcraft III.
Close Battle.net.
Right-click REMOVE.bat.
Choose Run as administrator.
Keep REMOVE_REPORT.txt if an error is reported.
Reboot Windows once.

If Windows cannot immediately delete the provider DLL because it is still mapped by a process, reboot and run REMOVE.bat again.

Warcraft III / Battle.net installation path

Warcraft III and Battle.net do not need to be installed on C:.

The compatibility package does not depend on a fixed game path and does not search for or modify Warcraft III or Battle.net files.

For example, the game may be installed on:

D:\Games\
E:\Battle.net\

and the compatibility package may be extracted somewhere else entirely.

Windows system locations are resolved from the running Windows environment rather than from a hard-coded C:\Windows path.

However, the actual development and validation machine used:

C:\Windows

A Windows installation whose system directory itself is located on another drive has not been separately validated.

Windows 8

Windows 8 is not supported or validated by v1.0.

I currently do not know whether:

the exact same problem exists on Windows 8;
Windows 8 expects the same provider-interface layout;
this exact compatibility provider would work there;
or Windows 8 would require a different implementation.

INSTALL.bat therefore deliberately rejects Windows 8.

Please do not remove that protection simply to "try it".

For people who want to investigate Windows 8 or another Windows build

The useful part of this project is not merely the compiled DLL but the mechanism that was identified.

A system-specific investigation should:

identify the Schannel / ncrypt call returning NTE_NOT_SUPPORTED;
determine the SSL provider-interface version expected by that exact Windows build;
map the provider table used by that build;
determine which real native callbacks are missing;
preserve all existing provider entries;
preserve real error statuses;
add only the callbacks actually required by the target system;
validate the resulting provider experimentally;
add fail-closed checks for the exact Windows binaries that were analyzed.

For the Windows 7 system investigated here, the important compatibility boundary was:

provider interface v2
        ↓
current ncrypt path expects v3
        ↓
slots 0..25 preserved
slot 26 = SslComputeSessionHash
slot 27 = SslGeneratePreMasterKey

The hashes and table layout documented by this repository must not be assumed to apply to Windows 8 or every Windows 7 installation.

AVG / antivirus note

During development, AVG interfered with the installation process on the Windows 7 test machine by blocking some of the compatibility files.

Once the verified files were allowed to install, no further AVG-related problem was observed during normal Warcraft III / Battle.net use.

Antivirus behavior may vary between versions and machines.

If AVG or another antivirus blocks or quarantines one of the release files:

do not continue with an incomplete package;
compare the file hashes with SHA256SUMS.txt;
restore or allow only files whose hashes match the official release;
run INSTALL.bat again.

A specific allow-list/exclusion for the verified release files is preferable to broadly weakening antivirus protection.

About this project

This compatibility tool was developed through a long iterative investigation performed with ChatGPT by OpenAI, together with repeated experiments and validation on the affected Windows 7 machine.

I want to be completely transparent about my own role:

I am a novelist, not a software engineer.

I do not have formal qualifications in:

Windows internals;
cryptography;
security engineering;
reverse engineering;
driver or operating-system development.

I can document what was investigated, what was tested, and what worked on the validated machine.

However, I may not be able to answer detailed technical questions, debug other Windows configurations, or provide individual technical support.

The technical information is published so that people with the appropriate expertise can inspect the result independently, reproduce the investigation, improve it, or adapt the mechanism to another Windows version.

Files included in v1.0
War3Win7BattleNetCompat.dll
War3Win7BattleNetCompatInstall.exe
INSTALL.bat
REMOVE.bat
README.txt
SHA256SUMS.txt
Important file hashes
War3Win7BattleNetCompat.dll
d2dc7f30344f2f4482196301835fdc45231619fc4df3d74bf49bf809b5fcbc90


War3Win7BattleNetCompatInstall.exe
748823f38819be8b83d52d568a179e754fdaece3b1532c0ae961b40a1fd4da40


INSTALL.bat
8b165793e8d5f48037414311df0fed4bd9b9f5dc5a282018141bf8fc916efe41


REMOVE.bat
e17b2e340ded4b9a3ffdc158f30ffbe9c8d71b7907490b8a2fd314ccffa42263


README.txt
0bc6a8ffa93627fe6446a4156f11da4e7c97d10e4d1e5f1dce298e2a59c31f96
If something goes wrong

Please keep:

INSTALL_REPORT.txt
REMOVE_REPORT.txt

If INSTALL.bat reports a precheck failure:

stop and do not bypass it.

If the installer reports a post-install hash failure, use REMOVE.bat before further testing.

If possible, include the generated report when describing a problem.

Because of the support limitations explained above, I cannot guarantee that I will be able to diagnose individual systems.

Provider identity
Provider name:
War3 Win7 Battle.net Compat v1.0


System32 DLL:
War3Win7BattleNetCompat.dll


DLL SHA256:
d2dc7f30344f2f4482196301835fdc45231619fc4df3d74bf49bf809b5fcbc90
Integrity

Final v1.0 release ZIP:

War3_Win7_BattleNet_Compat_v1.0.zip

SHA-256:

3db1ba9ccc1b0bcf805b0e849d4df77ffd78d966b50d517187a359b4dc0f85c7

Always prefer the file attached directly to the GitHub v1.0 Release and verify its hash before installation.

Legal / independence notice

This repository and release contain only the independent compatibility provider and its installation/removal tools.

No Blizzard game executable, Battle.net executable, Microsoft system DLL, authentication material, account credential, token, or server-side component is distributed.

Warcraft, Warcraft III, Battle.net and Blizzard Entertainment are trademarks or properties of their respective owners.

Windows and Microsoft are trademarks or properties of Microsoft Corporation.

AVG is a trademark or product of its respective owner.

ChatGPT and OpenAI are trademarks or products of OpenAI.

This project is independent and is not affiliated with or endorsed by Blizzard Entertainment, Microsoft, AVG, or OpenAI.
