<#
.SYNOPSIS
  Get Microsoft 365 Service health status and post to Teams using webhooks
.DESCRIPTION
  Script to check Microsoft 365 Health status, configured to check last 15 minutes (can be adapted as required). Run as a scheduled task, Azure automation etc.
  Create a webhook in Teams and copy the URI to the variable section below.
  The output will be color coded (can be adapted as required) according to Classification of the entry:
  
  Red = Incident
  Yellow = Advisory
  Green = Resolved (Messages with a value in "End date")
  Replace the variables with your own where feasible
  
  Example doc for registering Azure application for credentials and permissions:
  https://evotec.xyz/preparing-azure-app-registrations-permissions-for-office-365-health-service/
  Disclaimer: This script is offered "as-is" with no warranty. 
  While the script is tested and working in my environment, it is recommended that you test the script
  in a test environment before using in your production environment.
 
.NOTES
  Version:        2.3
  Author:         Einar Asting (einar@thingsinthe.cloud)
  Creation Date:  March 16th 2021
  Purpose/Change: Added more services
.LINK
  https://github.com/einast/PS_M365_scripts
#>

# User defined variables
$ApplicationID = 'a4486318-fcbd-4975-9def-c20deb4cafc7'
$ApplicationKey = '9JsMmjCtjpa6OE4-JK7.35_nVdrkY9Yk.-'
$TenantDomain = 'iiji.id' # Alternatively use DirectoryID if tenant domain fails
$URI = 'https://iiji.webhook.office.com/webhookb2/325d3108-0688-4478-984a-2d559c18dcbc@510e0c10-5ad1-4d73-91ac-8980be07b670/IncomingWebhook/23ebdb0bfff44723a3dd3f89cad3aeac/05df29d8-bc01-43a1-887a-d686b45d7b54'
$Minutes = '15'

# Service(s) to monitor
# Leave the one(s) you DON'T want to check empty (with '' ), add a value in the ones you WANT to check (I added 'yes' for readability

$ExchangeOnline = 'yes'
$MicrosoftForms = ''
$MicrosoftIntune = ''
$MicrosoftKaizala = ''
$SkypeforBusiness = ''
$MicrosoftDefenderATP = ''
$MicrosoftFlow = ''
$FlowinMicrosoft365 = ''
$MicrosoftTeams = 'yes'
$MobileDeviceManagementforOffice365 = ''
$OfficeClientApplications = ''
$Officefortheweb = ''
$OneDriveforBusiness = 'yes'
$IdentityService = ''
$Office365Portal = 'yes'
$OfficeSubscription = ''
$Planner = ''
$PowerApps = ''
$PowerAppsinMicrosoft365 = ''
$PowerBI = ''
$AzureInformationProtection = ''
$SharePointOnline = 'yes'
$MicrosoftStaffHub = ''
$YammerEnterprise = ''
$Microsoft365Suite = ''

# Classification(s) to monitor
# Leave the one(s) you DON'T want to check empty (with '' ), add a value in the ones you WANT to check (I added 'yes' for readability)

$Incident = 'yes'
$Advisory = 'yes'

# Build the Services array            
$ServicesArray = @()            
            
# If Services variables are present, add with 'eq' comparison            
if($ExchangeOnline){$ServicesArray += '$_.WorkloadDisplayName -eq "Exchange Online"'}            
if($MicrosoftForms){$ServicesArray += '$_.WorkloadDisplayName -eq "Microsoft Forms"'}
if($MicrosoftIntune){$ServicesArray += '$_.WorkloadDisplayName -eq "Microsoft Intune"'}
if($MicrosoftKaizala){$ServicesArray += '$_.WorkloadDisplayName -eq "Microsoft Kaizala"'} 
if($SkypeforBusiness){$ServicesArray += '$_.WorkloadDisplayName -eq "Skype for Business"'}
if($MicrosoftDefenderATP){$ServicesArray += '$_.WorkloadDisplayName -eq "Microsoft Defender ATP"'}
if($MicrosoftFlow){$ServicesArray += '$_.WorkloadDisplayName -eq "Microsoft Flow"'}
if($FlowinMicrosoft365){$ServicesArray += '$_.WorkloadDisplayName -eq "Flow in Microsoft 365"'}
if($MicrosoftTeams){$ServicesArray += '$_.WorkloadDisplayName -eq "Microsoft Teams"'}
if($MobileDeviceManagementforOffice365){$ServicesArray += '$_.WorkloadDisplayName -eq "Mobile Device Management for Office 365"'}
if($OfficeClientApplications){$ServicesArray += '$_.WorkloadDisplayName -eq "Office Client Applications"'}
if($Officefortheweb){$ServicesArray += '$_.WorkloadDisplayName -eq "Office for the web"'}
if($OneDriveforBusiness){$ServicesArray += '$_.WorkloadDisplayName -eq "OneDrive for Business"'}
if($IdentityService){$ServicesArray += '$_.WorkloadDisplayName -eq "Identity Service"'}
if($Office365Portal){$ServicesArray += '$_.WorkloadDisplayName -eq "Office 365 Portal"'}
if($OfficeSubscription){$ServicesArray += '$_.WorkloadDisplayName -eq "Office Subscription"'}
if($Planner){$ServicesArray += '$_.WorkloadDisplayName -eq "Planner"'}
if($PowerApps){$ServicesArray += '$_.WorkloadDisplayName -eq "PowerApps"'}
if($PowerAppsinMicrosoft365){$ServicesArray += '$_.WorkloadDisplayName -eq "PowerApps in Microsoft 365"'}
if($PowerBI){$ServicesArray += '$_.WorkloadDisplayName -eq "Power BI"'}
if($AzureInformationProtection){$ServicesArray += '$_.WorkloadDisplayName -eq "Azure Information Protection"'}
if($SharepointOnline){$ServicesArray += '$_.WorkloadDisplayName -eq "Sharepoint Online"'}
if($MicrosoftStaffHub){$ServicesArray += '$_.WorkloadDisplayName -eq "Microsoft StaffHub"'}
if($YammerEnterprise){$ServicesArray += '$_.WorkloadDisplayName -eq "Yammer Enterprise"'}
if($Microsoft365Suite){$ServicesArray += '$_.WorkloadDisplayName -eq "Microsoft 365 Suite"'}

