class AppVeyorId {
    [string]$AuthorizationToken;
    
    AppVeyorId([string]$AuthorizationToken) {
        $this.AuthorizationToken = $AuthorizationToken;
    }
}

class AppVeyorBuildId : AppVeyorId {
    [string]$AccountName;
    [string]$ProjectSlug;

    AppVeyorBuildId([string]$AuthorizationToken,[string]$AccountName,[string]$ProjectSlug) : base($AuthorizationToken) {
        $this.AccountName = $AccountName;
        $this.ProjectSlug = $ProjectSlug;
    }
}

Function Get-AVProject {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True,ValueFromPipeline=$True)]
        [AppVeyorId]$AppVeyorId
    )

    return Invoke-RestMethod -Uri 'https://ci.appveyor.com/api/projects' -Headers (Get-AVRestHeader $AppVeyorId.AuthorizationToken) -Method Get;
}

Function Get-AVBuild {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True,ValueFromPipeline=$True)]
        [AppVeyorBuildId]$AppVeyorBuildId
    )

    $url = "https://ci.appveyor.com/api/projects/$($AppVeyorBuildId.AccountName)/$($AppVeyorBuildId.ProjectSlug)";
    Write-Verbose "Url:$url";

    $lastBuild = Invoke-RestMethod -Uri $url -Headers (Get-AVRestHeader $AppVeyorBuildId.AuthorizationToken) -Method Get;

    Write-Verbose (ConvertTo-Json $lastBuild);

    return $lastBuild;
}

Function Get-AVRestHeader {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True,ValueFromPipeline=$True)]
        [string]$AuthorizationToken
    )
    
    return @{"Authorization" = "Bearer $AuthorizationToken";"Content-type" = "application/json"};
}

Function Test-AVBuildToday {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True,ValueFromPipeline=$True)]
        $LastBuild
    )

    If(-not $LastBuild.build.created) {
        return $false;
    }
    
    $format = "yyyyMMdd";
    $today = [DateTime]::UtcNow.ToString($format);

    Write-Verbose "Last build finished at $($LastBuild.build.created).";
    $lastBuildFinished = [DateTime]::Parse($LastBuild.build.created).ToUniversalTime().ToString($format);

    $isLastBuildFromToday = $lastBuildFinished -eq $today;
    Write-Verbose "Last build is from today: '$isLastBuildFromToday' (based on comparing of last build data: '$lastBuildFinished' and today: '$today')."
    return $isLastBuildFromToday;
}

Function Update-AVBuild {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True,ValueFromPipeline=$True)]
        [AppVeyorBuildId]$AppVeyorBuildId,
        [Parameter(Mandatory=$True,ValueFromPipeline=$True)]
        [int]$NextBuildNumber
    )

    $url = "https://ci.appveyor.com/api/projects/$($AppVeyorBuildId.AccountName)/$($AppVeyorBuildId.ProjectSlug)/settings/build-number";
    $requestBody = "{ nextBuildNumber: $NextBuildNumber }";

    Write-Verbose "Url:$url Request body: $requestBody";

    return Invoke-RestMethod -Method Put -Uri $url -Body $requestBody -Headers (Get-AVRestHeader $AppVeyorBuildId.AuthorizationToken);
}

Function Update-AVBuildRevision {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True)]
        [string]$AuthorizationToken,
        [string]$AccountName = $env:APPVEYOR_ACCOUNT_NAME,
        [string]$ProjectSlug = $env:APPVEYOR_PROJECT_SLUG
    )

    $appVeyorId = [AppVeyorBuildId]::new($AuthorizationToken,$AccountName,$ProjectSlug);
    $anyBuildToday = Get-AVBuild $appVeyorId | Test-AVBuildToday;
    If(-not $anyBuildToday) {
        Write-Verbose "This is the first build today, setting revision to 1.";
        Update-AVBuild $appVeyorId 1;
        $env:APPVEYOR_BUILD_NUMBER = 1;
    } Else {
        Write-Verbose "The build revision will be not reset to 1, because this is not the first build today.";
    }
}

Function Update-AVBuildVersion {
    [CmdletBinding()]
    Param (
    )

    $version = Get-Date -Format "yyMM.dd";
    $currentVersion = $($env:APPVEYOR_BUILD_NUMBER).PadLeft(3,"0");
    $targetVersion = "1.0.$version$currentVersion";

    Write-Verbose "Updating build version to $targetVersion.";

    Update-AppveyorBuild -Version $targetVersion;
}

Function Invoke-AVScriptAnalysis {
    [CmdletBinding()]
    Param (
        [string]$Path = $env:APPVEYOR_BUILD_FOLDER,
        [string]$Severity = "Error"
    )

    try {
        $scriptAnalyzerReport = Invoke-ScriptAnalyzer -Path $Path -Recurse -Severity $Severity;

        If($scriptAnalyzerReport.Count -gt 0) {
            $scriptAnalyzerReport | % { Write-Host $_.Message -ForegroundColor Red  };
            $host.SetShouldExit(1);
        }
    } catch {
        Write-Output $_;
        $host.SetShouldExit(1);
    }
}

Function Invoke-PSDTInitBuild {
    [CmdletBinding()]
    Param (

    )

    Install-Module -Name PSScriptAnalyzer;
}

Function Invoke-PSDTPreBuild {
    [CmdletBinding()]
    Param (

    )

    Import-Module PSDT.AppVeyor;
    
    Update-AVBuildRevision $env:AppVeyorAuthorizationToken;
    
    Update-AVBuildVersion -Verbose;
    
    Invoke-AVScriptAnalysis;
}

Function Invoke-PSDTPostBuild {
    [CmdletBinding()]
    Param (
        [string]$Module
    )

    if($env:APPVEYOR_PULL_REQUEST_NUMBER) {
        Write-Host "Pull request available ('$($env:APPVEYOR_PULL_REQUEST_NUMBER)'), PSGallery publish will be skipped.";
        return;
    }

    $version = Get-Date -Format "yyMM.dd";
    $currentVersion = ($env:APPVEYOR_BUILD_NUMBER).PadLeft(3,"0");
    $targetVersion = "1.0.$($version)$($currentVersion)";
    
    $moduleManifest = "$($env:APPVEYOR_BUILD_FOLDER)\$Module.psd1";
        
    Update-AppveyorBuild -Version $targetVersion;

    (Get-Content $moduleManifest) | Foreach-Object {$_ -replace '.*ModuleVersion.*$', "    ModuleVersion = '$targetVersion'"} | Set-Content $moduleManifest -Force;

    Write-Host "$Module updated, $((Get-Content -Path $moduleManifest | Where-Object { $_ -match ".*ModuleVersion.*$" }).Trim())";

    if (Test-Path 'C:\Tools\NuGet3') { 
        $nugetDir = 'C:\Tools\NuGet3';
    } else { 
        $nugetDir = 'C:\Tools\NuGet';
    }
    (New-Object Net.WebClient).DownloadFile('https://dist.nuget.org/win-x86-commandline/v3.3.0/nuget.exe', "$nugetDir\NuGet.exe");

    Publish-Module -Path "$($env:APPVEYOR_BUILD_FOLDER)" -NuGetApiKey $env:PSGalleryApiKey -Confirm:$false;
}