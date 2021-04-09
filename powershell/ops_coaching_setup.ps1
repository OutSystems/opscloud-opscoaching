#Format the data disk and create partition
Get-Disk | Where partitionstyle -eq ‘raw’ | Initialize-Disk -PartitionStyle MBR -PassThru | New-Partition -DriveLetter "O" -UseMaximumSize | Format-Volume -FileSystem NTFS -NewFileSystemLabel “OutSystems” -Confirm:$false
