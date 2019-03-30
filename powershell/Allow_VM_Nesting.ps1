# Source <https://docs.microsoft.com/en-us/virtualization/hyper-v-on-windows/user-guide/nested-virtualization>
#
# simply allow a VM to have the CPU nested bit.
#
# Author Robert Munnoch

$name = "DL-Host"

Set-VMProcessor -VMName $name -ExposeVirtualizationExtensions $true