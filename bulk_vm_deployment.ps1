##################################
# This script will deploy multiple VMs using a CSV file. 
##################################
# Create a CSV file with below colums and add values as needed. dont leave column emptry if not required enter 0
# os,vmname,viserver,template,cluster,datastore,cpu,core,totalvcpu,ram,disk1,disk2,disk3,disk4,disk5,primaryipaddress,primarysubnet,primaryprefix,primarygateway,primaryvmnetwork,secondaryipaddress,secondarysubnet,secondaryprefix,secondaryvmnetwork,tertiaryipaddress,tertiarysubnet,tertiaryprefix,tertiaryvmnetwork,networkadaptertype,DNS1,DNS2

# Import CSV 

$path = Split-Path -Parent $MyInvocation.MyCommand.Definition
$newpath = $path + ".\VMs.csv"
$csv = @()
$csv = Import-Csv -Path $newpath

# Logs

$timestamp = Get-Date -format yyyy.MM.dd-hh.mm.ss
$logfile = New-Item -path $path\Logs\$timestamp.txt
Start-Transcript -Path $logfile -append

# VMWAre Snap-in

if ((Get-Module -name VMWare.VimAutomation.Core -ErrorAction SilentlyContinue) -eq $null) { Import-Module VMWare.VimAutomation.Core }

# Connect to VI server

