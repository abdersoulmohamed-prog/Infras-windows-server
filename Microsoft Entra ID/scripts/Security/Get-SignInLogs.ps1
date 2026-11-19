#requires -Version 7.2

<#
.SYNOPSIS
    Read interactive sign-in logs for a specified period.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [guid]$TenantId,
    [string]$OutputPath,
    [switch]$UseDeviceCode,
    [datetimeoffset]$Since = ([datetimeoffset]::UtcNow.AddDays(-1)),
    [datetimeoffset]$Until = ([datetimeoffset]::UtcNow),
    [switch]$FailuresOnly
)
. (Join-Path $PSScriptRoot '../Common/Connect-Graph.ps1')

$start = $Since.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
$end = $Until.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
if ($Since -ge $Until) { throw 'Since must be earlier than Until.' }
$filter = "createdDateTime ge $start and createdDateTime lt $end"
Connect-LabGraph -TenantId $TenantId -Scopes @('AuditLog.Read.All','Policy.Read.All') -UseDeviceCode:$UseDeviceCode
$uri = 'https://graph.microsoft.com/v1.0/auditLogs/signIns?$filter=' + [uri]::EscapeDataString($filter)
# Raw JSON preserves authentication details and applied CA policy results.
$data = @(
    Get-LabGraphCollection -Uri $uri | Where-Object {
        -not $FailuresOnly -or (
            $null -ne $_['status']['errorCode'] -and $_['status']['errorCode'] -ne 0
        )
    }
)
Write-LabReport -Data $data -OutputPath $OutputPath -Format Json
