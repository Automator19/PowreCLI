[cmdletbinding()]
param
(
    [Parameter(Mandatory = $true)]
    [string]$vCenter,

    [Parameter(Mandatory = $true)]
    [string]$Host
)
$ram = Read-Host "Enter Memory (Total)Size"
$vCPU = Read-Host "Enter Number of CPUs"
$Core = 2 

$powerstate = Get-vm $vmname | select powerstate 


if ($vmname.powerstate -eq "PoweredOn")
{ 
    write-host "Shutting down" $vmname
    Shutdown-VMGuest -vm $vmname
}

#wait for VM to be powered off
do {
    # wait for 5 seconds 
    start-sleep -s  5
    #Check Power status
    $status = $vmname.Powerstate
} until ($status -eq "Powered Off")

elese 
{ write-host  $vmname "already Powered Off" }
 

# Set Memory Size

Write-host (get-date)  ":Setting CPU and Memory" -ForegroundColor Green

$spec = New-object -Type VMWare.vim.Virtualmachineconfigspec -Property @{"NumcoresPerSocket" = $core } 
    ($vmname).ExtensionData.ReconfigvM_Task($spec)
$vmname | Set-VM -MemoryGB $ram -NumCpu $vCPU -Confirm:$false