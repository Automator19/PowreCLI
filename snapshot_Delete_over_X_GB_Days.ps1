# Logs
$path = Split-Path -Parent $MyInvocation.MyCommand.Definition
$timestamp = Get-Date -format yyyy.MM
Start-Transcript -Path $path\Delete-Snap-$timestamp.txt -append

# Import PowerCLI Module
Get-Module -Name VMware* -ListAvailable | Import-Module

# Set PowerCLI Proxy config to NoProxy
Set-PowerCLIConfiguration -ProxyPolicy NoProxy -Scope Session -confirm:$false | out-Null

#Connect to both vCenter Servers 
Connect-VIServer -server vcenter01, vcenter02 | Out-Null

# List and Remove Snapshots over 200GB
Write-Host "Removing Snapshots over 200GB"
$RemSnap = get-vm | get-snapshot | Select-Object -Property vm,created,sizeGB | Where-object {$_.SizeGB -ge 200}

foreach ($line in $RemSnap)
{
  $vm=$line.vm
  Write-Host "Removing Snapshot for $vm"
  Get-snapshot -vm $vm | Remove-Snapshot -runasync -confirm:$false | Out-Null
}

# List and Remove Snapshots over 4 Days old 

Write-Host "Removing Snapshots over 4 Days old"
get-snapshot -vm * | Where-Object {$_.Created -lt (Get-Date).AddDays(-4)} | Remove-Snapshot -Confirm:$false -runasync

# Disconnect from vCenter Servers
Disconnect-VIServer -server vcenter01, vcenter02 -confirm:$false 
stop-transcript