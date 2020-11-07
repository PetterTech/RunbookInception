Param (  
    [Parameter(Mandatory = $True)][string]$Tenantname,
    [Parameter(Mandatory = $True)][string]$ApplicationID,
    [Parameter(Mandatory = $True)][string]$ApplicationSecret
)  
 
Write-Verbose "Runbook started"
#region Part 1

#########################################################################################
#
#       Part 1 - Getting data and token
#
#########################################################################################

#Getting token from Graph
Write-Verbose "Composing body for token request"
try {
    $ReqTokenBody = @{
        Grant_Type    = "client_credentials"
        Scope         = "https://graph.microsoft.com/.default"
        client_Id     = $ApplicationID
        Client_Secret = $ApplicationSecret
    }
    Write-Verbose "Body composed"
}

catch {
    Write-Verbose "Failed to compose body"
    Write-Output $Error[0]
    throw "Failed to compose body"
}

Write-Verbose "Invoking rest method to get token from graph"
try {
    $TokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$($Tenantname)/oauth2/v2.0/token" -Method POST -Body $ReqTokenBody
    Write-Verbose "Got token"
}

catch {
    Write-Verbose "Failed to get token"
    Write-Output $Error[0]
    throw "Failed to get token"
}

Write-Verbose "Setting headerParams"
$headerParams = @{
    'Authorization' = "Bearer $($TokenResponse.access_token)"
    'Content-Type' = "application/json"
}

Write-Verbose "Finished with part 1"
#endregion