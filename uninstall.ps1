$TaskName = "FL Studio Rich Presence"

Write-Host ""
Write-Host " Removing FL Studio Rich Presence..." -ForegroundColor Cyan

Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue

Get-WmiObject -Namespace root\subscription -Class __EventFilter            | Where-Object Name -eq "FL_Studio_RPC_Filter"   | Remove-WmiObject -ErrorAction SilentlyContinue
Get-WmiObject -Namespace root\subscription -Class CommandLineEventConsumer | Where-Object Name -eq "FL_Studio_RPC_Consumer" | Remove-WmiObject -ErrorAction SilentlyContinue

Write-Host " [OK] Done." -ForegroundColor Green
Write-Host ""
Read-Host " Press Enter twice to exit"