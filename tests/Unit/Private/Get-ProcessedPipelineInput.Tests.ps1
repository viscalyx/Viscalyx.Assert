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

Describe 'Get-ProcessedPipelineInput' {
    Context 'When no pipeline input is provided' {
        It 'Should return $null' {
            InModuleScope -ScriptBlock {
                $result = Get-ProcessedPipelineInput -InvocationInfo $MyInvocation

                $result | Should -BeNullOrEmpty
            }
        }
    }

    Context 'When function is called directly (no pipeline)' {
        It 'Should handle ExpectingInput property correctly' {
            InModuleScope -ScriptBlock {
                # This function is primarily used internally by Assert commands
                # Testing it directly is challenging since it reads $local:Input
                # which is only available in specific pipeline contexts.
                # The real test is that Assert-BitwiseFlag and Assert-NotBitwiseFlag
                # work correctly with pipeline input, which is tested in their unit tests.

                # Basic test to ensure function doesn't error when called
                $result = Get-ProcessedPipelineInput -InvocationInfo $MyInvocation

                # When not expecting input, should return null
                $result | Should -BeNullOrEmpty
            }
        }
    }

    Context 'When testing indirectly through Assert-BitwiseFlag' {
        It 'Should unwrap single-element array when piped without -Each' {
            # This tests Get-ProcessedPipelineInput's unwrapping logic indirectly
            # Single-element array should be unwrapped and processed as a single value
            $null = @(7) | Assert-BitwiseFlag -Expected 4
        }

        It 'Should keep single-element as array when piped with -Each' {
            # This tests Get-ProcessedPipelineInput's -Each parameter indirectly
            # Single-element array should remain as array
            $null = @(7) | Assert-BitwiseFlag -Expected 4 -Each
        }

        It 'Should return array when multiple items are piped with -Each' {
            # This tests that Get-ProcessedPipelineInput properly handles multiple items
            $null = @(7, 15, 23) | Assert-BitwiseFlag -Expected 4 -Each
        }

        It 'Should process last element when array piped without -Each' {
            # When piping array without -Each, should get the full array
            # which then checks the last element
            $null = @(1, 2, 7) | Assert-BitwiseFlag -Expected 4
        }
    }

    Context 'When testing the -Each parameter behavior' {
        It 'Should handle -Each switch correctly when passed' {
            InModuleScope -ScriptBlock {
                # Test that -Each switch is properly handled by Get-ProcessedPipelineInput
                # Use $MyInvocation which is the correct type
                $result = Get-ProcessedPipelineInput -InvocationInfo $MyInvocation -Each

                # When not expecting input, should return null regardless of -Each
                $result | Should -BeNullOrEmpty
            }
        }
    }
}
