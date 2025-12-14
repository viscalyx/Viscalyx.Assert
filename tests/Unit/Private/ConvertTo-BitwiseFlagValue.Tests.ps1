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

Describe 'ConvertTo-BitwiseFlagValue' {
    Context 'When value is null' {
        It 'Should throw an assertion error' {
            InModuleScope -ScriptBlock {
                { ConvertTo-BitwiseFlagValue -Value $null -ParameterName 'Actual' -InvocationInfo $MyInvocation } |
                    Should -Throw -ExpectedMessage '*not to be null*'
            }
        }
    }

    Context 'When value is an integer' {
        It 'Should convert to Int64' {
            InModuleScope -ScriptBlock {
                $result = ConvertTo-BitwiseFlagValue -Value 42 -ParameterName 'Actual' -InvocationInfo $MyInvocation

                $result | Should -BeOfType [System.Int64]
                $result | Should -Be 42
            }
        }
    }

    Context 'When value is an enum' {
        It 'Should convert enum to Int64' {
            InModuleScope -ScriptBlock {
                $enumValue = [System.IO.FileAttributes]::ReadOnly

                $result = ConvertTo-BitwiseFlagValue -Value $enumValue -ParameterName 'Actual' -InvocationInfo $MyInvocation

                $result | Should -BeOfType [System.Int64]
                $result | Should -Be 1
            }
        }
    }

    Context 'When value is not bitwise-compatible' {
        It 'Should throw an assertion error for Actual parameter' {
            InModuleScope -ScriptBlock {
                { ConvertTo-BitwiseFlagValue -Value 'not a number' -ParameterName 'Actual' -InvocationInfo $MyInvocation } |
                    Should -Throw -ExpectedMessage '*Expected the value to be a bitwise-compatible type (integer or enum), but the type was*'
            }
        }

        It 'Should throw an assertion error for Flag parameter with different message' {
            InModuleScope -ScriptBlock {
                { ConvertTo-BitwiseFlagValue -Value 'not a number' -ParameterName 'Flag' -InvocationInfo $MyInvocation } |
                    Should -Throw -ExpectedMessage '*Expected the flag to be a bitwise-compatible type (integer or enum), but the type was*'
            }
        }
    }

    Context 'When Because parameter is provided' {
        It 'Should include Because reason in error message for invalid types' {
            InModuleScope -ScriptBlock {
                { ConvertTo-BitwiseFlagValue -Value 'string' -ParameterName 'Actual' -Because 'test reason' -InvocationInfo $MyInvocation } |
                    Should -Throw -ExpectedMessage '*because test reason*'
            }
        }
    }
}
