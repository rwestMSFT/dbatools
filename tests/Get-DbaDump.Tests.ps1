$CommandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Write-Host -Object "Running $PSCommandPath" -ForegroundColor Cyan
$global:TestConfig = Get-TestConfig

Describe "$CommandName Unit Tests" -Tag 'UnitTests' {
    Context "Validate parameters" {
        [object[]]$params = (Get-Command $CommandName).Parameters.Keys | Where-Object {$_ -notin ('whatif', 'confirm')}
        [object[]]$knownParameters = 'SqlInstance', 'SqlCredential', 'EnableException'
        $knownParameters += [System.Management.Automation.PSCmdlet]::CommonParameters
        It "Should only contain our specific parameters" {
            (@(Compare-Object -ReferenceObject ($knownParameters | Where-Object {$_}) -DifferenceObject $params).Count ) | Should Be 0
        }
    }
}

# Not sure what is up with appveyor but it does not support this at all
if (-not $env:appveyor) {
    Describe "$commandname Integration Tests" -Tags "IntegrationTests" {
        Context "Testing if memory dump is present" {
            BeforeAll {
                $server = Connect-DbaInstance -SqlInstance $TestConfig.instance1
                $server.Query("DBCC STACKDUMP")
                $server.Query("DBCC STACKDUMP")
            }

            $results = Get-DbaDump -SqlInstance $TestConfig.instance1
            It "finds least one dump" {
                ($results).Count -ge 1 | Should Be $true
            }
        }
    }
}
