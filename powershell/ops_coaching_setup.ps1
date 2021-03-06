#Download AZCopy
Invoke-WebRequest -Uri 'https://platopsterraform.blob.core.windows.net/osunattended/azcopy.exe' -OutFile 'C:\Windows\System32\azcopy.exe'

#Format the data disk and create partition
Get-Disk | Where partitionstyle -eq 'raw' | Initialize-Disk -PartitionStyle MBR -PassThru | New-Partition -DriveLetter "O" -UseMaximumSize | Format-Volume -FileSystem NTFS -NewFileSystemLabel "OutSystems" -Confirm:$false

#Disable IE Enhanced Security
function Disable-InternetExplorerESC {
    $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
    $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
    Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0 -Force
    Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0 -Force
    Stop-Process -Name Explorer -Force
}
function Disable-UserAccessControl {
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 00000000 -Force
}
Disable-UserAccessControl
Disable-InternetExplorerESC

#Download OutSystems binaries
azcopy copy 'https://platopsterraform.blob.core.windows.net/osfiles' 'C:\Temp' --recursive


