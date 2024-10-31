# Hyper-V-Manager-Helper-Scripts
Powershell Scripts I made to programmatically create VMs in Hyper-V Manager.

I've also used some scripts from [Easy-GPU-PV](https://github.com/jamesstringerparsec/Easy-GPU-PV), to easily copy NVIDIA GPU drivers from host to guest and setup GPU partitioning.

To run the scripts, you can use [`run.bat`](run.bat), which spawns an admin powershell.

# Scripts

- <details>
    <summary>Create-VM</summary>

    <a id="create-vm"></a>

    Script: [Create-VM.ps1](Create-VM.ps1)

    This script creates a new VM.
    Notes:
    - `$VMName` argument will be set to the disk file name, if it is empty.
    - `$EnableTPM` argument is responsible for deciding whether to create a new LocalKeyProtector for the VM, and use it for the TPM, or not create it and leave TPM disabled.

</details>

- <details>
    <summary>Mount-Disk-WSL</summary>

    <a id="mount-disk-wsl"></a>

    Script: [Mount-Disk-WSL.ps1](Mount-Disk-WSL.ps1)

    This script simply mounts a VHD disk in WSL. The script remains open until a key is pressed, which will trigger it to dismount the disk.

</details>

- <details>
    <summary>Select-VMs</summary>

    <a id="select-vms"></a>

    Script: [Select-VMs.psm1](Select-VMs.psm1)

    This is a simple helper that shows all the VMs, and allows the user to choose any number of them.

</details>

- <details>
    <summary>Set-VMValues</summary>

    <a id="set-vmvalues"></a>

    Script: [Set-VMValues.ps1](Set-VMValues.ps1)

    This script will set all the necessary values in the VM, such as disabling checkpoints, disabling dynamic memory, etc...
    Notes:
    - `$EnableTPM` argument, when set to true, won't create a new KeyProtector. Instead it will try to restore the last known good key protector. If it wasn't created before (with [`Create-VM`](#create-vm)), you have to create it either in powershell by running `Set-VMKeyProtector -VMName $VMNAme -NewLocalKeyProtector` or in Hyper-V Manager by enabling TPM in the VM settings.

</details>

- <details>
    <summary>Set-VMValuesAndGPUDrivers</summary>

    <a id="set-vmvaluesandgpudrivers"></a>

    Script: [Set-VMValuesAndGPUDrivers.psq](Set-VMValuesAndGPUDrivers.ps1)

    This script will run both [`Set-VMValues`](#set-vmvalues) and [`Update-VMGpuPartitionDriver`](#update-vmgpupartitiondriver) for every selected VM. You can pass a single VM in the arguments, or pass none and it will use [`Select-VMs`](#select-vms) to select them.

</details>

- <details>
    <summary>Update-VMGpuPartitionDriver</summary>

    <a id="update-vmgpupartitiondriver"></a>

    Script: [Update-VMGpuPartitionDriver.ps1](Update-VMGpuPartitionDriver.ps1)

    This script copies the NVIDIA GPU drivers into the VM, by mounting the disk, copying and then dismounting it. This script was taken from [Easy-GPU-PV](https://github.com/jamesstringerparsec/Easy-GPU-PV).

</details>