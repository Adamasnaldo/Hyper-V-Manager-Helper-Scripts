#Requires -RunAsAdministrator

<# 
If you are opening this file in Powershell ISE you should modify the params section like so...
Remember: GPU Name must match the name of the GPU you assigned when creating the VM...

Param (
    [string]$VMName = "NameofyourVM",
    [string]$GPUName = "NameofyourGPU",
    [string]$Hostname = $ENV:Computername
)

#>

Param (
    [Parameter(mandatory)]
    [ValidateScript({ (Get-VM -Name $_).State -eq "Off" })]
    [string]$VMName,
    [string]$GPUName = "AUTO",
    [string]$Hostname = $ENV:Computername
)

Remove-Module Add-VMGpuPartitionAdapterFiles -Force -ErrorAction Ignore
Import-Module $PSSCriptRoot\Add-VMGpuPartitionAdapterFiles.psm1

$VM = Get-VM -VMName $VMName
$VHD = Get-VHD -VMId $VM.VMId

if ($VM.state -ne "Off") {
    "Attemping to shutdown VM..."
    Stop-VM -Name $VMName -Force
}

While ($VM.State -ne "Off") {
    Start-Sleep -s 3
    "Waiting for VM to shutdown - make sure there are no unsaved documents..."
}

"Mounting Drive..."
$DriveLetter = (Mount-VHD -Path $VHD.Path -PassThru | Get-Disk | Get-Partition | Get-Volume | Where-Object {$_.DriveLetter} | ForEach-Object DriveLetter)

"Copying GPU Files - this could take a while..."
Add-VMGPUPartitionAdapterFiles -Hostname $Hostname -DriveLetter $DriveLetter -GPUName $GPUName

"Dismounting Drive..."
Dismount-VHD -Path $VHD.Path

"Done..."