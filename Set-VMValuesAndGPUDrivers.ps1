#Requires -RunAsAdministrator

Param (
    [ValidateScript({ (Get-VM -Name $_).State -eq "Off" })]
    [string]$VMName,
    [string]$GPUName = "AUTO",
    [string]$Hostname = $ENV:Computername,
    [uint32]$GPUSharePercentage = 50,
    [bool]$EnableTPM = $false
)

$VMList = $VMName

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
    Write-Host "Setting up VM '$vm'"

    .\Set-VMValues -VMName $vm -CreateGPUPartition $true -GPUSharePercentage $GPUSharePercentage -EnableTPM $EnableTPM

    .\Update-VMGpuPartitionDriver.ps1 -VMName $vm -GPUName $GPUName -Hostname $Hostname
}
