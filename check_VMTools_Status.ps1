$vmNames = (Get-Content -Path "C:\temp\vmnames.txt") -join '|'

Get-View -ViewType VirtualMachine -Filter @{'Name' = $vmNames } |

Select Name,

@{N = "HW Version"; E = { $_.Config.version } },

@{N = 'VMware Toos Status'; E = { $_.Guest.ToolsStatus } },

@{N = "VMware Tools version"; E = { $_.Config.Tools.ToolsVersion } }  



#################################################################################
#you can also do it this way 
#################################################################################

param(

    [string[]]$vmname
)

foreach ($vmnames in $vmname)
{

    Get-View -ViewType VirtualMachine -Filter @{'Name' = $vmnames } |

    Select Name,

    @{N = "HW Version"; E = { $_.Config.version } },
    @{N = 'VMware Toos Status'; E = { $_.Guest.ToolsStatus } },
    @{N = "VMware Tools version"; E = { $_.Config.Tools.ToolsVersion } }
	
}