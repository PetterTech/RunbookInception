Param  
(  
    [Parameter (Mandatory = $false)]  
    [object] $WebhookData  
)  
 
Write-Verbose "Runbook started"

# If runbook was called from Webhook, WebhookData will not be null.  
Write-Verbose "Checking if webhookdata is present"
if ($WebhookData) {  
    Write-Verbose "Grabbing webhookdata"
    # Collect properties of WebhookData  
    $WebhookName = $WebHookData.WebhookName  
    $WebhookHeaders = $WebHookData.RequestHeader  
    $WebhookBody = $WebHookData.RequestBody  
    $Input = (ConvertFrom-Json -InputObject $WebhookBody)  
    Write-Verbose "Got webhookdata"
}  

else {  
    Write-Verbose "Webhookdata is NOT present"
    Write-Error -Message 'Runbook was not started from Webhook' -ErrorAction stop  
} 

#Connecting to tenant
Write-Verbose "Connecting to target tenant"
try {
    Connect-AzureAD -TenantId $input.TenantID -ApplicationId $input.ApplicationID -CertificateThumbprint $input.Thumbprint | Out-Null
    Write-Verbose "Connected to tenant"
}

catch {
    Write-Verbose "Something went wrong"
    Write-Output $error[0]
    throw "I have failed you"
}