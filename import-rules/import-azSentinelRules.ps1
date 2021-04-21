#cabrego - 20210412

$TenantID = ''
#$RulesFile = ''

write-host "PS version $($psversionTable.psversion)" -ForegroundColor red
    
#check for Azure az module
if($null -eq (Get-InstalledModule -Name az)){
write-host "Installing Azure az module"
Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force -AllowClobber
}

#check for Azure az module
if($null -eq (Get-InstalledModule -Name AzSentinel)){
write-host "Installing Azure AzSentinel module"
Install-Module -Name AzSentinel -Scope CurrentUser -Repository PSGallery -Force -AllowClobber
}
Function Get-FileName {  
    param($initialDirectory)
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null

    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $initialDirectory
    $OpenFileDialog.filter = "All files (*.json)| *.*"
    $OpenFileDialog.ShowDialog() | Out-Null
    
 return $OpenFileDialog.filename
} #end function Get-FileName

#disconnect exiting connections and clearing contexts.
Write-Output "Clearing existing Azure connection `n"
    
Disconnect-AzAccount -ContextName 'MyContext' | Out-Null
    
Write-Output "Clearing existing Azure context `n"
    
get-azcontext -ListAvailable | ForEach-Object{$_ | remove-azcontext -Force -Verbose | Out-Null} #remove all connected content
    
Write-Output "`nClearing of existing connection and context completed. `n"
Try{
    #Connect to tenant with context name and save it to variable
    $ConnectToTentant = Connect-AzAccount -Tenant $TenantID -ContextName 'MyContext' -Force -ErrorAction Stop
        
    #Select subscription to build
    $GetSubscriptions = Get-AzSubscription | Where-Object {($_.state -eq 'enabled') } | Out-GridView -Title "Select Subscription to build" -PassThru 
        
    }
    catch{
        
    Write-Error "Error When trying to connct to tenant...`n tenant ID in this link: https://portal.azure.com/#blade/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/Overview"
        
    $_ ;
        
    Return 
        
    }
#loop through each selected subscription.. 
foreach($GetSubscription in $GetSubscriptions)
{

Try{
	#Set context for subscription being built
	$SubContext = Set-AzContext -Subscription $GetSubscription.id

    Write-Host "`nWorking in Subscription: $($GetSubscription.Name)"

    $LAWs = get-AzOperationalInsightsWorkspace 
    if($null -eq $LAWs){
        Write-Host "No Log Analytics workspace found..." -ForegroundColor red 
    }
    else{
        Write-Host "`nListing Log Analytics workspace" -ForegroundColor Green
           
        Write-host "Importing Azure Sentinel Rules" -ForegroundColor Green
        foreach($LAW in $LAWs){
            $CurrentLoation = Get-Location

            $File = Get-FileName -initialDirectory $CurrentLoation.Drive.Root
    
            Import-AzSentinelAlertRule -WorkspaceName $LAW.Name -SettingsFile $File
        }

    }

 	}
	catch [Exception]{ 

		Write-warning "Error Message: `n$_ "

		$_

		}
		 
} 

