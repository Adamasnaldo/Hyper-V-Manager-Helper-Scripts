Param (
    [Parameter(mandatory)]
    [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
    [string]$VHDPath,
    [ValidateRange(1, [uint32]::MaxValue)]
    [uint32]$PartitionNumber = 2
)

$Drive = "\\.\PhysicalDrive$((Mount-VHD -Path "$VHDPath" -PassThru | Get-Disk).Number)"

Write-Output "Mounting partition $PartitionNumber from drive $Drive"

wsl --mount $Drive --partition $PartitionNumber

Write-Output "Pausing script until the disk is ready to unmount"

pause

wsl --unmount $Drive

Dismount-VHD -Path "$VHDPath"