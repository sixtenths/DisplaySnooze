# DisplaySnooze

DisplaySnooze is a tiny open-source Windows utility that turns your displays off while leaving the PC awake and your current Windows session alone.

## Why

I like to keep my PC on, and I do not usually log out because it is just me in my home. At night, I just wanted an easy way to turn my screens off so the room is not lit up while I am trying to sleep.

Windows can turn monitors off, but sometimes a short-lived wake event turns them right back on. DisplaySnooze handles that by turning the displays off immediately, then repeating the same monitor-off command for a short guard window.

## What It Does

DisplaySnooze sends the standard Windows monitor power command:

```text
WM_SYSCOMMAND / SC_MONITORPOWER / 2
```

By default, it:

- Turns the displays off immediately.
- Repeats the monitor-off command every 4 seconds.
- Stops after 3 minutes.
- Leaves the PC awake.
- Leaves your apps running.
- Does not lock, log out, shut down, sleep, hibernate, or change power settings.
- Does not install a service.
- Does not add itself to startup.
- Does not use the network.

## Usage

Double-click `DisplaySnooze.exe`, or run it from PowerShell:

```powershell
.\DisplaySnooze.exe
```

Optional arguments:

```powershell
.\DisplaySnooze.exe <guard-seconds> <interval-seconds>
```

Examples:

```powershell
.\DisplaySnooze.exe 300
.\DisplaySnooze.exe 300 5
```

`guard-seconds` defaults to `180` and is clamped between `15` and `1800`.
`interval-seconds` defaults to `4` and is clamped between `1` and `60`.

## Build

```powershell
.\Build.ps1
```

The build script uses the .NET Framework C# compiler included with Windows.

## Signing

```powershell
.\Sign-DisplaySnooze.ps1
```

The signing script creates or reuses a local self-signed Authenticode certificate:

```text
CN=Zac DisplaySnooze Local Code Signing
```

That signature proves the file has not changed since signing, but it will not show as a trusted publisher on other machines unless they explicitly trust the exported certificate or the executable is signed with a trusted public code-signing certificate.
