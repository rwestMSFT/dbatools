$CommandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Write-Host -Object "Running $PSCommandPath" -ForegroundColor Cyan
$global:TestConfig = Get-TestConfig

Describe "$CommandName Unit Tests" -Tag 'UnitTests' {
    Context "Validate parameters" {
        [object[]]$params = (Get-Command $CommandName).Parameters.Keys | Where-Object {$_ -notin ('whatif', 'confirm')}
        [object[]]$knownParameters = 'SqlInstance', 'SqlCredential', 'Database', 'ExcludeDatabase', 'IncludeSystemDBs', 'EnableException'
        $knownParameters += [System.Management.Automation.PSCmdlet]::CommonParameters
        It "Should only contain our specific parameters" {
            (@(Compare-Object -ReferenceObject ($knownParameters | Where-Object {$_}) -DifferenceObject $params).Count ) | Should Be 0
        }
    }
}
<#
    Integration test should appear below and are custom to the command you are writing.
    Read https://github.com/dataplat/dbatools/blob/development/contributing.md#tests
    for more guidence.
#>
Describe "$commandname Integration Tests" -Tags "IntegrationTests" {
    Context "Test Retriving Certificate" {
        BeforeAll {
            $random = Get-Random
            $cert = "dbatoolsci_getcert$random"
            $password = ConvertTo-SecureString -String Get-Random -AsPlainText -Force
            New-DbaDbCertificate -SqlInstance $TestConfig.instance1 -Name $cert -password $password
        }
        AfterAll {
            Get-DbaDbCertificate -SqlInstance $TestConfig.instance1 -Certificate $cert | Remove-DbaDbCertificate -confirm:$false
        }
        $results = Get-DbaDbEncryption -SqlInstance $TestConfig.instance1
        It "Should find a certificate named $cert" {
            ($results.Name -match 'dbatoolsci').Count -gt 0 | Should Be $true
        }
    }
}
