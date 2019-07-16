## vSphere Cluster Services Checker
## Auth. Mike Chartier July 10, 2019
## Rev. 1

## Assign variables // Import modules

# For some reason I need to include the below module path before importing the module each time. Not sure why that variable does not persist.
$env:PSModulePath += $env:PSModulePath + ";C:\Modules"
import-Module VMware.VimAutomation.Core

#$Credential = Get-Credential
$vCenterServers = "vmfivcpr10.fpicore.fpir.pvt", "vmfivcqa10.fpicorelab.fpir.pvt", "vmfivcpr30.fpicore.fpir.pvt", "vmfivcqa30.fpicorelab.fpir.pvt", "vmnwvcpr51.fpicore.fpir.pvt", "hpe-hc-mgmt.fpicore.fpir.pvt"
$ClusterResult = @()
$connectionValidation = @()

## Loop for each vCenter server
foreach ($viServer in $vCenterServers)
    {
    # Connect to vCenter
    Connect-VIServer $viServer -Credential $Credential

    # Validate connection
    $servercheck = $global:DefaultVIServer
    if($servercheck -eq $null) 
        {
        write-host "No connected servers."
        #write-host "Error:" $Error
        $connectionValidation = $connectionValidation =+ $servercheck
        } ## If $serverlist
    else
        {
        ## do nothing
        write-host "Connected!"
        } ## Server check else
            
    # Check Host Cluster DRS / HA
    $Clusters = Get-Cluster | Where-Object Name -ne "BUILD_DNU"
    $ClusterArray = @()
    
    Foreach ($Cluster in $Clusters)
        {
        $ClusterArray += $Cluster
        } # Foreach cluster
    # Check SDRS
    Disconnect-VIServer $viServer -Confirm:$false
    $ClusterResult += $ClusterArray
    #$viServer
    $ClusterArray
    } ## Foreach VI server
    
## Formatting output and sending mail ##

# Collecting relivant information
$ClusterResult | ForEach-Object {
    '{0}: {1}: {2}: {3}' -f $_.name, $_.HAEnabled, $_.DrsEnabled, $_.DrsAutomationLevel | Format-table
    } | ConvertTo-Html

    # Setting variable for email body // information may change day to day
$SubBody = $ClusterResult | Select-Object -Property Name, DrsEnabled, DrsAutomationLevel, HAEnabled | Convertto-html -Fragment

# Gathering attachment
$ClusterResult | Select-Object -Property * | Export-Csv .\vmware\ClusterOutTest.csv -NoTypeInformation

# Structuring mail message
$From = "BEST.Custom.Reports@financialpartners.com"
$To = "FPISystems-BE@financialpartners.com"
$Cc = ""
$Bcc = ""
$Attachment = "C:\scripts\vmware\ClusterOutTest.csv"
$Subject = "Cluster Services Report"
$Body = "
<title>HTML TABLE</title>
<style>BODY{font-family: Arial; font-size: 10pt;}
TABLE{border: 1px solid black; border-collapse: collapse;}
TH{border: 1px solid black; background: #dddddd; padding: 5px; }
TD{border: 1px solid black; padding: 5px; }
</style>
</head><body>
$SubBody 
</body></html>"
#End email body  
$SMTPServer = "mta.fpicore.fpir.pvt"
$SMTPPort = "25"

# Mail report
Send-MailMessage -From $From -to $To -Subject $Subject -Body $Body -SmtpServer $SMTPServer -BodyAsHtml 