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
                $result = Test-BitwiseFlagSet -Value 7 -Expected 4

                $result | Should -BeTrue
            }
        }

        It 'Should return $true for multiple flags' {
            InModuleScope -ScriptBlock {
                $result = Test-BitwiseFlagSet -Value 15 -Expected 5

                $result | Should -BeTrue
            }
        }

        It 'Should return $true with all bits matching' {
            InModuleScope -ScriptBlock {
                $result = Test-BitwiseFlagSet -Value 7 -Expected 7

                $result | Should -BeTrue
            }
        }
    }

    Context 'When flag is not set' {
        It 'Should return $false with flag not present' {
            InModuleScope -ScriptBlock {
                $result = Test-BitwiseFlagSet -Value 3 -Expected 4

                $result | Should -BeFalse
            }
        }

        It 'Should return $false with only partial match' {
            InModuleScope -ScriptBlock {
                $result = Test-BitwiseFlagSet -Value 5 -Expected 7

                $result | Should -BeFalse
            }
        }

        It 'Should return $false for zero value' {
            InModuleScope -ScriptBlock {
                $result = Test-BitwiseFlagSet -Value 0 -Expected 1

                $result | Should -BeFalse
            }
        }
    }

    Context 'When working with large values' {
        It 'Should handle Int64 values correctly' {
            InModuleScope -ScriptBlock {
                $largeValue = [Int64]::MaxValue
                $flag = 1

                $result = Test-BitwiseFlagSet -Value $largeValue -Expected $flag

                $result | Should -BeTrue
            }
        }
    }

    Context 'When Expected parameter is zero or negative' {
        It 'Should handle Expected value of 0' {
            InModuleScope -ScriptBlock {
                # When Expected is 0, ($Value -band 0) -eq 0 is always true
                $result = Test-BitwiseFlagSet -Value 5 -Expected 0

                $result | Should -BeTrue
            }
        }

        It 'Should handle negative Expected values' {
            InModuleScope -ScriptBlock {
                # Test with -1 (all bits set)
                $result = Test-BitwiseFlagSet -Value 5 -Expected -1

                # 5 -band -1 = 5, and 5 -eq -1 is false
                $result | Should -BeFalse
            }
        }

        It 'Should handle high bit set in Expected (appears as negative)' {
            InModuleScope -ScriptBlock {
                # 0x8000000000000000 is -9223372036854775808 in signed Int64
                $value = [System.Int64]0x8000000000000001
                $expected = [System.Int64]0x8000000000000000

                $result = Test-BitwiseFlagSet -Value $value -Expected $expected

                $result | Should -BeTrue
            }
        }
    }
}
