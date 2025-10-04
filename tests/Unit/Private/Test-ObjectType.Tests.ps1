<#
    .SYNOPSIS
        Unit tests for the private function Test-ObjectType.

    .NOTES
        This file is used to test the private function Test-ObjectType.
#>

[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
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
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
    }
}

BeforeAll {
    $script:dscModuleName = 'Viscalyx.Assert'

    Import-Module -Name $script:dscModuleName -Force -ErrorAction 'Stop'

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

Describe 'Test-ObjectType' {
    Context 'When comparing null values' {
        It 'Should return true when both values are null' {
            InModuleScope -ScriptBlock {
                $result = Test-ObjectType -ActualValue $null -ExpectedValue $null
                $result | Should -BeTrue
            }
        }

        It 'Should return false when actual is null but expected is not' {
            InModuleScope -ScriptBlock {
                $result = Test-ObjectType -ActualValue $null -ExpectedValue 'test'
                $result | Should -BeFalse
            }
        }

        It 'Should return false when expected is null but actual is not' {
            InModuleScope -ScriptBlock {
                $result = Test-ObjectType -ActualValue 'test' -ExpectedValue $null
                $result | Should -BeFalse
            }
        }
    }

    Context 'When comparing same types' {
        It 'Should return true when both are strings' {
            InModuleScope -ScriptBlock {
                $result = Test-ObjectType -ActualValue 'test1' -ExpectedValue 'test2'
                $result | Should -BeTrue
            }
        }

        It 'Should return true when both are integers' {
            InModuleScope -ScriptBlock {
                $result = Test-ObjectType -ActualValue 42 -ExpectedValue 100
                $result | Should -BeTrue
            }
        }

        It 'Should return true when both are booleans' {
            InModuleScope -ScriptBlock {
                $result = Test-ObjectType -ActualValue $true -ExpectedValue $false
                $result | Should -BeTrue
            }
        }

        It 'Should return true when both are arrays' {
            InModuleScope -ScriptBlock {
                $result = Test-ObjectType -ActualValue @(1, 2, 3) -ExpectedValue @(4, 5, 6)
                $result | Should -BeTrue
            }
        }

        It 'Should return true when both are hashtables' {
            InModuleScope -ScriptBlock {
                $result = Test-ObjectType -ActualValue @{Key = 'Value1' } -ExpectedValue @{Key = 'Value2' }
                $result | Should -BeTrue
            }
        }

        It 'Should return true when both are DateTime objects' {
            InModuleScope -ScriptBlock {
                $date1 = [System.DateTime]::new(2023, 1, 1)
                $date2 = [System.DateTime]::new(2023, 12, 31)
                $result = Test-ObjectType -ActualValue $date1 -ExpectedValue $date2
                $result | Should -BeTrue
            }
        }
    }

    Context 'When comparing different types' {
        It 'Should return false when comparing integer to string' {
            InModuleScope -ScriptBlock {
                $result = Test-ObjectType -ActualValue 123 -ExpectedValue '123'
                $result | Should -BeFalse
            }
        }

        It 'Should return false when comparing integer to double' {
            InModuleScope -ScriptBlock {
                [int]$intValue = 42
                [double]$doubleValue = 42.0
                $result = Test-ObjectType -ActualValue $intValue -ExpectedValue $doubleValue
                $result | Should -BeFalse
            }
        }

        It 'Should return false when comparing string to boolean' {
            InModuleScope -ScriptBlock {
                $result = Test-ObjectType -ActualValue 'true' -ExpectedValue $true
                $result | Should -BeFalse
            }
        }

        It 'Should return false when comparing array to scalar' {
            InModuleScope -ScriptBlock {
                $result = Test-ObjectType -ActualValue @(1) -ExpectedValue 1
                $result | Should -BeFalse
            }
        }

        It 'Should return false when comparing hashtable to PSCustomObject' {
            InModuleScope -ScriptBlock {
                $hashtable = @{Name = 'Test' }
                $psobject = [PSCustomObject]@{Name = 'Test' }
                $result = Test-ObjectType -ActualValue $hashtable -ExpectedValue $psobject
                $result | Should -BeFalse
            }
        }
    }

    Context 'When comparing numeric types' {
        It 'Should return false when comparing int32 to int64' {
            InModuleScope -ScriptBlock {
                [int32]$int32Value = 42
                [int64]$int64Value = 42
                $result = Test-ObjectType -ActualValue $int32Value -ExpectedValue $int64Value
                $result | Should -BeFalse
            }
        }

        It 'Should return false when comparing single to double' {
            InModuleScope -ScriptBlock {
                [single]$singleValue = 3.14
                [double]$doubleValue = 3.14
                $result = Test-ObjectType -ActualValue $singleValue -ExpectedValue $doubleValue
                $result | Should -BeFalse
            }
        }

        It 'Should return true when both are the same numeric type' {
            InModuleScope -ScriptBlock {
                [int64]$value1 = 100
                [int64]$value2 = 200
                $result = Test-ObjectType -ActualValue $value1 -ExpectedValue $value2
                $result | Should -BeTrue
            }
        }
    }

    Context 'When handling edge cases' {
        It 'Should return true when both are empty arrays' {
            InModuleScope -ScriptBlock {
                $result = Test-ObjectType -ActualValue @() -ExpectedValue @()
                $result | Should -BeTrue
            }
        }

        It 'Should return true when both are empty strings' {
            InModuleScope -ScriptBlock {
                $result = Test-ObjectType -ActualValue '' -ExpectedValue ''
                $result | Should -BeTrue
            }
        }

        It 'Should return true when comparing identical PSCustomObjects' {
            InModuleScope -ScriptBlock {
                $obj1 = [PSCustomObject]@{Name = 'Test1' }
                $obj2 = [PSCustomObject]@{Name = 'Test2' }
                $result = Test-ObjectType -ActualValue $obj1 -ExpectedValue $obj2
                $result | Should -BeTrue
            }
        }
    }

    Context 'When GetType() fails' {
        It 'Should throw terminating error when actual value GetType() fails' {
            InModuleScope -ScriptBlock {
                # Create a mock object that throws when GetType() is called
                $mockObject = New-MockObject -Type 'System.Object' -Methods @{
                    GetType = {
                        throw 'GetType failed'
                    }
                }

                { Test-ObjectType -ActualValue $mockObject -ExpectedValue 'test' } |
                    Should -Throw -ErrorId 'TOT0001,Test-ObjectType' -ExpectedMessage '*actual*GetType()*-NoTypeCheck*'
            }
        }

        It 'Should throw terminating error when expected value GetType() fails' {
            InModuleScope -ScriptBlock {
                # Create a mock object that throws when GetType() is called
                $mockObject = New-MockObject -Type 'System.Object' -Methods @{
                    GetType = {
                        throw 'GetType failed'
                    }
                }

                { Test-ObjectType -ActualValue 'test' -ExpectedValue $mockObject } |
                    Should -Throw -ErrorId 'TOT0001,Test-ObjectType' -ExpectedMessage '*expected*GetType()*-NoTypeCheck*'
            }
        }
    }
}
