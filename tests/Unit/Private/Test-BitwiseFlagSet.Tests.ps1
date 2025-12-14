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

Describe 'Test-BitwiseFlagSet' {
    Context 'When flag is set' {
        It 'Should return $true for single flag' {
            InModuleScope -ScriptBlock {
                $result = Test-BitwiseFlagSet -Value 7 -Flag 4

                $result | Should -BeTrue
            }
        }

        It 'Should return $true for multiple flags' {
            InModuleScope -ScriptBlock {
                $result = Test-BitwiseFlagSet -Value 15 -Flag 5

                $result | Should -BeTrue
            }
        }

        It 'Should return $true when all bits match' {
            InModuleScope -ScriptBlock {
                $result = Test-BitwiseFlagSet -Value 7 -Flag 7

                $result | Should -BeTrue
            }
        }
    }

    Context 'When flag is not set' {
        It 'Should return $false when flag is not present' {
            InModuleScope -ScriptBlock {
                $result = Test-BitwiseFlagSet -Value 3 -Flag 4

                $result | Should -BeFalse
            }
        }

        It 'Should return $false when only partial match' {
            InModuleScope -ScriptBlock {
                $result = Test-BitwiseFlagSet -Value 5 -Flag 7

                $result | Should -BeFalse
            }
        }

        It 'Should return $false for zero value' {
            InModuleScope -ScriptBlock {
                $result = Test-BitwiseFlagSet -Value 0 -Flag 1

                $result | Should -BeFalse
            }
        }
    }

    Context 'When working with large values' {
        It 'Should handle Int64 values correctly' {
            InModuleScope -ScriptBlock {
                $largeValue = [Int64]::MaxValue
                $flag = 1

                $result = Test-BitwiseFlagSet -Value $largeValue -Flag $flag

                $result | Should -BeTrue
            }
        }
    }
}
