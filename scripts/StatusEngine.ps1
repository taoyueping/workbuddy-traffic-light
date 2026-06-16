Set-StrictMode -Version Latest

function Get-WorkBuddyHome {
    if ($env:WORKBUDDY_HOME) {
        return $env:WORKBUDDY_HOME
    }

    return (Join-Path $HOME ".workbuddy")
}

function Get-TailJsonLines {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [int64]$MaxBytes = 2097152
    )

    $stream = [System.IO.File]::Open(
        $Path,
        [System.IO.FileMode]::Open,
        [System.IO.FileAccess]::Read,
        [System.IO.FileShare]::ReadWrite
    )

    try {
        $skipPartialLine = $stream.Length -gt $MaxBytes
        if ($skipPartialLine) {
            [void]$stream.Seek(-$MaxBytes, [System.IO.SeekOrigin]::End)
        }

        $reader = [System.IO.StreamReader]::new($stream)
        try {
            if ($skipPartialLine) {
                [void]$reader.ReadLine()
            }

            $lines = [System.Collections.Generic.List[string]]::new()
            while (-not $reader.EndOfStream) {
                $line = $reader.ReadLine()
                if (-not [string]::IsNullOrWhiteSpace($line)) {
                    $lines.Add($line)
                }
            }
            return $lines
        }
        finally {
            $reader.Dispose()
        }
    }
    finally {
        $stream.Dispose()
    }
}

function Test-RequiresApproval {
    param(
        [Parameter(Mandatory)]
        $Payload
    )

    if ($Payload.name -in @("request_user_input", "item/tool/requestUserInput")) {
        return $true
    }

    if (-not $Payload.arguments) {
        return $false
    }

    try {
        $arguments = $Payload.arguments | ConvertFrom-Json
        return $arguments.sandbox_permissions -eq "require_escalated"
    }
    catch {
        return $Payload.arguments -match '"sandbox_permissions"\s*:\s*"require_escalated"'
    }
}

function Get-WorkBuddySessionState {
    param(
        [Parameter(Mandatory)]
        [System.IO.FileInfo]$File
    )

    $active = $false
    $errorState = $false
    $pendingCalls = @{}
    $lastEvent = $File.LastWriteTimeUtc

    foreach ($line in (Get-TailJsonLines -Path $File.FullName)) {
        try {
            $record = $line | ConvertFrom-Json
        }
        catch {
            continue
        }

        if ($record.timestamp) {
            try {
                $lastEvent = [datetime]::Parse($record.timestamp).ToUniversalTime()
            }
            catch {
                # Keep the file timestamp when a record timestamp is malformed.
            }
        }

        if ($record.type -eq "response_item") {
            $payload = $record.payload

            if ($payload.type -eq "message" -and $payload.role -eq "user") {
                $active = $true
                $errorState = $false
                $pendingCalls = @{}
                continue
            }

            if ($payload.type -eq "function_call") {
                if ((Test-RequiresApproval -Payload $payload) -and $payload.call_id) {
                    $pendingCalls[$payload.call_id] = $true
                }
                continue
            }

            if ($payload.type -eq "function_call_output" -and $payload.call_id) {
                [void]$pendingCalls.Remove($payload.call_id)
                continue
            }

            if (
                $payload.type -eq "message" -and
                $payload.role -eq "assistant" -and
                $payload.phase -in @("final", "final_answer")
            ) {
                $active = $false
                $pendingCalls = @{}
                continue
            }
        }

        if ($record.type -eq "event_msg") {
            if ($record.payload.type -eq "task_started") {
                $active = $true
                $errorState = $false
                $pendingCalls = @{}
                continue
            }

            if ($record.payload.type -eq "task_complete") {
                $active = $false
                $pendingCalls = @{}
                continue
            }

            if ($record.payload.type -in @("turn_aborted", "turn_error", "error")) {
                $active = $false
                $errorState = $true
                $pendingCalls = @{}
            }
        }
    }

    [pscustomobject]@{
        Path = $File.FullName
        Detected = $true
        Active = $active
        Approval = $active -and $pendingCalls.Count -gt 0
        Error = $errorState
        LastEvent = $lastEvent
    }
}

function ConvertFrom-UnixMilliseconds {
    param(
        [Parameter(Mandatory)]
        [int64]$Milliseconds
    )

    return [DateTimeOffset]::FromUnixTimeMilliseconds($Milliseconds).UtcDateTime
}

function Get-WorkBuddyNativeSessionState {
    param(
        [Parameter(Mandatory)]
        [System.IO.FileInfo]$File,

        [int]$HeartbeatWindowMinutes = 5
    )

    $lastEvent = $File.LastWriteTimeUtc
    $processActive = $false

    try {
        $session = Get-Content -LiteralPath $File.FullName -Raw | ConvertFrom-Json
    }
    catch {
        return [pscustomobject]@{
            Path = $File.FullName
            Detected = $false
            Active = $false
            Approval = $false
            Error = $true
            LastEvent = $lastEvent
        }
    }

    if ($session.lastHeartbeat) {
        try {
            $lastEvent = ConvertFrom-UnixMilliseconds -Milliseconds ([int64]$session.lastHeartbeat)
        }
        catch {
            # Keep the file timestamp when heartbeat parsing fails.
        }
    }
    elseif ($session.updatedAt) {
        try {
            $lastEvent = ConvertFrom-UnixMilliseconds -Milliseconds ([int64]$session.updatedAt)
        }
        catch {
            # Keep the file timestamp when updatedAt parsing fails.
        }
    }

    if ($session.pid) {
        $processActive = $null -ne (Get-Process -Id ([int]$session.pid) -ErrorAction SilentlyContinue)
    }

    $recentHeartbeat = $lastEvent -ge ([datetime]::UtcNow.AddMinutes(-$HeartbeatWindowMinutes))

    [pscustomobject]@{
        Path = $File.FullName
        Detected = $processActive -or $recentHeartbeat
        Active = $false
        Approval = $false
        Error = -not ($processActive -or $recentHeartbeat)
        LastEvent = $lastEvent
    }
}

