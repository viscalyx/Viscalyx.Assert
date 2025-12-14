<#
    .SYNOPSIS
        Unit tests for the private function Test-BitwiseCompatible.

    .NOTES
        This file is used to test the private function Test-BitwiseCompatible.
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

Describe 'Test-BitwiseCompatible' {
    Context 'When testing integer types' {
        It 'Should return true for Byte value' {
            InModuleScope -ScriptBlock {
                $value = [System.Byte]42
                $result = Test-BitwiseCompatible -Value $value
                $result | Should -BeTrue
            }
        }

        It 'Should return true for SByte value' {
            InModuleScope -ScriptBlock {
                $value = [System.SByte]-42
                $result = Test-BitwiseCompatible -Value $value
                $result | Should -BeTrue
            }
        }

        It 'Should return true for Int16 value' {
            InModuleScope -ScriptBlock {
                $value = [System.Int16]1000
                $result = Test-BitwiseCompatible -Value $value
                $result | Should -BeTrue
            }
        }

        It 'Should return true for UInt16 value' {
            InModuleScope -ScriptBlock {
                $value = [System.UInt16]60000
                $result = Test-BitwiseCompatible -Value $value
                $result | Should -BeTrue
            }
        }

        It 'Should return true for Int32 value' {
            InModuleScope -ScriptBlock {
                $value = [System.Int32]100000
                $result = Test-BitwiseCompatible -Value $value
                $result | Should -BeTrue
            }
        }

        It 'Should return true for UInt32 value' {
            InModuleScope -ScriptBlock {
                $value = [System.UInt32]3000000000
                $result = Test-BitwiseCompatible -Value $value
                $result | Should -BeTrue
            }
        }

        It 'Should return true for Int64 value' {
            InModuleScope -ScriptBlock {
                $value = [System.Int64]9223372036854775807
                $result = Test-BitwiseCompatible -Value $value
                $result | Should -BeTrue
            }
        }

        It 'Should return true for UInt64 value' {
            InModuleScope -ScriptBlock {
                $value = [System.UInt64]18446744073709551615
                $result = Test-BitwiseCompatible -Value $value
                $result | Should -BeTrue
            }
        }

        It 'Should return true for implicit integer (Int32)' {
            InModuleScope -ScriptBlock {
                $value = 42
                $result = Test-BitwiseCompatible -Value $value
                $result | Should -BeTrue
            }
        }
    }

    Context 'When testing enum types' {
        It 'Should return true for System.IO.FileAttributes enum' {
            InModuleScope -ScriptBlock {
                $value = [System.IO.FileAttributes]::ReadOnly
                $result = Test-BitwiseCompatible -Value $value
                $result | Should -BeTrue
            }
        }

        It 'Should return true for System.DayOfWeek enum' {
            InModuleScope -ScriptBlock {
                $value = [System.DayOfWeek]::Monday
                $result = Test-BitwiseCompatible -Value $value
                $result | Should -BeTrue
            }
        }

        It 'Should return true for combined enum flags' {
            InModuleScope -ScriptBlock {
                $value = [System.IO.FileAttributes]::ReadOnly -bor [System.IO.FileAttributes]::Hidden
                $result = Test-BitwiseCompatible -Value $value
                $result | Should -BeTrue
            }
        }
    }

    Context 'When testing non-compatible types' {
        It 'Should return false for string value' {
            InModuleScope -ScriptBlock {
                $value = 'test'
                $result = Test-BitwiseCompatible -Value $value
                $result | Should -BeFalse
            }
        }

        It 'Should return false for decimal value' {
            InModuleScope -ScriptBlock {
                $value = [System.Decimal]123.45
                $result = Test-BitwiseCompatible -Value $value
                $result | Should -BeFalse
            }
        }

        It 'Should return false for double value' {
            InModuleScope -ScriptBlock {
                $value = [System.Double]123.45
                $result = Test-BitwiseCompatible -Value $value
                $result | Should -BeFalse
            }
        }

        It 'Should return false for float value' {
            InModuleScope -ScriptBlock {
                $value = [System.Single]123.45
                $result = Test-BitwiseCompatible -Value $value
                $result | Should -BeFalse
            }
        }

        It 'Should return false for boolean value' {
            InModuleScope -ScriptBlock {
                $value = $true
                $result = Test-BitwiseCompatible -Value $value
                $result | Should -BeFalse
            }
        }

        It 'Should return false for array' {
            InModuleScope -ScriptBlock {
                $value = @(1, 2, 3)
                $result = Test-BitwiseCompatible -Value $value
                $result | Should -BeFalse
            }
        }

        It 'Should return false for hashtable' {
            InModuleScope -ScriptBlock {
                $value = @{ Key = 'Value' }
                $result = Test-BitwiseCompatible -Value $value
                $result | Should -BeFalse
            }
        }

        It 'Should return false for PSCustomObject' {
            InModuleScope -ScriptBlock {
                $value = [PSCustomObject]@{ Property = 'Value' }
                $result = Test-BitwiseCompatible -Value $value
                $result | Should -BeFalse
            }
        }

        It 'Should return false for DateTime' {
            InModuleScope -ScriptBlock {
                $value = [System.DateTime]::Now
                $result = Test-BitwiseCompatible -Value $value
                $result | Should -BeFalse
            }
        }
    }

    Context 'When testing edge cases' {
        It 'Should return false for null value' {
            InModuleScope -ScriptBlock {
                $value = $null
                $result = Test-BitwiseCompatible -Value $value
                $result | Should -BeFalse
            }
        }

        It 'Should return true for zero value' {
            InModuleScope -ScriptBlock {
                $value = 0
                $result = Test-BitwiseCompatible -Value $value
                $result | Should -BeTrue
            }
        }

        It 'Should return true for negative integer' {
            InModuleScope -ScriptBlock {
                $value = -42
                $result = Test-BitwiseCompatible -Value $value
                $result | Should -BeTrue
            }
        }

        It 'Should return true for maximum Int32 value' {
            InModuleScope -ScriptBlock {
                $value = [System.Int32]::MaxValue
                $result = Test-BitwiseCompatible -Value $value
                $result | Should -BeTrue
            }
        }

        It 'Should return true for minimum Int32 value' {
            InModuleScope -ScriptBlock {
                $value = [System.Int32]::MinValue
                $result = Test-BitwiseCompatible -Value $value
                $result | Should -BeTrue
            }
        }
    }
}
