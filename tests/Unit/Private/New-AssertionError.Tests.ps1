<#
    .SYNOPSIS
        Unit tests for the private function New-AssertionError.

    .NOTES
        This file is used to test the private function New-AssertionError.
#>

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

Describe 'New-AssertionError' {
    Context 'When creating an error without Because parameter' {
        It 'Should create an error record with just the message' {
            InModuleScope -ScriptBlock {
                $message = 'Test error message'

                # Use $MyInvocation from the actual context
                $result = & {
                    param($msg)
                    New-AssertionError -Message $msg -InvocationInfo $MyInvocation
                } -msg $message

                $result | Should -Not -BeNullOrEmpty
                $result.Exception.Message | Should -Match $message
            }
        }
    }

    Context 'When creating an error with Because parameter' {
        It 'Should append the Because clause to the message' {
            InModuleScope -ScriptBlock {
                $message = 'Test error message'
                $because = 'it is required'

                # Use $MyInvocation from the actual context
                $result = & {
                    param($msg, $becauseText)
                    New-AssertionError -Message $msg -Because $becauseText -InvocationInfo $MyInvocation
                } -msg $message -becauseText $because

                $result | Should -Not -BeNullOrEmpty
                $result.Exception.Message | Should -Match 'because it is required'
            }
        }
    }

    Context 'When testing error record type' {
        It 'Should return an ErrorRecord object' {
            InModuleScope -ScriptBlock {
                $message = 'Test error message'

                # Use $MyInvocation from the actual context
                $result = & {
                    param($msg)
                    New-AssertionError -Message $msg -InvocationInfo $MyInvocation
                } -msg $message

                $result | Should -BeOfType [System.Management.Automation.ErrorRecord]
            }
        }
    }
}
