# TM-EA AI Trade - Go-Live Readiness Dashboard
param (
    [switch]$Sync = $true,
    [int]$Days = 30
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location (Join-Path $ScriptDir "..")

if ($Sync) {
    python -m ai_trade.reporting.dashboard --sync --days $Days
} else {
    python -m ai_trade.reporting.dashboard
}
