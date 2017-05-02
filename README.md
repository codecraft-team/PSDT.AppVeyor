# PowerShell Developer Tools

[![Build status](https://ci.appveyor.com/api/projects/status/ds64a9kj6snaio64?svg=true&passingText=Build%20Passing&failingText=Build%20Failing&pendingText=Build%20Pending)](https://ci.appveyor.com/project/tauri-code/psdevtools)

A collection of PowerShell scripts and modules, which increase .NET developers every day productivity.

## Table of contents

1. [Overview](#overview)
1. [Visual Studio Module](#visualstudiomodule)
1. [Team Foundation Server Module](#tfsmodule)

## Overview

### Requirements <a name="requirements"></a>

To use these modules the PowerShell execution policy must allow executing local scripts.
To enable executing scripts one can use e.g.

```powershell
Set-ExecutionPolicy RemoteSigned
```

To verify the current execution policy use

```powershell
Get-ExecutionPolicy
```

## Visual Studio module: PSDT.VisualStudio <a name="visualstudiomodule"></a>

Contains cmdlets to simplify working with Visual Studio solutions from within PowerShell.

### Prerequisites

- At least Visual Studio C# feature must be installed on the environment using the module.

### Cmdlets

All cmdlets within this module use "VS" as noun prefix.  
To get an overview of available cmdlets use the PowerShell Get-Command cmdlet.

```powershell
Get-Command -noun VS*
```

When the module is loaded into a PowerShell session the PowerShell title switches to **Visual Studio Command Prompt**.

#### Import-VSCommandPrompt

Imports required enviroment variables into the current PowerShell session.
After executing this cmdlet commands like msbuild are available within the current PowerShell session.
The cmdlet does not need to be called explicitly. It is call implicitly when the module will be loaded e.g. by executing another cmdlet of the module.

#### Get-VSSolution

Gets the Visual Studio solution files, which match the paramters. The cmdlet accepts one or more filters as parameter, and uses them to filter the full path of the solution file. 

```powershell
Get-VSSolution master Build
```

Gets the Build.sln file(s), which have the "master" word in the full path.

#### Invoke-VSBuild

Builds a specified Visual Studio solution file.

```powershell
Invoke-VSBuild -Solution Build.sln  
Get-VSSolution Build.sln | Invoke-VSBuild
```

The cmdlet supports parameters to specify the build target, out-dir, verbosity, MSBuild parameters, etc.

```powershell
Invoke-VSBuild Build.sln -Target "Clean"
Invoke-VSBuild Build.sln -Properties "/p:Platform=x86"
Invoke-VSBuild Build.sln -Properties "/m:4"
```

For detailed list of parameters and examples see
>PS \\>Get-Help Invoke-VSBuild -Detailed

#### Invoke-VSTest

Executes the tests for specified test files. See Cmdlet help for defaults.
>PS \\>Invoke-VSTest
PS \\>Invoke-VSTest -PathMatch ".*\\bin\\release\\"

The cmdlet supports parameters to filter tests, executing tests in parallel, etc.

```powershell
Invoke-VSTest -TestCaseFilter "TestCategory!=LongRunningTests"
Invoke-VSTest -Parallel
Invoke-VSTest -Settings local.runsettings
```

For detailed list of parameters and examples see

```powershell
Get-Help Invoke-VSTest -Detailed
```

## TFS module: PSDT.TFS <a name="tfsmodule"></a>

Contains cmdlets to simplify working with Team Foundation Server from within the powershell.

### Prerequisites

- PSDT.VisualStudio
- PowerShell snap-in Microsoft.TeamFoundation.PowerShell which is available through the Team Foundation Server PowerTools.

### Cmdlets

All cmdlets within this module use "Tfs" as noun prefix. When the module is loaded the Microsoft.TeamFoundation.PowerShell snap-in will be loaded.
To get an overview of available cmdlets use the PowerShell Get-Command cmdlet.

```powershell
Get-Command -noun Tfs
```

#### Get-TfsLatest

Performs a get latest operation. The cmdlet must be executed from within a local workspace to work.

```powershell
Get-TfsLatest
```

For detailed list of parameters and examples see

```powershell
Get-Help Get-TfsLatest -Detailed
```