# PowerShell Developer Tools

A collection of PowerShell cmdlets, which encapsulates AppVeyor related tasks and helps to create builds for PowerShell modules.

## Installation

The module can be installed through PowerShell Gallery or by downloading the sources.

```powershell
PS :\> Install-Package PSDT.AppVeyor
```

## Features

- Find an App Veyor
  - Project,
  - Build,
  - Header for REST calls.
- Update an App Veyor
  - Build revision,
  - Build version.
- Get, install and execute Microsoft's Script Analyzer tool during the build.

For more information check the cmdlets provided by the module, for example:

```powershell
Get-Command -Module PSDT.AppVeyor
```