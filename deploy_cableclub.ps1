# deploy_cableclub.ps1
param(
    [switch]$UploadOnly,
    [switch]$RestartOnly,
    [switch]$Status
)

$SERVER_IP = "34.61.122.15"
$SERVER_USER = "deewhydeeecks"
$SSH_KEY = "$env:USERPROFILE\.ssh\cable_club_key"
$REMOTE_HOME = "/home/deewhydeeecks"

# List of specific PBS files to copy
$PBS_FILES = @(
    "abilities.txt",
    "abilities_new.txt",
	"moves.txt",
	"moves_new.txt",
	"items.txt",
	"pokemon_server.txt"
)

function Send-Files {
    Write-Host "Uploading Tectonic Cable Club server files..." -ForegroundColor Green
    
    # Upload main server file
    Write-Host "  Uploading cable_club_v19.py..." -ForegroundColor Yellow
    & scp -i $SSH_KEY ".\cable_club_v19.py" "${SERVER_USER}@${SERVER_IP}:${REMOTE_HOME}/"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to upload main server file!" -ForegroundColor Red
        exit 1
    }
    
    # Upload specific PBS files
    Write-Host "  Uploading PBS files..." -ForegroundColor Yellow
    foreach ($file in $PBS_FILES) {
        Write-Host "    Uploading PBS/$file..." -ForegroundColor Gray
        & scp -i $SSH_KEY ".\PBS\$file" "${SERVER_USER}@${SERVER_IP}:${REMOTE_HOME}/PBS/"
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Failed to upload PBS/$file!" -ForegroundColor Red
            exit 1
        }
    }
    
    # Upload OnlinePresets folder
    Write-Host "  Uploading OnlinePresets folder..." -ForegroundColor Yellow
    & scp -i $SSH_KEY -r ".\OnlinePresets" "${SERVER_USER}@${SERVER_IP}:${REMOTE_HOME}/"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to upload OnlinePresets folder!" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "  All files uploaded successfully!" -ForegroundColor Green
}

function Restart-Server {
    Write-Host "Restarting Tectonic Cable Club server..." -ForegroundColor Green
    & ssh -i $SSH_KEY "${SERVER_USER}@${SERVER_IP}" "sudo systemctl restart cableclub"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Restart failed!" -ForegroundColor Red
        exit 1
    }
    Write-Host "Server restarted successfully!" -ForegroundColor Green
}

function Get-ServerStatus {
    Write-Host "Checking Tectonic Cable Club server status..." -ForegroundColor Yellow
    $status = & ssh -i $SSH_KEY "${SERVER_USER}@${SERVER_IP}" "sudo systemctl is-active cableclub"
    
    if ($status -eq "active") {
        Write-Host "Cable Club server is running" -ForegroundColor Green
    } else {
        Write-Host "Cable Club server is not running (Status: $status)" -ForegroundColor Red
    }
    
    # Show recent logs
    Write-Host "Recent logs:" -ForegroundColor Yellow
    & ssh -i $SSH_KEY "${SERVER_USER}@${SERVER_IP}" "sudo journalctl -u cableclub --no-pager -n 5"
}

# Main execution
if ($Status) {
    Get-ServerStatus
} elseif ($RestartOnly) {
    Restart-Server
    Get-ServerStatus
} elseif ($UploadOnly) {
    Send-Files
} else {
    Send-Files
    Restart-Server
    Get-ServerStatus
}