#############################################################################################################################################
# Define Parameter , Input value from Pipeline
#Check if the server is windows or linux
# Check if VM is powered on or not
# if vm is powered of break the loop with messsage " VM is already powered off"
# else execute command to restart guest OS
# check if server is  back online use while loop for ping return
# Now check if OS is online and ready for login 
# For Windows check any widnwos service is running , if not back by 15 minutes exist the script with error else display custom message
# For Linux check if any service is running 
# Note: this script should work for only 1 vm. value to to be entered via pipeline
###############################################################################################################################################

param (
    [parameter(Madatory = $true,
        ValueFromPipeline = $true)]
    [String[]]$VMs, 
         
    [Parameter(Mandatory = $true,
        ValueFromPipeline = $true)]
    [string[]]$VCenters
     
    # Passs Multiple Parameters .\Restaart-GuestOS.ps1 -vcenters vcenter01, vcenter02 
)

foreach ($vc in $vcenters) {
            
    $viserver = Connect-VIServer $vc
    if ( $viserver.IsConnected -eq $true ) {
        Write-Host "$vc is now connected" -ForegroundColor Green
    }
    else {
        Write-Host "Error Connecting to $vc " -ForegroundColor Red
        break;
    }
}


foreach ($vm in $vms)
{
          
    if ((get-vm $vm).Powerstate -ne "PoweredOff")
    {
        Write-Host "Initiating Guest OS Restart on $vm" -ForegroundColor Green
        Restart-VMGuest -vm (get-vm $vm) -Confirm:$false
    }

    while ($true) {
        if ((get-vm $vm).summary.guest.toolsrunningstatus -eq "guesttoolsrunning") {
            write-host (get-date) ": Reboot Completed on $vm, Guest OS is Online"
        }

        else {
            write-host (get-date) ": Reboot in Progress, Wating for Guest OS to come back online"
            sleep -Seconds 120
            $count++
        }
        if ( $count -gt 5) {
            Write-host (get-date) ": Taking too long to reboot $vm, Stopping the script now"
            $endloop = $true
            break;
        }

    }
    else 
    {
        Write-Host " $vm is not powered on, Can not Initiate Restart" -ForegroundColor Red
        break;
    }

}
