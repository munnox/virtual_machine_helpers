# Source <https://docs.microsoft.com/en-us/windows-server/virtualization/hyper-v/deploy/deploying-graphics-devices-using-dda>
#
# Useful external srcipt to find out what can be used <https://github.com/MicrosoftDocs/Virtualization-Documentation/blob/live/hyperv-tools/DiscreteDeviceAssignment/SurveyDDA.ps1>
#
# Author Robert Munnoch

$pnpdevs = Get-PnpDevice | Where-Object {$_.Present -eq $true} | Where-Object {$_.Class -eq "Display"}
# OR
$pnpdevs = Get-PnpDevice | Where-Object {$_.Class -like "*3D*"}

Write-Host $pnpdevs

$pnpdev = $pnpdevs[0]

$name = "DL-Host"

$instanceid = $pnpdev.InstanceId
$locationpath = ($pnpdev | Get-PnpDeviceProperty DEVPKEY_Device_LocationPaths).data[0]

Write-Host $locationpath

# Prepare VM

function initialiseVM {
    param ($name)
    Set-VM -Name $name -AutomaticStopAction TurnOff
    Set-VM -VMName $name -GuestControlledCacheTypes $true

    Set-VM -VMName $name -LowMemoryMappedIoSpace 3GB
    Set-VM -VMName $name -HighMemoryMappedIoSpace 8GB
}

# Disable on local host and attach to VM
function host_to_vm {
    [CmdletBinding()]
    param ($name, $instanceid, $locationpath)
    Disable-PnpDevice -InstanceId $instanceid -Confirm:$false
    Dismount-VmHostAssignableDevice -locationpath $locationpath -force
    Add-VMAssignableDevice -locationpath $locationpath -VMname $name
}


# see the connected devices
$pnp = Get-VMAssignableDevice -VMName $name


# Disable VM and attach to local host
function vm_to_host {
    param ($name, $instanceid, $locationpath)
    Remove-VMAssignableDevice -location $locationpath -vmname $name
    Mount-VMHostAssignableDevice -LocationPath $locationpath
    Enable-PnpDevice -InstanceID $instanceid -Confirm:$false
}


# see the connected devices
Get-VMAssignableDevice -VMName $name