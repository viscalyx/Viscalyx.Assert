[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies has been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies has not been resolved, this will throw an error.
            Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
        }
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
    }
}

BeforeAll {
    $script:dscModuleName = 'Viscalyx.Assert'

    Import-Module -Name $script:dscModuleName

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscModuleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force
}

Describe 'Assert-BlockString' {
    It 'Should pass when Actual and Expected are equal strings' {
        $mockActual = 'Test string'
        $mockExpected = 'Test string'

        { Assert-BlockString -Actual $mockActual -Expected $mockExpected } | Should -Not -Throw
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
        $mockActual = @('1','2')
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

        { & $scriptBlock } | Should -Not -Throw
    }

    It 'Should be able to be called using its alias' {
        $mockExpected = 'Test string'

        $scriptBlock = {
            'Test string' | Should-BeBlockString -Expected $mockExpected
        }

        { & $scriptBlock } | Should -Not -Throw
    }
}
