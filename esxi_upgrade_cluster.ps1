param
(
    [Parameter(Mandatory = $true)]
    [string]$vCenter,

    [Parameter(Mandatory = $true)]
    [string]$cluster
)


begin 
{ # Connect vCenter Server 
    try { connect-viserver $vcenter -ea stop }
    catch {
        $ErrorMessage = $_.exception.Message
        Write-Error $ErrorMessage
        break;
    }
}

process  
{ # Start Process  
    function Enter-MaintenanceMode {               
                                            
        Write-host (get-date) ": Settings $esxi to Maintenance Mode" -foregroundcolor Yellow
        $out = get-vmhost $esxi | set-vmhost -state Maintenance -Confirm:$false -RunAsync
        Start-Sleep -s 10
        $count = 0
 
        while ($true) { # Creating a endless function
            if ((get-vmhost $esxi).ConnectionState -eq "Maintenance") {
                Write-Host (get-date) ": $esxi in Maintenance Mode" -ForegroundColor Green
                break; # break is used to immidiately exist the loop ) 
            }
            else {
                Write-Host ( get-date) ": $esxi Mantenance Task is still running" -ForegroundColor Red
                Start-Sleep -s 120
                $count++
            }
            if ($count -gt 10) { # This condition will check the count 5 * 120 seconds = 600 seconds = 10 Minutes
                Write-Host (get-date) ": Maintenance Task taking too long....quiting!" -ForegroundColor Red
                $endloop = $true
                #break;
                exit
            }
        }
                          
    }      

    function ESXi-Upgrade-Gen8 {
                                                                      
        Write-host (get-date) ": Upgrading ESXi for Gen8 " -ForegroundColor Yellow
        $esxcli = (get-vmhost $esxi) | get-esxcli -v2

        # Remove VIB

        $esxcli.software.vib.remove.Invoke(@{"vibname" = "net-mst" }) 
        $esxcli.software.vib.remove.Invoke(@{"vibname" = "scsi-lpfc820" })
        $esxcli.software.vib.remove.Invoke(@{"vibname" = "amsd" })
        $esxcli.software.vib.remove.Invoke(@{"vibname" = "block-iomemory-vsl" })
        $esxcli.software.vib.remove.Invoke(@{"vibname" = "scsi-qla2xxx" })
        $esxcli.software.vib.remove.Invoke(@{"vibname" = "scsi-qla4xxx" })

        # Upgrade ESXi
                     
        $argsInstall = $esxcli.software.profile.update.createargs()
        $argsInstall.depot = "/path/VMware-ESXi-6.5.0-Update3-14990892-HPE-preGen9-650.U3.9.6.10.1-Dec2019-depot.zip"
        $argsInstall.profile = “HPE-ESXi-6.5.0-Update3-preGen9-650.U3.9.6.10.1”
        $esxcli.software.profile.update.invoke($argsInstall)
        # ref - https://kb.vmware.com/s/article/2008939   
        Write-host (get-date) ": Upgrade Completed.." -ForegroundColor Greenn
    }
    function ESXi-Upgrade-Gen9 {
        Write-host (get-date) ": Upgrading ESXi " -ForegroundColor Yellow
        $esxcli = (get-vmhost $esxi) | get-esxcli -v2

        # Remove VIB

        $esxcli.software.vib.remove.Invoke(@{"vibname" = "net-mst" }) 
        $esxcli.software.vib.remove.Invoke(@{"vibname" = "scsi-lpfc820" })
        $esxcli.software.vib.remove.Invoke(@{"vibname" = "amsd" })
        $esxcli.software.vib.remove.Invoke(@{"vibname" = "ima-be2iscsi" })
        $esxcli.software.vib.remove.Invoke(@{"vibname" = "scsi-be2iscsi" })
        # Upgrade ESXi
                     
        $argsInstall = $esxcli.software.profile.update.createargs()
        $argsInstall.depot = "/path/VMware_ESXi_6.7.0_17700523_HPE_Gen9plus_670.U3.10.7.0.132_May2021_depot.zip"
        $argsInstall.profile = "HPE-ESXi-6.7.0-Update3-Gen9plus-670.U3.10.7.0.132"
        $esxcli.software.profile.update.invoke($argsInstall)
        # ref - https://kb.vmware.com/s/article/2008939   
        Write-host (get-date) ": Upgrade Completed.." -ForegroundColor Green
    }

    function ESXi-Upgrade-Gen10 {
        Write-host (get-date) ": Upgrading ESXi " -ForegroundColor Yellow
        $esxcli = (get-vmhost $esxi) | get-esxcli -v2

        # Remove VIB

        $esxcli.software.vib.remove.Invoke(@{"vibname" = "net-mst" }) 
        $esxcli.software.vib.remove.Invoke(@{"vibname" = "scsi-lpfc820" })
        $esxcli.software.vib.remove.Invoke(@{"vibname" = "amsd" })
        $esxcli.software.vib.remove.Invoke(@{"vibname" = "ima-be2iscsi" })
        $esxcli.software.vib.remove.Invoke(@{"vibname" = "scsi-be2iscsi" })
        # Upgrade ESXi
                     
        $argsInstall = $esxcli.software.profile.update.createargs()
        $argsInstall.depot = "/path/VMware-ESXi-6.7.0-17167734-HPE-Synergy-670.U3.10.6.5.55-Jan2021-depot.zip"
        $argsInstall.profile = "HPE-ESXi-6.7.0-Update3-iso-Synergy-670.U3.10.6.5.55"
        $esxcli.software.profile.update.invoke($argsInstall)
        # ref - https://kb.vmware.com/s/article/2008939   
        Write-host (get-date) ": Upgrade Completed.." -ForegroundColor Green
    }
              
    function Reboot-Host {
                    
        if ( (Get-VMHost $esxi).connectionstate -eq "Maintenance" )
        {
            write-host (get-date) " : Rebooting $esxi" -foregroundcolor Yellow
            Get-VMHost $esxi | Restart-VMHost -Confirm:$false -force | Out-Null
            sleep -s 60


            while ((get-vmhost $esxi).ConnectionState -ne "NotResponding") {
                sleep 10
            }
            $count = 0
            while ($true) {
                  
                if ((get-vmhost $esxi).ConnectionState -eq "Maintenance" ) {
                    Write-Host (get-date) ": $esxi is back online and in maintenance mode" -ForegroundColor Green
                    break;
                }
                else {
                    write-host (get-date) ": Waiting for $esxi to be online " -ForegroundColor Red
                    sleep -Seconds 60
                    $count++
                }
 
                if ($count -gt 20) { 
                    Write-host (Get-date) ":Waited too long for host to come back online. Stopping!" -ForegroundColor Red
                    $endloop = $true
                    #break;
                    exit
                }

            }
        } 
        else {
            Write-Host (get-date) ": $esxi is not in maintenance, cannot reboot!" -foregroundcolor Red
            $Endloop = $true
            #break;
            exit
        } 

    }                                    
     
    function VUM-Update {
                 
        Write-host (get-date) ": Patching $esxi" -ForegroundColor Yellow
        $testCompliance = Get-Inventory -Name $esxi | Test-Compliance
        $baseline = Get-baseline -server $vcenter -targettype Host -baselinetype patch
        $updatetask = Update-Entity -Entity $esxi -server $vcenter -Baseline $baseline -Confirm:$False -runasync
                 
                 
        while ($UpdateTask.PercentComplete -ne 100) {
            Write-Progress -Activity "Patching $esxi " -PercentComplete $UpdateTask.PercentComplete
            Start-Sleep -seconds 10
            $UpdateTask = Get-Task -id $UpdateTask.id
        }
                          
        if ($UpdateTask.State -ne 'Success') { # Check to see if remediation was sucessful
            Write-Host (Get-Date) 'Patch for $esxi was not successful....Stopping the script' -ForegroundColor Red
            exit
        }
                   
        $CheckCompliance = Get-Compliance -Entity $esxi -Baseline $baseline -ea stop
        if ($CheckCompliance.Status -eq 'Compliant') {
            Write-Host (Get-Date) " $esxi is Compliant " -ForegroundColor Green
        }
        else {
            Write-Host (Get-Date) " $esxi is NOT Compliant " -ForegroundColor Red                       
        }
                 
    }

    function Exit-MaintenaneMode {
                                                      
        Write-host (get-date) ": Exiting Maintenance Mode for $esxi" -ForegroundColor Yellow
        $out = get-vmhost $esxi | set-vmhost -state Connected -Confirm:$false -runasync
        Start-Sleep -s 10
        $count = 0

        while ($true) { # Creating a endless function
            if ((get-vmhost $esxi).ConnectionState -eq "Connected") {
                Write-Host (get-date) ": $esxi has exited Maintenance Mode" -ForegroundColor Green
                break; # break is used to immidiately exist the loop ) 
            }

            else {
                Write-Host ( get-date) ": $esxi Exit Mantenance Task is still running" -ForegroundColor White
                Start-Sleep -s 30
                $count++
            }
            if ($count -gt 5) { # This condition will check the count 5 * 120 seconds = 600 seconds = 10 Minutes
                Write-Host (get-date) ": Exit Maintenance Task taking too long....quiting!" -ForegroundColor Red
                $endloop = $true
                #break;
                exit
                                     
            }
                     
        }
                           
    } 

    function Send-email {
        Send-MailMessage -to "uer@email.com" -from esxiupgrade@gbvdcts374.com -Subject "$esxi - Upgrade Completed!" -SmtpServer smtp.server.com
    }


    #$vmhosts = Get-Cluster $cluster | Get-VMHost
    #$vmhosts = Get-Cluster $cluster | Get-VMHost | Select-Object -first 15
    $vmhosts = Get-Cluster $cluster | Get-VMHost | where-object { $_.name -like "hostname" }
    foreach ($esxi in $vmhosts)
    { #start of foreach loop
        $checkhardware = Get-VMHost $esxi | get-view | select-object Name, @{N = "Type"; E = { $_.hardware.systeminfo.model } }
        $checkesxiversion = get-vmhost $esxi | select @{N = 'Version'; E = { "$($_.Version) $($_.build)" } }
        write-host (get-date) : " Harware Info - $($checkhardware.Type) " -ForegroundColor Yellow
        write-host (get-date) : " ESXi Version - $($checkesxiversion.Version) " -ForegroundColor Yellow
                   
        ###########################
        #########ESXi Upgrade######
        ###########################
        if ($checkhardware.type -match "Gen8" -and $checkesxiversion.version -like "*6.0*") {
            Write-host (Get-date) "$esxi is a  Gen8 host with $($checkesxiversion.version) ..Continuing with ESXi upgrade and VUM Update..." -ForegroundColor Green
            #Enter-MaintenanceMode
            #ESXi-Upgrade-Gen8
            #Reboot-Host
            #VUM-Update
            #Exit-MaintenaneMode
            send-email
        }
                 
                 
        elseif ($checkhardware.type -match "Gen9" -and ($checkesxiversion.version -like "*6.0*" -or $checkesxiversion.version -like "*6.5*") ) {
            Write-host (Get-date) "$esxi is a  Gen9 host with $($checkesxiversion.version) ..Continuing with ESXi upgrade and VUM Update..." -ForegroundColor Green
            #Enter-MaintenanceMode
            #ESXi-Upgrade-Gen9
            #Reboot-Host
            #VUM-Update
            #Exit-MaintenaneMode
            send-email
        }

                              
        elseif ($checkhardware.type -match "Gen10" -and ($checkesxiversion.version -like "*6.0*" -or $checkesxiversion.version -like "*6.5*") ) {
            Write-host (Get-date) "$esxi is a  Gen9 host $($checkesxiversion.version) ..Continuing with ESXi upgrade and VUM Update..." -ForegroundColor Green
            #Enter-MaintenanceMode
            #ESXi-Upgrade-Gen10
            #Reboot-Host
            #VUM-Update
            #Exit-MaintenaneMode
            send-email
        }
                  
        else {
            Write-Host (Get-date) : "No ESXi upgrade required for $($esxi) - $($checkesxiversion.Version)" -foregroundcolor Green
            Write-Host (Get-Date) : "Starting VUM Update" -foregroundcolor Yellow
            #VUM-Update
            #Exit-MaintenaneMode
            send-email
        }
                 
                 

    } #end of for eachloop    
               
} # End Process 

end 
{ # Disconnect vCenter Server
    Disconnect-VIServer -Confirm:$false -Force
    Write-Host (get-date) : "Patching for $esxi completed !" -foregroundcolor Green
    Write-Host (get-date) : "Disconnecting from $vcenter  ! " -foregroundcolor Green
}