function Get-WorkBuddyLogTaskState {
    param(
        [Parameter(Mandatory)]
        [string]$WorkBuddyHome,

        [int]$MaxLogFiles = 10,
        [int]$TaskWindowMinutes = 120
    )

    $logsRoot = Join-Path $WorkBuddyHome "logs"
    if (-not (Test-Path -LiteralPath $logsRoot)) {
        return [pscustomobject]@{
            Detected = $false
            Active = $false
            Approval = $false
            Error = $false
            LastEvent = [datetime]::MinValue
        }
    }

    $latestState = $null
    $latestEvent = [datetime]::MinValue
    $logFiles = @(
        Get-ChildItem -LiteralPath $logsRoot -Filter "*.log" -File -Recurse -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTimeUtc -Descending |
            Select-Object -First $MaxLogFiles
    )

    foreach ($file in $logFiles) {
        foreach ($line in (Get-TailJsonLines -Path $file.FullName)) {
            if ($line -notmatch '\[SessionManager\] task state transition') {
                continue
            }

            $lineState = $null
            if ($line -match '"to"\s*:\s*"([^"]+)"') {
                $lineState = $Matches[1]
            }
            elseif ($line -match '\bto=([A-Za-z_-]+)') {
                $lineState = $Matches[1]
            }

            if (-not $lineState) {
                continue
            }

            $lineEvent = $file.LastWriteTimeUtc
            if ($line -match '^\[(?<timestamp>[^\]]+)\]') {
                try {
                    $lineEvent = [datetime]::Parse($Matches["timestamp"]).ToUniversalTime()
                }
                catch {
                    # Keep the file timestamp when the log timestamp is malformed.
                }
            }

            if ($lineEvent -ge $latestEvent) {
                $latestEvent = $lineEvent
                $latestState = $lineState
            }
        }
    }

    $fresh = $latestEvent -ge ([datetime]::UtcNow.AddMinutes(-$TaskWindowMinutes))
    $active = $fresh -and $latestState -in @("pending", "planning", "working")
    $errorState = $fresh -and $latestState -in @("failed", "error", "aborted", "cancelled", "canceled")

    [pscustomobject]@{
        Detected = $null -ne $latestState
        Active = $active
        Approval = $false
        Error = $errorState
        LastEvent = $latestEvent
    }
}

function Get-WorkBuddyTrafficState {
    param(
        [string]$WorkBuddyHome = (Get-WorkBuddyHome),
        [int]$MaxSessions = 12,
        [int]$ConcurrentWindowMinutes = 3
    )

    $sessionsRoot = Join-Path $WorkBuddyHome "sessions"
    if (-not (Test-Path -LiteralPath $sessionsRoot)) {
        return [pscustomobject]@{
            State = "offline"
            Label = "WorkBuddy not detected"
            ActiveCount = 0
            ApprovalCount = 0
            SessionCount = 0
        }
    }

    $jsonlFiles = @(
        Get-ChildItem -LiteralPath $sessionsRoot -Filter "*.jsonl" -File -Recurse -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTimeUtc -Descending |
            Select-Object -First $MaxSessions
    )
    $nativeFiles = @(
        Get-ChildItem -LiteralPath $sessionsRoot -Filter "*.json" -File -Recurse -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTimeUtc -Descending |
            Select-Object -First $MaxSessions
    )
    $files = @($jsonlFiles + $nativeFiles | Sort-Object LastWriteTimeUtc -Descending | Select-Object -First $MaxSessions)

    if ($files.Count -eq 0) {
        return [pscustomobject]@{
            State = "offline"
            Label = "No WorkBuddy sessions"
            ActiveCount = 0
            ApprovalCount = 0
            SessionCount = 0
        }
    }

    # Old interrupted threads may never contain a final response. Treat only the
    # newest cluster of files as concurrently relevant to the desktop status.
    $newestWrite = $files[0].LastWriteTimeUtc
    $cutoff = $newestWrite.AddMinutes(-$ConcurrentWindowMinutes)
    $relevantFiles = @($files | Where-Object { $_.LastWriteTimeUtc -ge $cutoff })
    $states = @($relevantFiles | ForEach-Object {
        if ($_.Extension -eq ".json") {
            Get-WorkBuddyNativeSessionState -File $_
        }
        else {
            Get-WorkBuddySessionState -File $_
        }
    })
    $logState = Get-WorkBuddyLogTaskState -WorkBuddyHome $WorkBuddyHome
    if ($logState.Detected) {
        $states = @($states + $logState)
    }
    $detectedCount = @($states | Where-Object Detected).Count
    $approvalCount = @($states | Where-Object Approval).Count
    $activeCount = @($states | Where-Object Active).Count
    $errorCount = @($states | Where-Object Error).Count

    if ($detectedCount -eq 0) {
        $state = "offline"
        $label = "WorkBuddy not detected"
    }
    elseif ($approvalCount -gt 0) {
        $state = "approval"
        $label = "Approval needed"
    }
    elseif ($activeCount -gt 0) {
        $state = "working"
        $label = "WorkBuddy working"
    }
    elseif ($errorCount -gt 0) {
        $state = "error"
        $label = "Run ended with error"
    }
    else {
        $state = "complete"
        $label = "WorkBuddy ready"
    }

    return [pscustomobject]@{
        State = $state
        Label = $label
        ActiveCount = $activeCount
        ApprovalCount = $approvalCount
        SessionCount = $states.Count
    }
}
