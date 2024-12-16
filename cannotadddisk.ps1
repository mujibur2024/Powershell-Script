# Get physical disks and format the output
$disks = Get-PhysicalDisk | Format-Table FriendlyName, MediaType, Size, CanPool, CannotPoolReason, SerialNumber -AutoSize

# Display the formatted table
$disks

# Define descriptions for each CannotPoolReason
$descriptions = @{
    "In a pool" = "The drive already belongs to a storage pool. To use this drive in another storage pool, first remove the drive from its existing pool using Remove-PhysicalDisk or reset the drive using Reset-PhysicalDisk."
    "Not healthy" = "The drive isn't in a healthy state and might need to be replaced."
    "Removable media" = "The drive is classified as a removable drive. Storage Spaces doesn't support media recognized by Windows as removable."
    "In use by cluster" = "The drive is currently used by a Failover Cluster."
    "Offline" = "The drive is offline. To bring all offline drives online and set to read/write, use the following commands:
                  Get-Disk | Where-Object -Property OperationalStatus -EQ 'Offline' | Set-Disk -IsOffline $false
                  Get-Disk | Where-Object -Property IsReadOnly -EQ $true | Set-Disk -IsReadOnly $false"
    "Insufficient capacity" = "There are partitions taking up the free space on the drive. Delete any volumes on the drive using Clear-Disk."
    "Verification in progress" = "The Health Service is checking if the drive or firmware is approved for use."
    "Verification failed" = "The Health Service couldn't verify if the drive or firmware is approved."
    "Firmware not compliant" = "The firmware on the drive isn't in the list of approved firmware revisions."
    "Hardware not compliant" = "The drive isn't in the list of approved storage models."
}

# Display solutions based on CannotPoolReason
foreach ($disk in Get-PhysicalDisk) {
    if ($disk.CannotPoolReason) {
        $reason = $disk.CannotPoolReason
        $description = $descriptions[$reason]
        Write-Output "Disk: $($disk.FriendlyName)"
        Write-Output "Serial Number: $($disk.SerialNumber)"
        Write-Output "Reason: $reason"
        Write-Output "Description: $description"
        Write-Output ""
    }
}
