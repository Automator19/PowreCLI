$path = split-path -Parent $MyInvocation.MyCommand.Definition
$newpath = $path + ".\vms.csv"
$csv = @()
$CSV = Import-CSV -Path $newpath


foreach ($line in $csv ) {

    $vmname = $line.vmname

    $vmObj = Get-VM -Name $vmname
    $si = Get-View ServiceInstance
    $scheduledTaskManager = Get-View $si.Content.ScheduledTaskManager
    Get-View -Id $scheduledTaskManager.ScheduledTask |

    where { $vmObj.ExtensionData.MoRef -contains $_.Info.Entity } | % {

        $_.RemoveScheduledTask()

    }

}