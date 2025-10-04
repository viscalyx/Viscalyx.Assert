<#
    .SYNOPSIS
        Unit tests for the private function Test-ObjectHasMethod.

    .NOTES
        This file is used to test the private function Test-ObjectHasMethod.
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

Describe 'Test-ObjectHasMethod' {
    Context 'When testing .NET objects' {
        It 'Should return true when method exists' {
            InModuleScope -ScriptBlock {
                $object = [System.IO.FileInfo]::new('C:\test.txt')
                $result = Test-ObjectHasMethod -InputObject $object -MethodName 'ToString'
                $result | Should -BeTrue
            }
        }

        It 'Should return false when method does not exist' {
            InModuleScope -ScriptBlock {
                $object = [System.IO.FileInfo]::new('C:\test.txt')
                $result = Test-ObjectHasMethod -InputObject $object -MethodName 'NonExistentMethod'
                $result | Should -BeFalse
            }
        }

        It 'Should return true for GetHashCode method' {
            InModuleScope -ScriptBlock {
                $object = [System.DateTime]::Now
                $result = Test-ObjectHasMethod -InputObject $object -MethodName 'GetHashCode'
                $result | Should -BeTrue
            }
        }

        It 'Should return true for Equals method' {
            InModuleScope -ScriptBlock {
                $object = 'TestString'
                $result = Test-ObjectHasMethod -InputObject $object -MethodName 'Equals'
                $result | Should -BeTrue
            }
        }
    }

    Context 'When testing PSCustomObject with ScriptMethod' {
        It 'Should return true when ScriptMethod exists' {
            InModuleScope -ScriptBlock {
                $object = New-Object -TypeName PSObject
                $object | Add-Member -MemberType ScriptMethod -Name 'CustomMethod' -Value { return 'Test' }
                $result = Test-ObjectHasMethod -InputObject $object -MethodName 'CustomMethod'
                $result | Should -BeTrue
            }
        }

        It 'Should return false when ScriptMethod does not exist' {
            InModuleScope -ScriptBlock {
                $object = New-Object -TypeName PSObject
                $object | Add-Member -MemberType ScriptMethod -Name 'CustomMethod' -Value { return 'Test' }
                $result = Test-ObjectHasMethod -InputObject $object -MethodName 'NonExistent'
                $result | Should -BeFalse
            }
        }
    }

    Context 'When testing collections' {
        It 'Should return true for Add method on ArrayList' {
            InModuleScope -ScriptBlock {
                $object = New-Object System.Collections.ArrayList
                $result = Test-ObjectHasMethod -InputObject $object -MethodName 'Add'
                $result | Should -BeTrue
            }
        }

        It 'Should return true for ContainsKey method on Hashtable' {
            InModuleScope -ScriptBlock {
                $object = @{}
                $result = Test-ObjectHasMethod -InputObject $object -MethodName 'ContainsKey'
                $result | Should -BeTrue
            }
        }
    }

    Context 'When testing edge cases' {
        It 'Should handle objects with both instance and static methods' {
            InModuleScope -ScriptBlock {
                $object = [System.DateTime]::Now
                $result = Test-ObjectHasMethod -InputObject $object -MethodName 'ToShortDateString'
                $result | Should -BeTrue
            }
        }

        It 'Should return false for properties that are not methods' {
            InModuleScope -ScriptBlock {
                $object = [PSCustomObject]@{ Name = 'Test' }
                $result = Test-ObjectHasMethod -InputObject $object -MethodName 'Name'
                $result | Should -BeFalse
            }
        }
    }

    Context 'When testing string objects' {
        It 'Should return true for Substring method' {
            InModuleScope -ScriptBlock {
                $object = 'TestString'
                $result = Test-ObjectHasMethod -InputObject $object -MethodName 'Substring'
                $result | Should -BeTrue
            }
        }

        It 'Should return true for ToUpper method' {
            InModuleScope -ScriptBlock {
                $object = 'TestString'
                $result = Test-ObjectHasMethod -InputObject $object -MethodName 'ToUpper'
                $result | Should -BeTrue
            }
        }
    }
}
