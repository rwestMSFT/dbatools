﻿function Get-DbaDbMailAccount {
    <#
    .SYNOPSIS
        Gets database mail accounts from SQL Server

    .DESCRIPTION
        Gets database mail accounts from SQL Server

    .PARAMETER SqlInstance
        The SQL Server instance, or instances.

    .PARAMETER SqlCredential
        Login to the target instance using alternative credentials. Windows and SQL Authentication supported. Accepts credential objects (Get-Credential)

    .PARAMETER Account
        Specifies one or more account(s) to get. If unspecified, all accounts will be returned.

    .PARAMETER ExcludeAccount
        Specifies one or more account(s) to exclude.

    .PARAMETER InputObject
        Accepts pipeline input from Get-DbaDbMail
    
    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: databasemail, dbmail, mail
        Website: https://dbatools.io
        Copyright: (C) Chrissy LeMaire, clemaire@gmail.com
        License: MIT https://opensource.org/licenses/MIT

    .LINK
        https://dbatools.io/Get-DbaDbMailAccount

    .EXAMPLE
        Get-DbaDbMailAccount -SqlInstance sql01\sharepoint

        Returns dbmail accounts on sql01\sharepoint

    .EXAMPLE
        Get-DbaDbMailAccount -SqlInstance sql01\sharepoint -Account 'The DBA Team'

        Returns The DBA Team dbmail account from sql01\sharepoint
    
    .EXAMPLE
        Get-DbaDbMailAccount -SqlInstance sql01\sharepoint | Select *

        Returns the dbmail accounts on sql01\sharepoint then return a bunch more columns

    .EXAMPLE
        $servers = "sql2014","sql2016", "sqlcluster\sharepoint"
        $servers | Get-DbaDbMail | Get-DbaDbMailAccount

       Returns the db dbmail accounts for "sql2014","sql2016" and "sqlcluster\sharepoint"

#>
    [CmdletBinding()]
    param (
        [Alias("ServerInstance", "SqlServer")]
        [DbaInstanceParameter[]]$SqlInstance,
        [Alias("Credential")]
        [PSCredential]$SqlCredential,
        [string[]]$Account,
        [string[]]$ExcludeAccount,
        [Parameter(ValueFromPipeline)]
        [Microsoft.SqlServer.Management.Smo.Mail.SqlMail[]]$InputObject,
        [switch]$EnableException
    )
    process {
        foreach ($instance in $SqlInstance) {
            Write-Message -Level Verbose -Message "Connecting to $instance"
            $InputObject += Get-DbaDbMail -SqlInstance $SqlInstance -SqlCredential $SqlCredential
        }
        
        if (-not $InputObject) {
            Stop-Function -Message "No servers to process"
            return
        }
        
        foreach ($mailserver in $InputObject) {
            try {
                $accounts = $mailserver.Accounts
                
                if ($Account) {
                    $accounts = $accounts | Where-Object Name -in $Account
                }
                
                If ($ExcludeAccount) {
                    $accounts = $accounts | Where-Object Name -notin $ExcludeAccount
                    
                }
                
                $accounts | Add-Member -Force -MemberType NoteProperty -Name ComputerName -value $mailserver.ComputerName
                $accounts | Add-Member -Force -MemberType NoteProperty -Name InstanceName -value $mailserver.InstanceName
                $accounts | Add-Member -Force -MemberType NoteProperty -Name SqlInstance -value $mailserver.SqlInstance
                $accounts | Select-DefaultView -Property ComputerName, InstanceName, SqlInstance, ID, Name, DisplayName, Description, EmailAddress, ReplyToAddress, IsBusyAccount, MailServers
            }
            catch {
                Stop-Function -Message "Failure" -ErrorRecord $_ -Continue
            }
        }
    }
}