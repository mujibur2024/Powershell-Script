<#
    Script Name : SBE Driver
    Description : Cluster node driver version checker
    Author      : Mujibur Rahman
    Version     : 1.0
    Created     : 2025-08-04
    Trademark   : © Mujibur Rahman. All rights reserved.
#>

# Load Failover Cluster module
Import-Module FailoverClusters

# Get all cluster nodes
$clusterNodes = Get-ClusterNode | Select-Object -ExpandProperty Name

# Get the full path to DriverComponents.xml in the current directory
$xmlPath = Join-Path -Path (Get-Location) -ChildPath "DriverComponents.xml"

# Script block to run on each node
$scriptBlock = {
    param($xmlPath)

    [xml]$xml = Get-Content -Path $xmlPath

    $searchPaths = @(
        "C:\Windows\INF",
        "C:\Windows\System32\DriverStore\FileRepository"
    )

    $results = @()

    foreach ($component in $xml.PlatformComponent.Components.Component) {
        $friendlyName = $component.FriendlyName
        $targetVersion = $component.TargetVersion
        $targetPath = $component.TargetPath
        $infFileName = [System.IO.Path]::GetFileName($targetPath)

        $foundInf = $null
        $installedVersion = "[Not found]"
        $status = "NOT FOUND"

        foreach ($path in $searchPaths) {
            $foundInf = Get-ChildItem -Path $path -Recurse -Filter $infFileName -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($foundInf) { break }
        }

        if ($foundInf) {
            $versionLine = Select-String -Path $foundInf.FullName -Pattern "DriverVer" | Select-Object -First 1
            if ($versionLine) {
                $installedVersion = ($versionLine -split ",")[1].Trim()
                $status = if ($installedVersion -eq $targetVersion) { "MATCH" } else { "MISMATCH" }
            } else {
                $installedVersion = "[No version]"
                $status = "UNKNOWN"
            }
        }

        $results += [PSCustomObject]@{
            FriendlyName     = $friendlyName
            TargetVersion    = $targetVersion
            InstalledVersion = $installedVersion
            Status           = $status
        }
    }

    return $results
}

# Define column widths
$friendlyNameWidth = 60
$targetVersionWidth = 22
$installedVersionWidth = 22
$statusWidth = 12

# Run the script on each node and display results
foreach ($node in $clusterNodes) {
    Write-Host "`nResults from $node" -ForegroundColor Cyan

    # Print column headers
    $header = "{0,-$friendlyNameWidth}{1,-$targetVersionWidth}{2,-$installedVersionWidth}{3,-$statusWidth}" -f "Friendly Name", "Target Version", "Installed Version", "Status"
    Write-Host $header -ForegroundColor Yellow
    Write-Host ("-" * ($friendlyNameWidth + $targetVersionWidth + $installedVersionWidth + $statusWidth))

    $nodeResults = Invoke-Command -ComputerName $node -ScriptBlock $scriptBlock -ArgumentList $xmlPath

    foreach ($result in $nodeResults) {
        $line = "{0,-$friendlyNameWidth}{1,-$targetVersionWidth}{2,-$installedVersionWidth}{3,-$statusWidth}" -f `
            $result.FriendlyName, $result.TargetVersion, $result.InstalledVersion, $result.Status

        switch ($result.Status) {
            "MISMATCH"   { Write-Host $line -ForegroundColor Red }
            "MATCH"      { Write-Host $line -ForegroundColor Green }
            "NOT FOUND"  { Write-Host $line -ForegroundColor DarkYellow }
            default      { Write-Host $line -ForegroundColor Gray }
        }
    }
}