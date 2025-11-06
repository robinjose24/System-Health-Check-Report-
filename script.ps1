# ============================================
# Project: System Health Check Report
# Author: Robin Jose
# Description: Monitors CPU, RAM, Disk, and Network usage.
# Generates an HTML report sends email and also saves it locally.
# ============================================

# ----- System Info -----
$computerName = $env:COMPUTERNAME
$date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# ----- CPU Usage -----
$cpuLoad = Get-Counter '\Processor(_Total)\% Processor Time' | 
    Select-Object -ExpandProperty CounterSamples | 
    Select-Object -ExpandProperty CookedValue
$cpuLoad = [math]::Round($cpuLoad, 2)

# ----- Memory Usage -----
$memory = Get-WmiObject Win32_OperatingSystem
$totalMemory = [math]::Round($memory.TotalVisibleMemorySize / 1MB, 2)
$freeMemory = [math]::Round($memory.FreePhysicalMemory / 1MB, 2)
$usedMemory = [math]::Round($totalMemory - $freeMemory, 2)
$memoryUsagePercent = [math]::Round(($usedMemory / $totalMemory) * 100, 2)

# ----- Disk Usage -----
$diskInfo = Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3" | 
    Select-Object DeviceID,
        @{Name='Total(GB)';Expression={[math]::Round($_.Size / 1GB,2)}},
        @{Name='Free(GB)';Expression={[math]::Round($_.FreeSpace / 1GB,2)}},
        @{Name='Used(GB)';Expression={[math]::Round(($_.Size - $_.FreeSpace) / 1GB,2)}},
        @{Name='Usage(%)';Expression={[math]::Round((($_.Size - $_.FreeSpace) / $_.Size) * 100,2)}}

# ----- Network Usage -----
$networkStats = Get-NetAdapterStatistics | 
    Select-Object Name, ReceivedBytes, SentBytes

# ----- Create HTML Report -----
$reportPath = "C:\SystemHealthReports"
if (!(Test-Path $reportPath)) { New-Item -ItemType Directory -Path $reportPath | Out-Null }

$reportFile = "$reportPath\SystemHealth_$($computerName)_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"

$reportContent = @"
<html>
<head>
<title>System Health Report - $computerName</title>
<style>
body { font-family: Arial; margin: 20px; }
table { border-collapse: collapse; width: 80%; margin-bottom: 20px; }
th, td { border: 1px solid #ccc; padding: 8px; text-align: center; }
th { background-color: #0078D7; color: white; }
h2 { color: #0078D7; }
</style>
</head>
<body>
<h1>System Health Report - $computerName</h1>
<p><b>Generated:</b> $date</p>

<h2>CPU Usage</h2>
<p><b>CPU Load:</b> $cpuLoad %</p>

<h2>Memory Usage</h2>
<p><b>Total Memory:</b> $totalMemory GB</p>
<p><b>Used Memory:</b> $usedMemory GB ($memoryUsagePercent%)</p>

<h2>Disk Usage</h2>
$( $diskInfo | ConvertTo-Html -Fragment )

<h2>Network Statistics</h2>
$( $networkStats | ConvertTo-Html -Fragment )

</body>
</html>
"@

$reportContent | Out-File -FilePath $reportFile -Encoding UTF8

Write-Host "✅ System Health Report generated successfully at: $reportFile" -ForegroundColor Green

# ----- Optional: Send Email (Uncomment if needed) -----
 $smtpServer = "smtp.gmail.com"
 $smtpPort = 587
 $sender = "robinjoserobert2@gmail.com"
 $password = "mgps lpek iatm ltzy"
 $recipient = "robinjoserobert2@gmail.com"
 $subject = "System Health Report - $computerName"
 $body = Get-Content $reportFile -Raw
 Send-MailMessage -From $sender -To $recipient -Subject $subject -Body $body -BodyAsHtml -SmtpServer $smtpServer -Port $smtpPort -UseSsl -Credential (New-Object System.Management.Automation.PSCredential($sender,(ConvertTo-SecureString $password -AsPlainText -Force)))


