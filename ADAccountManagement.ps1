#active users on 60 days
$DaysActive = 60
$time = (Get-Date).Adddays(-($DaysActive))
Get-ADUser -Filter {LastLogonTimeStamp -gt $time -and enabled -eq $true} -Properties LastLogonTimeStamp | select-object Name,@{Name="Time Stamp"; Expression={[DateTime]::FromFileTime($_.lastLogonTimestamp).ToString('yyyy-MM-dd_hh:mm:ss')}} > C:\ad-management\ActiveUser-60days.csv

#inactive users on 60 days
$DaysInactive = 60
$time = (Get-Date).Adddays(-($DaysInactive))
Get-ADUser -Filter {LastLogonTimeStamp -lt $time -and enabled -eq $true} -Properties LastLogonTimeStamp | select-object Name,@{Name="Time Stamp"; Expression={[DateTime]::FromFileTime($_.lastLogonTimestamp).ToString('yyyy-MM-dd_hh:mm:ss')}} > C:\ad-management\InActiveUser-60days.csv

#created users on 60 days
$DateCutOff = (Get-Date).AddDays(-60)
Get-ADUser -Filter * -Properties whenCreated | where {$_.whenCreated -gt $DateCutOff} | FT Name, whenCreated > C:\ad-management\CreatedUser-60days.csv

#disabled users on 60 days
$DaysInactive = 60
$time = (Get-Date).Adddays(-($DaysInactive))
Get-ADUser -Filter {LastLogonTimeStamp -gt $time -and enabled -eq $false} -Properties LastLogonTimeStamp | select-object Name,@{Name="Time Stamp"; Expression={[DateTime]::FromFileTime($_.lastLogonTimestamp).ToString('yyyy-MM-dd_hh:mm:ss')}} > C:\ad-management\DisabledUser-60days.csv



