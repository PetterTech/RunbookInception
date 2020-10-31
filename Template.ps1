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
$TokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$($WebhookInput.Tenantname)/oauth2/v2.0/token" -Method POST -Body $ReqTokenBody

#endregion