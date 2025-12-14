[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Suppressing this rule because Script Analyzer does not understand Pester syntax.')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies have been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies have not been resolved, this will throw an error.
            Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
        }
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks noop" first.'
    }
}

BeforeAll {
    $script:moduleName = 'Viscalyx.Assert'

    Import-Module -Name $script:moduleName -Force -ErrorAction 'Stop'

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:moduleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:moduleName -All | Remove-Module -Force
}

Describe 'Assert-BlockString' {
    Context 'When validating parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = '__AllParameterSets'
                ExpectedParameters = '[-Expected] <Object> [-Actual] <Object> [-Because <string>] [-Highlight <string>] [-NoHexOutput] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Assert-BlockString').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }

        It 'Should have Expected parameter as mandatory' {
            (Get-Command -Name 'Assert-BlockString').Parameters['Expected'].Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have Actual parameter as mandatory' {
            (Get-Command -Name 'Assert-BlockString').Parameters['Actual'].Attributes.Mandatory | Should -BeTrue
        }
    }

    It 'Should pass when Actual and Expected are equal strings' {
        $mockActual = 'Test string'
        $mockExpected = 'Test string'

        $null = Assert-BlockString -Actual $mockActual -Expected $mockExpected
    }

    It 'Should throw when Actual and Expected are different strings' {
        $mockActual = 'Test string'
        $mockExpected = 'Different string'

        { Assert-BlockString -Actual $mockActual -Expected $mockExpected } | Should -Throw
    }

    It 'Should throw when Actual is not a string' {
        $mockActual = 12345
        $mockExpected = 'Test string'

        { Assert-BlockString -Actual $mockActual -Expected $mockExpected } | Should -Throw
    }

    It 'Should throw when Actual is string array' {
        $mockActual = @('1', '2')
        $mockExpected = 'Test string'

        { Assert-BlockString -Actual $mockActual -Expected $mockExpected } | Should -Throw
    }

    It 'Should include Because message in the error' {
        $mockActual = 'Test string'
        $mockExpected = 'Different string'
        $Because = 'this is a test'

        {
            Assert-BlockString -Actual $mockActual -Expected $mockExpected -Because $Because
        } | Should -Throw -ExpectedMessage '*because this is a test*'
    }

    It 'Should handle pipeline input' {
        $mockExpected = 'Test string'

        $scriptBlock = {
            'Test string' | Assert-BlockString -Expected $mockExpected
        }

        $null = & $scriptBlock
    }

    It 'Should be able to pass empty collection as Expected' {
        $scriptBlock = {
            '' | Assert-BlockString -Expected @()
        }

        $null = & $scriptBlock
    }

    It 'Should be able to pass empty string as Expected' {
        $scriptBlock = {
            '' | Assert-BlockString -Expected ''
        }

        $null = & $scriptBlock
    }

    It 'Should be able to pass empty collection as Actual' {
        $scriptBlock = {
            Assert-BlockString -Actual @() -Expected @()
        }

        $null = & $scriptBlock
    }

    It 'Should be able to pass empty string as Actual' {
        $scriptBlock = {
            Assert-BlockString -Actual '' -Expected ''
        }

        $null = & $scriptBlock
    }

    It 'Should not return any hex output' {
        $mockLongString = 'A' * 70

        $scriptBlock = {
            Assert-BlockString -Actual $mockLongString -Expected $mockLongString -NoHexOutput
        }

        $null = & $scriptBlock
    }

    It 'Should be able to be called using its alias' {
        $mockExpected = 'Test string'

        $scriptBlock = {
            'Test string' | Should-BeBlockString -Expected $mockExpected
        }

        $null = & $scriptBlock
    }

    It 'Should throw the correct error message when Actual is not a string' {
        $mockExpected = 'Test string'

        $scriptBlock = {
            ([Int32] -1) | Should-BeBlockString -Expected $mockExpected
        }

        { & $scriptBlock } | Should -Throw -ExpectedMessage 'The Actual value must be of type string or string`[`], but it was not.'
    }

    It 'Should throw the correct error message when Expected is not a string' {
        $mockActual = 'Test string'

        $scriptBlock = {
            'Test string' | Should-BeBlockString -Expected ([Int32] -1)
        }

        { & $scriptBlock } | Should-Throw -ExceptionMessage 'The Expected value must be of type string or string`[`], but it was not.'
    }
}
