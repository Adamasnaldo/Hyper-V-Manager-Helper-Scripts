#Requires -RunAsAdministrator

Param (
    [Parameter(mandatory)]
    [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
    [string]$VHDPath,
    [string]$VMName = "",
    [ValidateRange(512, [int64]::MaxValue)]
    [int64]$MemoryStartupBytes = 4GB,
    [string]$SwitchName = "VM Ethernet",
    [ValidateRange(1, [uint32]::MaxValue)]
    [uint32]$CPUCount = 2,
    [bool]$CreateGPUPartition = $true,
    [bool]$EnableTPM = $true,
    [ValidateRange(10, 80)]
    [uint32]$GPUSharePercentage = 50
)

# Get full path for VHDX
$FIVHDPath = Get-Item $VHDPath

# Define VM Name
if ([string]::IsNullOrWhiteSpace($VMNAme)) {
    $VMNAme = $FIVHDPath.BaseName
}

# Create VM
New-VM -Name $VMNAme -MemoryStartupBytes $MemoryStartupBytes -BootDevice VHD -SwitchName $SwitchName -VHDPath $FIVHDPath.FullName -Generation 2 -Confirm

# Set processors separately, cuz it can't be done when creating...
Set-VMProcessor -VMName $VMNAme -Count $CPUCount

# Enable TPM
if ($EnableTPM) {
    Set-VMKeyProtector -VMName $VMNAme -NewLocalKeyProtector
    Enable-VMTPM -VMName $VMNAme
}

if ($CreateGPUPartition) {
    .\Set-VMValuesAndGPUDrivers -VMName $VMNAme -GPUSharePercentage $GPUSharePercentage -EnableTPM $false
} else {
    .\Set-VMValues -VMName $VMNAme -CreateGPUPartition $CreateGPUPartition -EnableTPM $false -GPUSharePercentage $GPUSharePercentage
}