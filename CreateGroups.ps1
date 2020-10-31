Param  
(  
    [Parameter (Mandatory = $false)]  
    [object] $WebhookData  
)  
 
Write-Verbose "Runbook started"
#region Part 1

#########################################################################################
#
#       Part 1 - Getting data and token
#
#########################################################################################

#Checking if runbook was started from webhook  
Write-Verbose "Checking if webhookdata is present"
if ($WebhookData) {
    try {
        Write-Verbose "Grabbing webhookdata"
        # Collect properties of WebhookData  
        $WebhookInput = (ConvertFrom-Json -InputObject $WebHookData.RequestBody)
        Write-Verbose "Got webhookdata"        
    }

    catch {
        Write-Verbose "Failed to grab WebhookInput"
        throw "Failed to grab WebhookInput"
    }

}

else {  
    Write-Verbose "Webhookdata is NOT present"
    Write-Error -Message 'Runbook was not started from Webhook' -ErrorAction stop  
} #End if webhookdata

#Getting token from Graph
Write-Verbose "Composing body for token request"
try {
    $ReqTokenBody = @{
        Grant_Type    = "client_credentials"
        Scope         = "https://graph.microsoft.com/.default"
        client_Id     = $WebhookInput.ApplicationID
        Client_Secret = $WebhookInput.ApplicationSecret
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
    $TokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$($WebhookInput.Tenantname)/oauth2/v2.0/token" -Method POST -Body $ReqTokenBody
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

#Creating dynamic group for Intune users
Write-Verbose "Composing body"
$dynamicGroupProperties = @{
    "description" = "All users with active Intune license";
    "displayName" = "IntuneEnabled Users";
    "groupTypes" = @("DynamicMembership");
    "mailEnabled" = $False;
    "mailNickname" = "IntuneEnabledUsers";
    "membershipRule" = "user.assignedPlans -any (assignedPlan.service -eq `"SCO`" -and assignedPlan.capabilityStatus -eq `"Enabled`")";
    "membershipRuleProcessingState" = "On";
    "securityEnabled" = $True
}



Invoke-WebRequest -Headers $headerParams -uri "https://graph.microsoft.com/beta/groups" -Body (ConvertTo-Json $dynamicGroupProperties) -method POST