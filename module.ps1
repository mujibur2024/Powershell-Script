# Target modules relevant to SBE and solution updates
$targetModules = @(
    "Az.StackHCI", "Az.AksArc", "Az.ConnectedMachine", "Az.Accounts", "Az.Resources", "Az",
    "ArcHci", "Moc", "PrivateCloud.DiagnosticInfo", "DownloadSdk",
    "PackageManagement", "PowerShellGet", "TraceProvider"
)

# Get all cluster nodes
$clusterNodes = Get-ClusterNode | Select-Object -ExpandProperty Name

# Store module versions per node
$allModuleVersions = @{}

foreach ($node in $clusterNodes) {
    try {
        $modules = Invoke-Command -ComputerName $node -ScriptBlock {
            Get-InstalledModule | Select-Object Name, Version
        }

        $allModuleVersions[$node] = $modules
    } catch {
        $allModuleVersions[$node] = "Error: $_"
    }
}

# Define column widths
$moduleColWidth = 35
$nodeColWidth = 20

# Print header
$header = "Module".PadRight($moduleColWidth)
foreach ($node in $clusterNodes) {
    $header += $node.PadRight($nodeColWidth)
}
Write-Host $header -ForegroundColor Cyan

# Compare and print each module
foreach ($moduleName in $targetModules) {
    $versions = @()
    $row = @{}
    $notInstalledCount = 0

    foreach ($node in $clusterNodes) {
        $modules = $allModuleVersions[$node]
        if ($modules -is [string]) {
            $versionStr = "Error"
        } else {
            $version = ($modules | Where-Object { $_.Name -eq $moduleName }).Version
            $versionStr = if ($version) { $version.ToString() } else { "Not Installed" }
        }

        $row[$node] = $versionStr
        $versions += $versionStr
        if ($versionStr -eq "Not Installed") { $notInstalledCount++ }
    }

    $uniqueVersions = $versions | Select-Object -Unique

    # Print row with alignment and color
    $output = $moduleName.PadRight($moduleColWidth)
    Write-Host -NoNewline $output

    foreach ($node in $clusterNodes) {
        $versionStr = $row[$node].PadRight($nodeColWidth)
        if ($notInstalledCount -eq 0) {
            if ($uniqueVersions.Count -eq 1) {
                Write-Host -NoNewline $versionStr -ForegroundColor Green
            } else {
                Write-Host -NoNewline $versionStr -ForegroundColor Red
            }
        } else {
            Write-Host -NoNewline $versionStr
        }
    }
    Write-Host ""
}