$vCenterServers = @("vcenter01", "vcenter02");
Connect-VIServer -server $vCenterServers
Set-PowerCLIConfiguration -ProxyPolicy NoProxy -Scope Session -Confirm:$false | Out-Null
     
     
foreach ( $line in $csv ) {
  
    #Set Variables for VMware Configs
    $viserver = $line.viserver
    $template = $line.template
    $vmname = $line.vmname
    $cluster = $line.cluster
    # $datastore = Get-Datastore -name $line.datastore
    $datastore = $line.datastore
   
    # Set Variables for Hardware Configs
    $cpu = $line.cpu
    $core = $line.core
    $totalvcpu = $line.totalvcpu
    $ram = $line.ram
    $disk1 = $line.disk1
    $disk2 = $line.disk2
    $disk3 = $line.disk3
    $disk4 = $line.disk4
    $disk5 = $line.disk5
  
    # Set Variables for Network Configs
  
    $primaryipaddress = $line.primaryipaddress
    $primarysubnet = $line.primarysubnet
    $primarygateway = $line.primarygateway
    $primaryvmnetwork = $line.primaryvmnetwork
    $secondaryipaddress = $line.secondaryipaddress
    $secondarysubnet = $line.secondarysubnet
    $secondaryvmnetwork = $line.secondaryvmnetwork
    $tertiaryipaddress = $line.tertiaryipaddress
    $tertiarysubnet = $line.tertiarysubnet
    $tertiaryvmnetwork = $line.tertiaryvmnetwork
    $networkadaptertype = $line.networkadaptertype
    $primaryprefix = $line.primaryprefix
    $secondaryprefix = $line.secondaryprefix
    $tertiaryprefix = $line.tertiaryprefix
    $dns1 = $line.DNS1
    $dns2 = $line.DNS2

    # OS
    $os = $line.os

    $exist = get-vm $vmname -ErrorAction SilentlyContinue
    if (!$exist)
    { 
        # Check if VM already exist on vCenter
  
        Write-host (get-date)  ": No VM named $vmname exists..Starting VM Deployment..." -ForegroundColor Green
        start-sleep -Seconds 5
  
        # Clone VM from Template
       
        $Task = New-VM -name $vmname -template $template -resourcepool $cluster -datastore $datastore -server $viserver -ErrorAction Stop -RunAsync
        
        Wait-Task -Task $Task | out-null
        $NewVM = get-vm -name $vmname 

        # Set CPU and Memory 
      
        Write-host (get-date)  ":Setting CPU and Memory" -ForegroundColor Green
        $spec = New-object -Type VMWare.vim.Virtualmachineconfigspec -Property @{"NumcoresPerSocket" = $core } 
        ($NewVM).ExtensionData.ReconfigvM_Task($spec)
        $NewVM | Set-VM -MemoryGB $ram -NumCpu $TotalvCPU -Confirm:$false | Out-Null

        # Additiona;  Disks 
        
        Write-host (get-date)  ":Adding Disks" -ForegroundColor Green
        if ( $disk1 -gt 1 ) { $NewVM | New-Harddisk -CapacityGB $disk1 }  else { Write-host " Disk 1 not required" -ForegroundColor Yellow } 
        if ( $disk2 -gt 1 ) { $NewVM | New-Harddisk -CapacityGB $disk2 }  else { Write-host " Disk 2 not required" -ForegroundColor Yellow } 
        if ( $disk3 -gt 1 ) { $NewVM | New-Harddisk -CapacityGB $disk3 }  else { Write-host  " Disk 3 not required" -ForegroundColor Yellow } 
        if ( $disk4 -gt 1 ) { $NewVM | New-Harddisk -CapacityGB $disk4 }  else { Write-host  " Disk 4 not required" -ForegroundColor Yellow } 
        if ( $disk5 -gt 1 ) { $NewVM | New-Harddisk -CapacityGB $disk5 }  else { Write-host  " Disk 5 not required" -ForegroundColor Yellow } 
        sleep -Seconds 5

        # Add VM Network Adapters                                
       
        write-host (get-date) ": Setting Network Adapters" -ForegroundColor Green
        if ( $primaryvmnetwork -ne '0' ) { New-NetworkAdapter -vm $newvm -NetworkName $primaryvmnetwork -Type $networkadaptertype -StartConnected:$true -Confirm:$false | select Name, MacAddress, NetworkName }
        else { Write-host "Primary VM Network adapter not required" -ForegroundColor Red }

        if ( $secondaryvmnetwork -ne '0') { New-NetworkAdapter -vm $newvm -NetworkName $secondaryvmnetwork -Type $networkadaptertype -StartConnected:$true -Confirm:$false | select Name, MacAddress, NetworkName }
        else { Write-host "Secondary VM Network adapter not required" -ForegroundColor Red }
        
        if ( $tertiaryvmnetwork -ne '0' ) { New-NetworkAdapter -vm $newvm -NetworkName $tertiaryvmnetwork -Type $networkadaptertype -StartConnected:$true -Confirm:$false | select Name, MacAddress, NetworkName }
        else { Write-host "Tertiary VM Network adapter not required" -ForegroundColor Red }
        

        # Power ON VM                              
       
        write-host (get-date) ": Powering ON $NewVM " -ForegroundColor Green
        $changestate = Start-VM $NewVM
        $count = 0
        while ($true) {
            if ((get-vm $NewVM | get-view ).summary.guest.toolsrunningstatus -eq "guesttoolsrunning")
            {
                write-host (get-date) ": $NewVM is now powered on, VM Tools are running" -ForegroundColor Green
                break; 
            }

            else {
                write-host (get-date) ": $NewVM Power on in progress" -ForegroundColor Yellow
                sleep -Seconds 60
                $count++
            }
            if ($count -gt 5) {
                Write-host (get-date) ": Taking too long to power on $NewVM, Stopping the script now" -ForegroundColor Red
                $endloop = $true
                break;
            }

        }

        # Setting IP addresses for the OS

        $vmstate = (get-vm $NewVM | get-view ).summary.guest.toolsrunningstatus -eq "guesttoolsrunning"
        while ($true) {

            # Set Primary IP address


            if ($os -eq 'Windows' -and $primaryvmnetwork -ne '0') {  
                Read-Host -Prompt "Check Server is booted to windows and no VMTools warning present and VMTools are running , Press Any key to Continue"
                write-host (get-date) ": Setting up Primary IP address for Windows VM ($primaryvmnetwork)" 
                Invoke-VMScript -vm $newvm -ScriptText "New-NetIPAddress -interfaceindex (get-netadapter 'ethernet0').ifindex -IPAddress $primaryipaddress -Prefixlength $primaryprefix -defaultgateway $primarygateway" -scripttype powershell -GuestUser "cw_admin" -GuestPassword "bDrvW0z3r3"
                Invoke-VMScript -vm $newvm -ScriptText "set-DnsClientServerAddress -InterfaceIndex (get-netadapter 'ethernet0').ifindex -ServerAddresses ('$dns1','$dns2')" -ScriptType powershell -GuestUser cw_admin -GuestPassword bDrvW0z3r3 
                Invoke-VMScript -vm $newvm -ScriptText "Rename-NetAdapter -name 'ethernet0' -Newname $primaryvmnetwork" -GuestUser cw_admin -GuestPassword bDrvW0z3r3
            }
            elseif ($os -eq 'Linux' -and $primaryvmnetwork -ne '0') {
                Invoke-VMScript -vm $newvm -ScriptText "/home/support/build/scripts/ifcfg.pl -i $primaryipaddress/$primaryprefix -d eth0 -n $primaryvmnetwork -g $primarygateway" -GuestUser root -GuestPassword mde123 -ScriptType bash
            }
   
            else {
                Write-Host "Primary IP address not required" -ForegroundColor Red
            }	
    
            # Set Secondary IP Address

            if ($os -eq 'Windows' -and $secondaryvmnetwork -ne '0') {
                write-host (get-date) ": Setting up Secondary IP address for Windows VM ($secondaryvmnetwork)" 
                Invoke-VMScript -vm $newvm -ScriptText "New-NetIPAddress -interfaceindex (get-netadapter ethernet1).ifindex -IPAddress $secondaryipaddress -Prefixlength $secondaryprefix " -scripttype powershell -GuestUser "cw_admin" -GuestPassword "bDrvW0z3r3"
                Invoke-VMScript -vm $newvm -ScriptText "Rename-NetAdapter -name ethernet1 -Newname $secondaryvmnetwork" -GuestUser cw_admin -GuestPassword bDrvW0z3r3
            }
            elseif ( $os -eq 'linux' -and $secondaryvmnetwork -ne '0') { 
                Invoke-VMScript -vm $newvm -ScriptText "/home/support/build/scripts/ifcfg.pl -i $secondaryipaddress/$secondaryprefix -d eth1 -n $secondaryvmnetwork" -GuestUser root -GuestPassword mde123 -ScriptType bash
            }
            else {
                Write-Host "Secondary IP address not required" -ForegroundColor Red
            }	 
        
            # Set Tertiary IP Address

            if ( $os -eq 'Windows' -and $tertiaryvmnetwork -ne '0') {
                write-host (get-date) ": Setting up Tertiery IP address for Windows VM ($tertiaryvmnetwork)" 
                Invoke-VMScript -vm $newvm -ScriptText "New-NetIPAddress -interfaceindex (get-netadapter ethernet2).ifindex -IPAddress $tertiaryipaddress -Prefixlength $tertiaryprefix " -scripttype powershell -GuestUser "cw_admin" -GuestPassword "bDrvW0z3r3"
                Invoke-VMScript -vm $newvm -ScriptText "Rename-NetAdapter -name ethernet2 -Newname $tertiaryvmnetwork" -GuestUser cw_admin -GuestPassword bDrvW0z3r3
            }

            elseif ( $os -eq 'linux' -and $tertiaryvmnetwork -ne '0') {
                Invoke-VMScript -vm $newvm -ScriptText "/home/support/build/scripts/ifcfg.pl -i $tertiaryipaddress/$tertiaryprefix -d eth2 -n $tertiaryvmnetwork" -GuestUser root -GuestPassword mde123 -ScriptType bash 
            }
            else {
                Write-Host "Tertiary IP address not required" -ForegroundColor Red    
            }

      

            # Set Hostname and Reboot - Only for Linux OS
      
            if ( $os -eq 'linux') {
                Start-Sleep -s 10
                Invoke-VMScript -vm $newvm -ScriptText "hostnamectl set-hostname $newvm" -GuestUser root -GuestPassword mde123 -ScriptType bash
                Start-sleep -s 5
                Get-VM $NewVM | Restart-VMGuest -Confirm:$false | Out-Null
                Write-host "Initiating Guest Reboot of $newvm" -ForegroundColor Yellow
                start-sleep -s 5
                Write-host "$newvm Deployment Completed!!!" -ForegroundColor Green 
            } 

            else { write-host "OS is not Linux!!!" }
            break;
        }

                  
    }
 
    else {
        Write-Host "*****************************************************************" -ForegroundColor Yellow
        Write-host "Can not start the deployment. $vmname already exist. Exiting!!!" -ForegroundColor Yellow
        Write-Host "*****************************************************************" -ForegroundColor Yellow
        #break; 
    }

}

# Disconnect VIServers
Disconnect-VIserver -server $vCenterServers -Force -confirm:$false
stop-transcript