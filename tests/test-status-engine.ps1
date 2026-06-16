Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "..\scripts\StatusEngine.ps1")

$testRoot = Join-Path $env:TEMP ("workbuddy-traffic-light-test-" + [guid]::NewGuid().ToString("N"))
$sessionDir = Join-Path $testRoot "sessions\2026\06\15"
$sessionFile = Join-Path $sessionDir "rollout-test.jsonl"

function Write-Records {
    param(
        [Parameter(Mandatory)]
        [array]$Records
    )

    $Records |
        ForEach-Object { $_ | ConvertTo-Json -Compress -Depth 12 } |
        Set-Content -LiteralPath $sessionFile -Encoding UTF8
}

function Assert-State {
    param(
        [Parameter(Mandatory)]
        [string]$Expected
    )

    $actual = (Get-WorkBuddyTrafficState -WorkBuddyHome $testRoot -MaxSessions 1).State
    if ($actual -ne $Expected) {
        throw "Expected state '$Expected' but got '$actual'."
    }
}

try {
    [void](New-Item -ItemType Directory -Path $sessionDir -Force)

    $userRecord = @{
        timestamp = "2026-06-15T10:00:00Z"
        type = "response_item"
        payload = @{
            type = "message"
            role = "user"
            content = @()
        }
    }

    Write-Records -Records @($userRecord)
    Assert-State -Expected "working"

    $approvalRecord = @{
        timestamp = "2026-06-15T10:00:01Z"
        type = "response_item"
        payload = @{
            type = "function_call"
            name = "shell_command"
            call_id = "approval-call"
            arguments = '{"sandbox_permissions":"require_escalated"}'
        }
    }

    Write-Records -Records @($userRecord, $approvalRecord)
    Assert-State -Expected "approval"

    $approvalOutput = @{
        timestamp = "2026-06-15T10:00:02Z"
        type = "response_item"
        payload = @{
            type = "function_call_output"
            call_id = "approval-call"
            output = "approved"
        }
    }

    Write-Records -Records @($userRecord, $approvalRecord, $approvalOutput)
    Assert-State -Expected "working"

    $finalRecord = @{
        timestamp = "2026-06-15T10:00:03Z"
        type = "response_item"
        payload = @{
            type = "message"
            role = "assistant"
            phase = "final"
            content = @()
        }
    }

    Write-Records -Records @($userRecord, $approvalRecord, $approvalOutput, $finalRecord)
    Assert-State -Expected "complete"

    $taskStarted = @{
        timestamp = "2026-06-15T10:00:04Z"
        type = "event_msg"
        payload = @{
            type = "task_started"
        }
    }

    Write-Records -Records @($taskStarted)
    Assert-State -Expected "working"

    $finalAnswerRecord = @{
        timestamp = "2026-06-15T10:00:05Z"
        type = "response_item"
        payload = @{
            type = "message"
            role = "assistant"
            phase = "final_answer"
            content = @()
        }
    }

    Write-Records -Records @($taskStarted, $finalAnswerRecord)
    Assert-State -Expected "complete"

    $taskComplete = @{
        timestamp = "2026-06-15T10:00:06Z"
        type = "event_msg"
        payload = @{
            type = "task_complete"
        }
    }

    Write-Records -Records @($taskStarted, $taskComplete)
    Assert-State -Expected "complete"

    Write-Output "Status engine tests passed."
}
finally {
    if (Test-Path -LiteralPath $testRoot) {
        Remove-Item -LiteralPath $testRoot -Recurse -Force
    }
}
