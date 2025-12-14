<#
    .SYNOPSIS
        Unit tests for the private function Test-ValueEquality.

    .NOTES
        This file is used to test the private function Test-ValueEquality.
#>

System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Suppressing this rule because Script Analyzer does not understand Pester syntax.')]
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

Describe 'Test-ValueEquality' {
    Context 'When comparing null values' {
        It 'Should return true when both values are null' {
            InModuleScope -ScriptBlock {
                $result = Test-ValueEquality -ActualValue $null -ExpectedValue $null
                $result | Should -BeTrue
            }
        }

        It 'Should return false when actual is null but expected is not' {
            InModuleScope -ScriptBlock {
                $result = Test-ValueEquality -ActualValue $null -ExpectedValue 'test'
                $result | Should -BeFalse
            }
        }

        It 'Should return false when expected is null but actual is not' {
            InModuleScope -ScriptBlock {
                $result = Test-ValueEquality -ActualValue 'test' -ExpectedValue $null
                $result | Should -BeFalse
            }
        }
    }

    Context 'When comparing scalar values' {
        It 'Should return true when strings are equal' {
            InModuleScope -ScriptBlock {
                $result = Test-ValueEquality -ActualValue 'test' -ExpectedValue 'test'
                $result | Should -BeTrue
            }
        }

        It 'Should return false when strings are not equal' {
            InModuleScope -ScriptBlock {
                $result = Test-ValueEquality -ActualValue 'test1' -ExpectedValue 'test2'
                $result | Should -BeFalse
            }
        }

        It 'Should return true when integers are equal' {
            InModuleScope -ScriptBlock {
                $result = Test-ValueEquality -ActualValue 42 -ExpectedValue 42
                $result | Should -BeTrue
            }
        }

        It 'Should return false when integers are not equal' {
            InModuleScope -ScriptBlock {
                $result = Test-ValueEquality -ActualValue 42 -ExpectedValue 43
                $result | Should -BeFalse
            }
        }

        It 'Should return true when booleans are equal' {
            InModuleScope -ScriptBlock {
                $result = Test-ValueEquality -ActualValue $true -ExpectedValue $true
                $result | Should -BeTrue
            }
        }

        It 'Should return false when booleans are not equal' {
            InModuleScope -ScriptBlock {
                $result = Test-ValueEquality -ActualValue $true -ExpectedValue $false
                $result | Should -BeFalse
            }
        }
    }

    Context 'When comparing arrays' {
        It 'Should return true when arrays are equal (same elements in same order)' {
            InModuleScope -ScriptBlock {
                $result = Test-ValueEquality -ActualValue @(1, 2, 3) -ExpectedValue @(1, 2, 3)
                $result | Should -BeTrue
            }
        }

        It 'Should return false when arrays have different elements' {
            InModuleScope -ScriptBlock {
                $result = Test-ValueEquality -ActualValue @(1, 2, 3) -ExpectedValue @(1, 2, 4)
                $result | Should -BeFalse
            }
        }

        It 'Should return false when arrays have different lengths' {
            InModuleScope -ScriptBlock {
                $result = Test-ValueEquality -ActualValue @(1, 2, 3) -ExpectedValue @(1, 2)
                $result | Should -BeFalse
            }
        }

        It 'Should return false when arrays have same elements in different order' {
            InModuleScope -ScriptBlock {
                $result = Test-ValueEquality -ActualValue @(1, 2, 3) -ExpectedValue @(3, 2, 1)
                $result | Should -BeFalse
            }
        }

        It 'Should return true when both arrays are empty' {
            InModuleScope -ScriptBlock {
                $result = Test-ValueEquality -ActualValue @() -ExpectedValue @()
                $result | Should -BeTrue
            }
        }

        It 'Should return true when string arrays are equal' {
            InModuleScope -ScriptBlock {
                $result = Test-ValueEquality -ActualValue @('a', 'b', 'c') -ExpectedValue @('a', 'b', 'c')
                $result | Should -BeTrue
            }
        }
    }

    Context 'When comparing mixed types with type coercion' {
        It 'Should return true when comparing number to string (PowerShell type coercion)' {
            InModuleScope -ScriptBlock {
                # PowerShell's -eq operator allows type coercion
                # Type checking is handled separately by Test-ObjectType
                $result = Test-ValueEquality -ActualValue 123 -ExpectedValue '123'
                $result | Should -BeTrue
            }
        }

        It 'Should return true when comparing different numeric types (PowerShell type coercion)' {
            InModuleScope -ScriptBlock {
                # PowerShell's -eq allows numeric type coercion
                [int]$intValue = 42
                [double]$doubleValue = 42.0
                $result = Test-ValueEquality -ActualValue $intValue -ExpectedValue $doubleValue
                $result | Should -BeTrue
            }
        }

        It 'Should return true when comparing array to scalar (PowerShell behavior)' {
            InModuleScope -ScriptBlock {
                # PowerShell's -eq operator returns matching element when comparing array to scalar
                # @(1) -eq 1 returns 1 (truthy), so this is expected behavior
                $result = Test-ValueEquality -ActualValue @(1) -ExpectedValue 1
                $result | Should -BeTrue
            }
        }
    }

    Context 'When comparing DateTime values' {
        It 'Should return true when DateTime values are equal' {
            InModuleScope -ScriptBlock {
                $date = [System.DateTime]::new(2023, 1, 1, 12, 0, 0)
                $result = Test-ValueEquality -ActualValue $date -ExpectedValue $date
                $result | Should -BeTrue
            }
        }

        It 'Should return false when DateTime values are different' {
            InModuleScope -ScriptBlock {
                $date1 = [System.DateTime]::new(2023, 1, 1, 12, 0, 0)
                $date2 = [System.DateTime]::new(2023, 1, 2, 12, 0, 0)
                $result = Test-ValueEquality -ActualValue $date1 -ExpectedValue $date2
                $result | Should -BeFalse
            }
        }
    }
}
