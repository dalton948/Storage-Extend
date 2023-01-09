<# Script made by 
 .----------------.  .----------------.  .----------------.  .----------------.  .----------------.  .-----------------.
| .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. |
| |  ________    | || |      __      | || |   _____      | || |  _________   | || |     ____     | || | ____  _____  | |
| | |_   ___ `.  | || |     /  \     | || |  |_   _|     | || | |  _   _  |  | || |   .'    `.   | || ||_   \|_   _| | |
| |   | |   `. \ | || |    / /\ \    | || |    | |       | || | |_/ | | \_|  | || |  /  .--.  \  | || |  |   \ | |   | |
| |   | |    | | | || |   / ____ \   | || |    | |   _   | || |     | |      | || |  | |    | |  | || |  | |\ \| |   | |
| |  _| |___.' / | || | _/ /    \ \_ | || |   _| |__/ |  | || |    _| |_     | || |  \  `--'  /  | || | _| |_\   |_  | |
| | |________.'  | || ||____|  |____|| || |  |________|  | || |   |_____|    | || |   `.____.'   | || ||_____|\____| | |
| |              | || |              | || |              | || |              | || |              | || |              | |
| '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' |
 '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------' 
 let me know if you have any questions
 #>


write-host "

  ____  _                               _____      _                 _ 
 / ___|| |_ ___  _ __ __ _  __ _  ___  | ____|_  _| |_ ___ _ __   __| |
 \___ \| __/ _ \| '__/ _` |/ _` |/ _ \ |  _| \ \/ / __/ _ \ '_ \ / _` |
  ___) | || (_) | | | (_| | (_| |  __/ | |___ >  <| ||  __/ | | | (_| |
 |____/ \__\___/|_|  \__,_|\__, |\___| |_____/_/\_\\__\___|_| |_|\__,_|
                           |___/                                        
"




function diskinfo {    
    if ($disk.Length -eq 1) {
        $diskold = (Invoke-Command -ComputerName $server -ScriptBlock { Get-Volume -DriveLetter $Using:disk -ErrorAction SilentlyContinue }).size
        Write-Host "Drive Letter:" $disk
        Write-Host "Current Drive Size:" ($diskold[0] / 1GB)
        Invoke-Command -ComputerName $Server -ScriptBlock { Update-HostStorageCache }
        $maxsize = (invoke-command -ComputerName $server -ScriptBlock { Get-PartitionSupportedSize -DriveLetter $Using:disk }).sizeMax
        Write-Host "Total Available Space:" ($maxsize[0] / 1GB)
        invoke-command -ComputerName $Server -ScriptBlock { Resize-Partition -DriveLetter  $using:disk -Size $using:maxsize[0] }
        $disknew = (Invoke-Command -ComputerName $server -ScriptBlock { Get-Volume -DriveLetter $Using:disk -ErrorAction SilentlyContinue }).size
        Write-Host "New Current Drive Size:" ($disknew[0] / 1GB)
        if ($diskold -eq $disknew) {
            Write-Host "Drive was not changed, please double check" -ForegroundColor Red
        }
    }
}

Function get-FileName($initialDirectory) {
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null 
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $initialDirectory
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.filename
}

function Menu {
    Write-Host "
    [1] Manually select one server and one drive to extend
    [2] Select a list of servers from a .txt file and specify one drive to extend on all
    [3] Select one server and check all drives for unallocated space  
    [Q] Exit
    "
}


do {
    Menu
    $choice = Read-Host "Please choose an option".Trim()
    #Option 1: Allows you to select one specific server and 1 specific drive to extend automatically.
    if ($choice -eq 1) {
        $msg = '

        Are there any server volumes you wish to extend [y/n]?'.Trim()

        do {
            $response = Read-Host -Prompt $msg.ToLower()
            if ($response -like 'y*') {
                $server = Read-Host -Prompt 'Input name of intended target server'.Trim()
                $disk = Read-Host -Prompt 'Input drive letter without the colon'.Trim()
                #Checks the provided server's OS version and will filter out anything with 2008 as 2008 does not support the correct PS version
                $os = Get-CimInstance -ComputerName $Server Win32_OperatingSystem | Select Caption
                if ($os -like '*2008*') {
                    write-host "This server is Windows 2008 and is unable to support the following commands. Exiting..." -ForegroundColor Red
                    exit
                }
                elseif ($disk.length -eq 1) {                   
                    diskinfo
                }
                else {
                    Write-Host "Please enter the Drive Letter with no colon."
                }
            }
        } until ($response -like 'n*')
    }
    #Option 2: Prompts the user to select a saved .txt file for a list of servers and then select one drive letter to extend on all.
    #EX: C:\temp\serverlist.txt has 10 servers and we need to extend C:\ on each one.
    elseif ($choice -eq 2) {
        $path = Get-FileName
        $serverList = Get-Content -path $path
        $disk = Read-Host -Prompt 'Input drive letter without the colon'.Trim()
        foreach ($Server in $serverList) {
            $os = Get-CimInstance -ComputerName $Server Win32_OperatingSystem | Select Caption
            if ($os -like '*2008*') {
                write-host "This server is Windows 2008 and is unable to support the following commands. Exiting..." -ForegroundColor Red
                exit
            }
            elseif ($disk.length -eq 1) {                       
                diskinfo
            }
            else {
                Write-Host "Please enter the Drive Letter with no colon."
            }
        }


    }
    #Option 3: Allows you to select one Specific server and then it will check each drive on the machine for any drive with available space.
    elseif ($choice -eq 3) {       
        $Server = Read-Host -Prompt 'Input name of intended target server'.Trim()
        $os = Get-CimInstance -ComputerName $Server Win32_OperatingSystem | Select Caption
        
        if ($os -like '*2008*') {
            write-host "This server is Windows 2008 and is unable to support the following commands. Exiting..." -ForegroundColor Red
            exit   
        }
        else {
            Invoke-Command -ComputerName $Server -ScriptBlock { Update-HostStorageCache }
            $disklist = Invoke-Command -ComputerName $Server -ScriptBlock { Get-Volume | Select-Object -ExpandProperty DriveLetter }
            #pulls max value of each volume and then converts it to GB
            foreach ($disk in $disklist) {
                Write-Host "Checking" $disk
                $maxsizedrive = (Invoke-Command -ComputerName $Server -ScriptBlock { Get-PartitionSupportedSize -DriveLetter $Using:disk -ErrorAction SilentlyContinue }).sizeMax
                $currentsizedrive = (Invoke-Command -ComputerName $Server -ScriptBlock { Get-Volume -DriveLetter $Using:disk -ErrorAction SilentlyContinue }).size
                $maxsizeGB = ([math]::Round(($maxsizedrive[0] / 1GB)))
                $currentsizeGB = ([math]::Round($currentsizedrive[0] / 1GB))
                if ($currentsizeGB -lt $maxsizeGB) {
                    if ($currentsizeGB -ne 0) {
                        Write-Host "Drive Letter:" $disk
                        Write-Host "Current Drive Size:" $currentsizeGB
                        Write-Host "Total Drive Size:" $maxsizeGB
                        Invoke-Command -ComputerName $Server -ScriptBlock { Resize-Partition -DriveLetter  $using:disk -Size $using:maxsizedrive }
                        $newcurrentsizedrive = (Invoke-Command -ComputerName $Server -ScriptBlock { Get-Volume -DriveLetter $Using:disk -ErrorAction SilentlyContinue }).size
                        $newcurrentsizeGB = ([math]::Round($newcurrentsizedrive[0] / 1GB))
                        Write-Host "New Current Drive Size:" $newcurrentsizeGB
                        if ($newcurrentsizeGB -eq $currentsizeGB) {
                            Write-Host "Drive was not changed, please double check" -ForegroundColor Red
                        }
                    }
                }
            }
        }
    }
} until ($choice -eq "Q" )




<# NOTES ##################################
#Get-Disk | Where-Object IsOffline –Eq $True
###########################################
    #need to work on offline disks and new drives
    function newPartition {
        invoke-command -cn $server -script { 
            New-Partition -DiskNumber "" -AssignDriveLetter "" -UseMaximumSize
        }
    } #elseifcomeback
        #need to identify what disk is available and then assign letter

    #Find drive and initialize if raw
    Write-Host "Looking for Raw drives"
    $rawdisk = Invoke-Command -cn $server -script {get-disk | where PartitionStyle -eq 'raw' | Select-Object -ExpandProperty Number}
    if ($rawdisk.length -gt 0) {
        Write-Host $rawdisk
        $partstyle = Read-Host "Raw Disks were found, please enter what Partition type these drives will be. GPT or MBR".Trim()
        foreach ($disk in $rawdisk){
             Invoke-Command -cn $server -Script {
                Initialize-Disk $disk -PartitionStyle $partstyle
                }
            }
    }
    #>