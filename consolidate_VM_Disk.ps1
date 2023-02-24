# Logs
$path = Split-Path -Parent $MyInvocation.MyCommand.Definition
$timestamp = Get-Date -format yyyy.MM
Start-Transcript -Path $path\Disk-Consolidation-$timestamp.txt -append

# Import PowerCLI Module
Get-Module -Name VMware* -ListAvailable | Import-Module

# Set PowerCLI Proxy config to NoProxy
Set-PowerCLIConfiguration -ProxyPolicy NoProxy -Scope Session -confirm:$false | out-Null

#Connect to both vCenter Servers 
Connect-VIServer -server vcenter01, vcenter02 | out-Null

# Run Disk Consolidation
Write-Host "Running Disk Consolidation"
Get-VM | Where-Object {$_.Extensiondata.Runtime.ConsolidationNeeded} |

ForEach-Object {
  $_.ExtensionData.ConsolidateVMDisks_Task()
}

# Disconnect from vCenter Servers
Disconnect-VIServer -server vcenter01, vcenter02 -confirm:$false  
stop-transcript