Function Add-VMGpuPartitionAdapterFiles {
    param(
        [string]$Hostname = $ENV:COMPUTERNAME,
        [string]$DriveLetter,
        [string]$GPUName
    )

    Function Copy-DriverStore {
        param(
            [string]$Path
        )

        $Dir = Split-Path -Parent $Path
        $Dest = ("$Driveletter" + $(Split-Path -NoQualifier $Dir)).Replace("driverstore", "HostDriverStore").Replace("DriverStore", "HostDriverStore")

        if (!$(Test-Path -Path $Dest)) {
            Write-Host "Copying folder '$Dir' into '$Dest'"
            Copy-Item -path "$Dir" -Destination "$Dest" -Recurse
        }
    }

    If (!($DriveLetter -like "*:*")) {
        $DriveLetter = $Driveletter + ":"
    }

    If ($GPUName -eq "AUTO") {
        $PartitionableGPUList = Get-WmiObject -Class "Msvm_PartitionableGpu" -ComputerName $env:COMPUTERNAME -Namespace "ROOT\virtualization\v2"
        $DevicePathName = $PartitionableGPUList.Name | Select-Object -First 1
        $GPU = Get-PnpDevice | Where-Object {($_.DeviceID -like "*$($DevicePathName.Substring(8,16))*") -and ($_.Status -eq "OK")} | Select-Object -First 1
        $GPUName = $GPU.Friendlyname
        $GPUServiceName = $GPU.Service 
    }
    Else {
        $GPU = Get-PnpDevice | Where-Object {($_.Name -eq "$GPUName") -and ($_.Status -eq "OK")} | Select-Object -First 1
        $GPUServiceName = $GPU.Service
    }
    # Get Third Party drivers used, that are not provided by Microsoft and presumably included in the OS

    Write-Host "INFO   : Finding and copying driver files for $GPUName to VM. This could take a while..."

    $Drivers = Get-WmiObject Win32_PNPSignedDriver | where {$_.DeviceName -eq "$GPUName"}

    New-Item -ItemType Directory -Path "$DriveLetter\Windows\System32\HostDriverStore" -Force | Out-Null

    #copy directory associated with sys file 
    $ServicePath = (Get-WmiObject Win32_SystemDriver | Where-Object {$_.Name -eq "$GPUServiceName"}).Pathname
    Copy-DriverStore -Path $ServicePath

    # Initialize the list of detected driver packages as an array
    $DriverFolders = @()
    foreach ($driver in $Drivers) {

        $DriverFiles = @()
        $DriverName = $driver.DeviceName
        $DriverID = $driver.DeviceID

        $ModifiedDeviceID = $DriverID -replace "\\", "\\"
        $Antecedent = "\\" + $Hostname + "\ROOT\cimv2:Win32_PNPSignedDriver.DeviceID=""$ModifiedDeviceID"""
        $DriverFiles += Get-WmiObject Win32_PNPSignedDriverCIMDataFile | where {$_.Antecedent -eq $Antecedent}

        if ($DriverName -like "NVIDIA*") {
            New-Item -ItemType Directory -Path "$Driveletter\Windows\System32\drivers\Nvidia Corporation\" -Force | Out-Null
        }

        foreach ($file in $DriverFiles) {
            $path = $file.Dependent.Split("=")[1] -replace '\\\\', '\' # Get Path
            $path2 = $path.Substring(1,$path.Length-2) # Remove double quote (") from path

            If ($path2 -like "C:\Windows\System32\DriverStore\*") {
                Copy-DriverStore -Path $path2
            } Else {
                $ParseDestination = $path2.Replace("c:", "$Driveletter")
                $Destination = Split-Path -Parent $ParseDestination

                if (!$(Test-Path -Path $Destination)) {
                    New-Item -ItemType Directory -Path $Destination -Force | Out-Null
                }

                Write-Host "Copying '$path2'"

                Copy-Item $path2 -Destination $Destination -Force
            }
        }
    }
}
