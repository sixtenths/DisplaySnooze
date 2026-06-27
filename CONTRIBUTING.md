# Contributing to DisplaySnooze

Thanks for helping improve DisplaySnooze. Bug reports, platform testing, documentation fixes, and focused code contributions are welcome.

## Before You Start

- Search existing issues before opening a new one.
- Use the bug or feature issue form when possible.
- Keep changes focused on one problem.
- For larger behavior changes, open an issue first so the approach can be discussed.

## Development

The Windows application is a small C# program built with the .NET Framework compiler included with Windows:

```powershell
.\Build.ps1
```

The Linux implementation is a Bash script. Run it directly from the repository:

```bash
bash linux/displaysnooze
```

Build Linux packages with:

```bash
chmod +x linux/displaysnooze packaging/linux/build-linux-packages.sh
packaging/linux/build-linux-packages.sh
```

## Testing Changes

- Confirm the displays turn off while the computer remains awake and logged in.
- Confirm `Esc` cancels the guard early. On Linux, also confirm `Ctrl+C` works.
- Test changed command-line arguments, including invalid values and boundary values.
- For Linux backend changes, name the desktop environment, compositor, display protocol, and distribution tested.
- Do not commit generated binaries, signing certificates, or package output.

## Pull Requests

- Explain the problem and the behavior change.
- Link the related issue when one exists.
- List the Windows or Linux environments you tested.
- Update the README or wiki when user-facing behavior changes.
- By contributing, you agree that your contribution is licensed under the repository's MIT License.

Please follow the [Code of Conduct](CODE_OF_CONDUCT.md) in all project spaces.
