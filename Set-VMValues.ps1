#Requires -RunAsAdministrator

Param (
    [ValidateScript({ (Get-VM -Name $_).State -eq "Off" })]
    [string]$VMName,
    [bool]$CreateGPUPartition = $true,
    [bool]$EnableTPM = $true,
    [ValidateRange(1, 80)]
    [uint32]$GPUSharePercentage = 50
)

function Set-GPUPartition {
    Param (
        [Parameter(mandatory)]
        [ValidateScript({ (Get-VM -Name $_).State -eq "Off" })]
        [string]$VMName,
        [ValidateRange(1, 80)]
        [uint32]$GPUSharePercentage = 50
    )

    [double]$divider = 100 / $GPUSharePercentage

    $GPU = Get-VMPartitionableGpu

    # Partition VRAM
    $minVRAM = $GPU.MinPartitionVRAM
    $maxVRAM = $GPU.AvailableVRAM
    $optimalVRAM = [math]::Round($maxVRAM / $divider)

    Write-Host "Setting Partition VRAM: min = $minVRAM, max = $maxVRAM, optimal = $optimalVRAM"

    # Partition Encode
    $minEncode = $GPU.MinPartitionEncode
    $maxEncode = $GPU.MaxPartitionEncode
    $optimalEncode = [math]::Round($maxEncode / $divider)

    Write-Host "Setting Partition Encode: min = $minEncode, max = $maxEncode, optimal = $optimalEncode"

    # Partition Decode
    $minDecode = $GPU.MinPartitionDecode
    $maxDecode = $GPU.MaxPartitionDecode
    $optimalDecode = [math]::Round($maxDecode / $divider)

    Write-Host "Setting Partition Decode: min = $minDecode, max = $maxDecode, optimal = $optimalDecode"

    # Partition Compute
    $minCompute = $GPU.MinPartitionCompute
    $maxCompute = $GPU.MaxPartitionCompute
    $optimalCompute = [math]::Round($maxCompute / $divider)

    Write-Host "Setting Partition Compute: min = $minCompute, max = $maxCompute, optimal = $optimalCompute"

    # Create GPU Partition
    Remove-VMGpuPartitionAdapter -VMName $VMName -ErrorAction Ignore
    Add-VMGpuPartitionAdapter -VMName $VMName

    Set-VMGpuPartitionAdapter -VMName $VMName -MinPartitionVRAM $minVRAM -MaxPartitionVRAM $maxVRAM -OptimalPartitionVRAM $optimalVRAM
    Set-VMGPUPartitionAdapter -VMName $VMName -MinPartitionEncode $minEncode -MaxPartitionEncode $maxEncode -OptimalPartitionEncode $optimalEncode
    Set-VMGpuPartitionAdapter -VMName $VMName -MinPartitionDecode $minDecode -MaxPartitionDecode $maxDecode -OptimalPartitionDecode $optimalDecode
    Set-VMGpuPartitionAdapter -VMName $VMName -MinPartitionCompute $minCompute -MaxPartitionCompute $maxCompute -OptimalPartitionCompute $optimalCompute

    # Random stuff
    Set-VM -VMName $VMName -LowMemoryMappedIoSpace 1GB
    Set-VM -VMName $VMName -HighMemoryMappedIoSpace 32GB
    Set-VM -VMName $VMNAme -GuestControlledCacheTypes $true
}

$VMList = $VMNAme

if ($VMName.Length -lt 1) {
    Write-Host "No VM?"

    Remove-Module Select-VMs -Force -ErrorAction Ignore
    Import-Module $PSSCriptRoot\Select-VMs.psm1

    $result = Select-VMs
    if ($result -ne [System.Windows.Forms.DialogResult]::OK) {
        Write-Host "Whoops"

        return
    }

    $VMList = $global:SelectedVMs.ForEach({ $_.Name })
}

ForEach ($vm in $VMList) {
    if ($CreateGPUPartition) {
        Set-GPUPartition -VMName $vm -GPUSharePercentage $GPUSharePercentage
    }

    if ($EnableTPM) {
        Set-VMKeyProtector -VMName $vm -RestoreLastKnownGoodKeyProtector
        Enable-VMTPM -VMName $vm
    }

    # Disable stuff that breaks VM
    Set-VMFirmware -VMName $vm -EnableSecureBoot Off
    Set-VMSecurity -VMName $vm -EncryptStateAndVmMigrationTraffic $false

    # Disable things that break gpu partitioning (checkpoints, dynamic memory, etc...)
    Set-VM -VMName $vm -CheckpointType Disabled
    Set-VM -VMName $vm -AutomaticStopAction Save

    Set-VMMemory -VMName $vm -DynamicMemoryEnabled $false
    Set-VMProcessor -VMName $vm -ExposeVirtualizationExtensions $true
}