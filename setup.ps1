$ErrorActionPreference = "Stop"
$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$ScriptPath = Join-Path $ScriptDir "fl_rpc.py"
$TaskName   = "FL Studio Rich Presence"

Write-Host ""
Write-Host " FL Studio Rich Presence - Setup" -ForegroundColor Cyan
Write-Host " ================================" -ForegroundColor Cyan
Write-Host ""

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
          ).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host " [!] Not running as Administrator." -ForegroundColor Red
    Read-Host "`n Press Enter to exit"; exit 1
}

Write-Host " [.] Finding Python..."
$pythonwExe = $null

try {
    $raw = & python -c "import sys; print(sys.executable)" 2>$null
    if ($raw -and $raw -notlike "*WindowsApps*") {
        $candidate = Join-Path (Split-Path $raw.Trim()) "pythonw.exe"
        if (Test-Path $candidate) { $pythonwExe = $candidate }
    }
} catch {}

if (-not $pythonwExe) {
    $patterns = @(
        "$env:LOCALAPPDATA\Programs\Python\Python*\pythonw.exe",
        "C:\Python*\pythonw.exe",
        "C:\Program Files\Python*\pythonw.exe",
        "C:\Program Files (x86)\Python*\pythonw.exe"
    )
    foreach ($p in $patterns) {
        $found = Get-Item $p -ErrorAction SilentlyContinue | Sort-Object Name | Select-Object -Last 1
        if ($found) { $pythonwExe = $found.FullName; break }
    }
}

if (-not $pythonwExe) {
    Write-Host " [!] pythonw.exe not found." -ForegroundColor Red
    Write-Host "     Install Python from python.org (not the Microsoft Store)."
    Read-Host "`n Press Enter to exit"; exit 1
}
Write-Host " [OK] pythonw.exe: $pythonwExe" -ForegroundColor Green

if (-not (Test-Path $ScriptPath)) {
    Write-Host " [!] fl_rpc.py not found at: $ScriptPath" -ForegroundColor Red
    Read-Host "`n Press Enter to exit"; exit 1
}

$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

$xmlPath = "$env:TEMP\fl_rpc_task.xml"
$taskXml = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Description>FL Studio Discord Rich Presence</Description>
  </RegistrationInfo>
  <Triggers>
    <LogonTrigger>
      <Enabled>true</Enabled>
      <UserId>$currentUser</UserId>
      <Delay>PT10S</Delay>
    </LogonTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <UserId>$currentUser</UserId>
      <LogonType>InteractiveToken</LogonType>
      <RunLevel>LeastPrivilege</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <ExecutionTimeLimit>PT0S</ExecutionTimeLimit>
    <Hidden>true</Hidden>
    <Enabled>true</Enabled>
  </Settings>
  <Actions>
    <Exec>
      <Command>$pythonwExe</Command>
      <Arguments>"$ScriptPath"</Arguments>
    </Exec>
  </Actions>
</Task>
"@
[System.IO.File]::WriteAllText($xmlPath, $taskXml, [System.Text.Encoding]::Unicode)

Write-Host " [.] Registering scheduled task..."
$ErrorActionPreference = "SilentlyContinue"
schtasks /delete /tn $TaskName /f 2>&1 | Out-Null
$ErrorActionPreference = "Stop"

$result = schtasks /create /tn $TaskName /xml $xmlPath /f 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host " [!] Failed: $result" -ForegroundColor Red
    Read-Host "`n Press Enter twice to exit"; exit 1
}
Remove-Item $xmlPath -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host " [OK] All done!" -ForegroundColor Green
Write-Host ""
Write-Host "  Log out and back in (or reboot) once to activate."
Write-Host "  After that: presence starts automatically every time FL opens."
Write-Host ""
Write-Host "  To remove: run RUN_UNINSTALL.bat as Administrator" -ForegroundColor DarkGray
Write-Host ""
Read-Host " Press Enter to exit"
