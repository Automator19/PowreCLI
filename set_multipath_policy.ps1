# Import PowerCLI Module
Get-Module -Name VMware* -ListAvailable | Import-Module

# Set PowerCLI Proxy config to NoProxy
Set-PowerCLIConfiguration -ProxyPolicy NoProxy -Scope Session -confirm:$false

#Connect to both vCenter Servers 
Connect-VIServer -server GBVWS-VC001.ad.plc.cwintra.com, GBVWS-VC002.ad.plc.cwintra.com

#Set Multipath Policy

Get-VMHost | Get-ScsiLun -LunType disk | Where { $_.MultipathPolicy -notlike "RoundRobin" } | Where { $_.CapacityGB -ge 100 } | Set-Scsilun -MultiPathPolicy RoundRobin

# Disconnect from vCenter Servers
Disconnect-VIServer -server vcenter01, vcenter02 -confirm:$false