# Build the Services where array into a string and joining each statement with -or     
$ServicesString = $ServicesArray -Join " -or "

# Build the Classification array            
$ClassificationArray = @()            
            
# If Classification variables are present, add with 'eq' comparison            
if($Incident){$ClassificationArray += '$_.Classification -eq "Incident"'}            
if($Advisory){$ClassificationArray += '$_.Classification -eq "Advisory"'}            

# Build the Classification where array into a string and joining each statement with -or            
$ClassificationString = $ClassificationArray -Join " -or "

# Request data
$body = @{
    grant_type="client_credentials";
    resource="https://manage.office.com";
    client_id=$ApplicationID;
    client_secret=$ApplicationKey;
    earliest_time="-$($Minutes)m@s"}

$oauth = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$($tenantdomain)/oauth2/token?api-version=1.0" -Body $body
$headerParams = @{'Authorization'="$($oauth.token_type) $($oauth.access_token)"}
$messages = (Invoke-RestMethod -Uri "https://manage.office.com/api/v1.0/$($tenantdomain)/ServiceComms/Messages" -Headers $headerParams -Method Get)
$incidents = $messages.Value | Where-Object ([scriptblock]::Create($ClassificationString)) | Where-Object ([scriptblock]::Create($ServicesString))

$Now = Get-Date

# Parse data
ForEach ($inc in $incidents){
                
                # Add updates posted last $Minutes
                If (($Now - [datetime]$inc.LastUpdatedTime).TotalMinutes -le $Minutes) {
                
                # Set the color line of the card according to the Classification of the event, or if it has ended
                if ($inc.Classification -eq "Incident" -and $inc.EndTime -eq $null)
                {
                $color = "ff0000" # Red
                }
                else
                    {
                    if ($inc.EndTime -ne $null)
                        {
                        $color = "00cc00" # Green
                        }
                        else
                            {
                            $color = "ffff00" # Yellow
                            }
                        }

# Pick latest message in the message index and convert the text to JSON before generating payload (if not it will fail).
$Message = $inc.Messages.MessageText[$inc.Messages.Count-1] | ConvertTo-Json
  
# Generate payload(s)
$Payload =  @"
{
    "@context": "https://schema.org/extensions",
    "@type": "MessageCard",
    "potentialAction": [
            {
            "@type": "OpenUri",
            "name": "Post INC document",
            "targets": [
                {
                    "os": "default",
                    "uri": "$($inc.PostIncidentDocumentUrl)"
                }
            ]
        },           
    ],
    "sections": [
        {
            "facts": [
                {
                    "name": "Service:",
                    "value": "$($inc.WorkloadDisplayName)"
                },
                {
                    "name": "Status:",
                    "value": "$($inc.Status)"
                },
                {
                    "name": "Severity:",
                    "value": "$($inc.Severity)"
                },
                {
                    "name": "Classification:",
                    "value": "$($inc.Classification)"
                }
            ],
            "text": $($Message)
        }
    ],
    "summary": "$($Inc.Title)",
    "themeColor": "$($color)",
    "title": "$($Inc.Id) - $($Inc.Title)"
}
"@

# If any new posts, add to Teams
Invoke-RestMethod -uri $uri -Method Post -body $Payload -ContentType 'application/json; charset=utf-8'
    }
  }
