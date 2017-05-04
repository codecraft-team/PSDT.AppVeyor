@{
    RootModule = '.\PSDT.AppVeyor.psm1'
    ModuleVersion = '1.0.0.0'
    GUID = 'f38546f7-972e-46bb-afa9-2d7df93a9894'
    Author = 'Tauri-Code'
    CompanyName = 'Tauri-Code'
    Copyright = '(c) 2017 Tauri-Code. All rights reserved.'
    Description = 'A collection of App Veyor related PowerShell developer tools.'
    FunctionsToExport = @("Get-AVProject","Get-AVBuild","Get-AVRestHeader","Test-AVBuildToday","Update-AVBuild","Update-AVBuildRevision","Update-AVBuildVersion","Invoke-AVScriptAnalysis","Invoke-PSDTPostBuild","Invoke-PSDTInitBuild","Invoke-PSDTPreBuild")
}