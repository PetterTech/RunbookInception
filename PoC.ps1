Param  
(  
    [Parameter (Mandatory = $false)]  
    [object] $WebhookData  
)  
 
# If runbook was called from Webhook, WebhookData will not be null.  
if ($WebhookData) {  
    # Collect properties of WebhookData  
    $WebhookName = $WebHookData.WebhookName  
    $WebhookHeaders = $WebHookData.RequestHeader  
    $WebhookBody = $WebHookData.RequestBody  
    $Input = (ConvertFrom-Json -InputObject $WebhookBody)  
}  

else {  
    Write-Error -Message 'Runbook was not started from Webhook' -ErrorAction stop  
} 

#Connecting to tenant
Connect-AzureAD -TenantId $input.TenantID -ApplicationId $input.ApplicationID -CertificateThumbprint $input.Thumbprint

$TenantDetails = Get-AzureADTenantDetail

Write-Output $TenantDetails