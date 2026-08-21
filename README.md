# Warcraft III — Win7 Battle.net Compatibility

A system-specific compatibility variant of the original [War3-Win7-BattleNet-Compat](https://github.com/elconteodesombraluz-jpg/War3-Win7-BattleNet-Compat) project.

This release targets a specific Windows 7 SP1 x64 cryptographic stack where the original v1.0 provider does not work.

The goal is to restore Warcraft III Battle.net connectivity on this legacy Windows 7 configuration **without replacing or modifying the Windows system cryptographic DLLs**.

---

## Tested Configuration

### Operating System

- Windows 7 SP1 x64
- Windows version: `6.1.7601`

### System Cryptographic DLLs

This build was tested against the following exact SHA-256 values:

| File | SHA-256 |
|---|---|
| `schannel.dll` | `227000ed75a96e127855925ee8c1439eaf15e450ecd0533a3dace38c01acadbc` |
| `ncrypt.dll` | `c80e8599a2427846112f7dae4902a1242062cd20b05c9989b0f5467fd9bb411c` |
| `bcrypt.dll` | `ddb4cb575139233efaf2c59b7e9b04af36bbccc63190181f3b2a7e6bfc86e77e` |
| `bcryptprimitives.dll` | `3b5ed1a030bfd0bb73d4ffcd67a6a0b8501ef70293f223efaa12f430adf270f9` |

These hashes identify the exact Windows cryptographic binary set used during testing.

**Do not bypass the installer precheck on a different Windows 7 build.**

---

## Warcraft III

Tested with:

- Warcraft III version: `2.0.4.23745`
- Architecture: x64

The game itself already runs normally on the target system.

The problem addressed by this project is **Battle.net connectivity**, specifically error: 6:9

---

## Background

The original `War3-Win7-BattleNet-Compat` project provides a Windows 7 compatibility provider for Warcraft III Battle.net connectivity.

The original v1.0 implementation was validated against one specific Windows 7 cryptographic binary set.

Windows 7 systems with different versions of:

- `schannel.dll`
- `ncrypt.dll`
- `bcrypt.dll`
- `bcryptprimitives.dll`

may expose different SSL/CNG provider interfaces.

As a result, the original v1.0 provider may install successfully but still fail to provide working Battle.net connectivity on another Windows 7 build.

This repository is a separate compatibility target for one such older Windows 7 configuration.

---

## Why the Original v1.0 Build Did Not Work Here

The target `ncrypt.dll` exposes an older SSL/CNG provider interface.

It does not expose the following newer callbacks:

- `SslComputeSessionHash`
- `SslGeneratePreMasterKey`

The original v1.0 implementation extends the provider interface to version 3 and expects those callbacks to be available.

On the target system, the provider can therefore register successfully while Warcraft III still fails when the relevant TLS/CNG path is reached.

The resulting symptom is Battle.net error `6:9`.

---

## Compatibility Approach

This variant targets the older provider interface instead of requiring the newer callbacks.

The compatibility layer:

- preserves the existing v2 provider callback table;
- preserves the existing compatibility logic;
- does not require the missing v3 callbacks;
- does not replace Windows system cryptographic DLLs;
- does not modify Windows system cryptographic DLLs;
- verifies the target system using SHA-256 before installation.

The resulting provider was tested successfully on the exact Windows 7 configuration listed above.

---

## Confirmed Result

After installing the compatibility provider:

**Warcraft III 2.0.4.23745 → Battle.net → previous error 6:9 → resolved**

The game and Battle.net connectivity worked without replacing the system cryptographic DLLs.

---

## Compatibility Provider

### Working DLL

File:

`War3Win7BattleNetCompat.dll`

SHA-256:

`4b0ad5a8b9295b976a443c4969b6ad69915081e2865d86535d3889af9c032b8e`

---

## Installation

Keep the following files in the same directory:

```text
War3Win7BattleNetCompat.dll
War3Win7BattleNetCompatInstall.exe
INSTALL_Win7_V2.bat
```

Run:

```text
INSTALL_Win7_V2.bat
```

as Administrator.

The installer checks:

- Windows version;
- 64-bit architecture;
- `schannel.dll` SHA-256;
- `ncrypt.dll` SHA-256;
- `bcrypt.dll` SHA-256;
- `bcryptprimitives.dll` SHA-256;
- compatibility provider SHA-256.

If all checks pass, the provider is registered and the configuration is verified.

After a successful installation:

1. Reboot Windows once.
2. Start Battle.net.
3. Launch Warcraft III.

---

## Do Not Modify Windows System DLLs

This project is specifically intended to work with the existing Windows cryptographic stack.

**Do not replace or modify:**

```text
C:\Windows\System32\schannel.dll
C:\Windows\System32\ncrypt.dll
C:\Windows\System32\bcrypt.dll
C:\Windows\System32\bcryptprimitives.dll
```

Do not replace system DLLs just to make the SHA-256 checks match.

If your hashes are different, your Windows build is outside the tested configuration.

---

## Removal

To remove the Windows 7 Battle.net compatibility provider, use the included:

`Remove_Win7_v2.bat`

### Steps

1. Close Battle.net and Warcraft III.
2. Right-click `Remove_Win7_v2.bat`.
3. Select **Run as administrator**.
4. Wait for the script to finish.
5. Check `REMOVE_REPORT.txt` for the result.
6. Reboot Windows once.

A successful removal should end with:

```text
RESULT: PASS - compatibility provider registration removed.
```

The removal script only removes the compatibility provider registration and the installed `War3Win7BattleNetCompat.dll`.

It does **not** replace, modify, or remove the following Windows system files:

```text
C:\Windows\System32\schannel.dll
C:\Windows\System32\ncrypt.dll
C:\Windows\System32\bcrypt.dll
C:\Windows\System32\bcryptprimitives.dll
```

### If removal reports an error

Do not manually delete or replace any Windows cryptographic DLLs.

Keep `REMOVE_REPORT.txt` and reboot Windows. If the provider DLL is still present after the reboot, run `Remove_Win7_v2.bat` as Administrator again.


---

## Troubleshooting

### The installer fails the SHA-256 precheck

Your Windows cryptographic DLL set does not match the tested configuration.

Check the SHA-256 values of:

```text
schannel.dll
ncrypt.dll
bcrypt.dll
bcryptprimitives.dll
```

Do not bypass the precheck.

A different Windows 7 update level may require a different compatibility build.

### The provider installs successfully but Battle.net still reports 6:9

Verify that:

1. The correct compatibility DLL was installed.
2. The installer completed successfully.
3. Windows was rebooted after installation.
4. The system DLL hashes still match the tested configuration.
5. Warcraft III version `2.0.4.23745` is being used.

A different Windows 7 cryptographic build may require a different compatibility implementation.

### Warcraft III behaves differently after experimenting with another provider build

Remove the compatibility provider using the supplied removal procedure, reboot Windows, and restore the known-working release.

---

## Tested Status

| Component | Status |
|---|---|
| Windows 7 SP1 x64 | ✅ Tested |
| Target cryptographic DLL set | ✅ Tested |
| Provider installation | ✅ Tested |
| Provider registration | ✅ Tested |
| Warcraft III 2.0.4.23745 | ✅ Tested |
| Battle.net connectivity | ✅ Working |
| Error 6:9 | ✅ Resolved |
| Windows system DLL replacement | ❌ Not required |

---

## Project Scope

This project is specifically intended for:

- Windows 7 SP1 x64;
- the exact cryptographic DLL hashes listed in this README;
- Warcraft III `2.0.4.23745`.

It is **not** intended as a universal Windows 7 compatibility patch.

Other Windows 7 builds may require a different compatibility implementation.

---

## Credits

This project is based on the research and compatibility approach of:

**elconteodesombraluz-jpg / War3-Win7-BattleNet-Compat**

Original repository:

https://github.com/elconteodesombraluz-jpg/War3-Win7-BattleNet-Compat

The original author developed the initial Windows 7 Schannel/CNG compatibility research and the original v1.0 implementation.

This repository is a separate system-specific compatibility variant for a different Windows 7 cryptographic binary set.

Many thanks to the original author for documenting the provider-interface behaviour and for making the original project available.

---

## Disclaimer

This project is an independent community compatibility project.

It is not affiliated with, endorsed by, or supported by:

- Blizzard Entertainment
- Microsoft

Use this software at your own risk.

Always keep a backup of the original compatibility files and make sure you have the original removal procedure available before experimenting with alternative builds.
