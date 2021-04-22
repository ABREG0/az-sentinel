#cabrego - 20210412
$PSrequiredVersion = 6.2

write-host "`nCheck if PS was launched as admin..." -ForegroundColor Yellow
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))  
{  
  
  $arguments = $SCRIPT:MyInvocation.MyCommand.Path #"& '" +$myinvocation.mycommand.definition + "'"

  write-host "`ncheck if PS was launched as admin... re-launching the script: `n $($arguments) " -ForegroundColor Red
  Start-Process powershell -Verb runAs -ArgumentList $arguments
  
  Break
} 
 else{
    Write-Host "`nPowerShell was Launched as Admin... " -ForegroundColor Green
 }

 Function Install-PowerShellCore {
$TLS12Protocol = [System.Net.SecurityProtocolType] 'Ssl3 , Tls12'
[System.Net.ServicePointManager]::SecurityProtocol = $TLS12Protocol

   
   $sourceURL = 'https://github.com/PowerShell/PowerShell/releases/download/v7.1.3/PowerShell-7.1.3-win-x64.msi'

   $destination = "$env:TEMP\PowerShell-7.1.3-win-x64.msi"
   
   Invoke-webrequest -uri $sourceURL -outfile $destination
   
   $InstallArg = "/package $($destination) /qb ADD_EXPLORER_CONTEXT_MENU_OPENPOWERSHELL=1 ENABLE_PSREMOTING=1 REGISTER_MANIFEST=1"
   
   Start-Process -FilePath msiexec -ArgumentList $InstallArg -wait # '/x C:\temp\PowerShell-7.1.3-win-x64.msi /uninstall /qf' -Wait
   #msiexec.exe /package $destination /qb ADD_EXPLORER_CONTEXT_MENU_OPENPOWERSHELL=1 ENABLE_PSREMOTING=1 REGISTER_MANIFEST=1

   Remove-Item $destination -Force

}

 Function Test-InstalledPSCore{
   param(
      $PsVersion
   )
   $PSrequiredVersion = $PsVersion
   $PSInstalled = Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -match "PowerShell [6-9]-x" } 
   
   if($null -ne $PSInstalled){

       Write-Host "`n PS core is installed... Checking exact version"
       
       If($PSInstalled.DisplayVersion -ge $PSrequiredVersion){
   
           Write-Host "`n PS core version is greater than $($PSrequiredVersion) required for AzSentinel Module"
           $PSInstalled.DisplayVersion
       }
       return $true 
   } 
    else{
       Write-Host "`n PS core is NOT installed... `n Need to Install PowerShell Core latest version" -ForegroundColor Red
         Return $false 
         
    }
   
}

if(Test-InstalledPSCore -PsVersion 6.2){
   Write-Host "PS Core is installed" -ForegroundColor Green
}
 else{
    Write-Host "Installing PS Core Latest version" -ForegroundColor Red
    Install-PowerShellCore
 }

Write-Host "`nStarting PS version" -ForegroundColor Red
$PSVersionTable.PSVersion

if ($PSVersionTable.PSVersion -lt $PSrequiredVersion)
{
    Write-Host "`nScript was launch from PS ver below $($PSrequiredVersion)... re-launching the script with ps7. `n $($SCRIPT:MyInvocation.MyCommand.Path)" -ForegroundColor Cyan 
    pwsh -f $SCRIPT:MyInvocation.MyCommand.Path

	return
}
 else{

    Write-Host "`nScript was launch from PS Core" -ForegroundColor Cyan 
 }


#& .\Import-azSentinelRules.ps1

Write-Host "`nSleeping for 20 seconds before exiting new admin PS window..."
Start-Sleep -Seconds 20
