Function Get-VIScheduledTasks {
    PARAM ( [switch]$Full )
    if ($Full) {
        # Note: When returning the full View of each Scheduled Task, all date times are in UTC
      (Get-View ScheduledTaskManager).ScheduledTask | % { (Get-View $_).Info }
    }
    else {
        # By default, lets only return common headers and convert all date/times to local values
      (Get-View ScheduledTaskManager).ScheduledTask | % { (Get-View $_ -Property Info).Info } |
        Select Name, Description, Enabled, Notification, LastModifiedUser, State, Entity,
        @{N = "EntityName"; E = { (Get-View $_.Entity -Property Name).Name } },
        @{N = "LastModifiedTime"; E = { $_.LastModifiedTime.ToLocalTime() } },
        @{N = "NextRunTime"; E = { $_.NextRunTime.ToLocalTime() } },
        @{N = "PrevRunTime"; E = { $_.LastModifiedTime.ToLocalTime() } },
        @{N = "ActionName"; E = { $_.Action.Name } }
    }
}
    
    
# This next function calls above function, but only returns the tasks whose action is “CreateSnapshot_Task”
    
Function Get-VMScheduledSnapshots {
    Get-VIScheduledTasks | ? { $_.ActionName -eq 'CreateSnapshot_Task' } |
    ft @{N = "VMName"; E = { $_.EntityName } }, Name, NextRunTime, Notification -AutoSize 
}
    
    
# To find all tasks that failed to execute last run
Get-VIScheduledTasks | ? { $_.State -ne 'success' }
    
# To find all snapshots that are not scheduled to run again:
Get-VMScheduledSnapshots | ? { $_.NextRunTime -eq $null }
    
    
# Delete Scheduled task with no next run 
Get-VMScheduledSnapshots | ? { $_.NextRunTime -eq $null } | % { Remove-VIScheduledTask $_.Name }
    
# Get snapshots from specific time
Get-VMScheduledSnapshots | where-object { $_.NextRunTime -like "07/09/2020 22:45:00" } 
    
Get-VIScheduledTasks | where-object { $_.NextRunTime -eq '07/09/2020 01:45:00' } 
    
    
    
    
Get-VMScheduledSnapshots | Select-String '07/09/2020 01:45:00' | ft @{N = "VMName"; E = { $_.EntityName } }, Name, NextRunTime, Notification -AutoSize 