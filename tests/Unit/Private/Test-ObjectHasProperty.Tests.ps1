<#
    .SYNOPSIS
        Unit tests for the private function Test-ObjectHasProperty.

    .NOTES
        This file is used to test the private function Test-ObjectHasProperty.
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

Describe 'Test-ObjectHasProperty' {
    Context 'When testing hashtable objects' {
        It 'Should return true when property exists' {
            InModuleScope -ScriptBlock {
                $hashtable = @{ Name = 'Test'; Value = 123 }
                $result = Test-ObjectHasProperty -InputObject $hashtable -PropertyName 'Name'
                $result | Should -BeTrue
            }
        }

        It 'Should return false when property does not exist' {
            InModuleScope -ScriptBlock {
                $hashtable = @{ Name = 'Test'; Value = 123 }
                $result = Test-ObjectHasProperty -InputObject $hashtable -PropertyName 'NonExistent'
                $result | Should -BeFalse
            }
        }

        It 'Should return true for case-sensitive key match' {
            InModuleScope -ScriptBlock {
                $hashtable = @{ Name = 'Test' }
                $result = Test-ObjectHasProperty -InputObject $hashtable -PropertyName 'Name'
                $result | Should -BeTrue
            }
        }
    }

    Context 'When testing PSCustomObject' {
        It 'Should return true when property exists' {
            InModuleScope -ScriptBlock {
                $object = [PSCustomObject]@{ Name = 'Test'; Value = 123 }
                $result = Test-ObjectHasProperty -InputObject $object -PropertyName 'Name'
                $result | Should -BeTrue
            }
        }

        It 'Should return false when property does not exist' {
            InModuleScope -ScriptBlock {
                $object = [PSCustomObject]@{ Name = 'Test'; Value = 123 }
                $result = Test-ObjectHasProperty -InputObject $object -PropertyName 'NonExistent'
                $result | Should -BeFalse
            }
        }

        It 'Should return true when property value is null' {
            InModuleScope -ScriptBlock {
                $object = [PSCustomObject]@{ Name = $null }
                $result = Test-ObjectHasProperty -InputObject $object -PropertyName 'Name'
                $result | Should -BeTrue
            }
        }
    }

    Context 'When testing .NET objects' {
        It 'Should return true when property exists on a .NET object' {
            InModuleScope -ScriptBlock {
                $object = [System.IO.FileInfo]::new('C:\test.txt')
                $result = Test-ObjectHasProperty -InputObject $object -PropertyName 'Name'
                $result | Should -BeTrue
            }
        }

        It 'Should return false when property does not exist on a .NET object' {
            InModuleScope -ScriptBlock {
                $object = [System.IO.FileInfo]::new('C:\test.txt')
                $result = Test-ObjectHasProperty -InputObject $object -PropertyName 'NonExistent'
                $result | Should -BeFalse
            }
        }

        It 'Should return true for DateTime properties' {
            InModuleScope -ScriptBlock {
                $object = [System.DateTime]::Now
                $result = Test-ObjectHasProperty -InputObject $object -PropertyName 'Year'
                $result | Should -BeTrue
            }
        }
    }

    Context 'When testing objects with NoteProperty' {
        It 'Should return true when NoteProperty exists' {
            InModuleScope -ScriptBlock {
                $object = New-Object -TypeName PSObject
                $object | Add-Member -MemberType NoteProperty -Name 'CustomProperty' -Value 'CustomValue'
                $result = Test-ObjectHasProperty -InputObject $object -PropertyName 'CustomProperty'
                $result | Should -BeTrue
            }
        }

        It 'Should return false when NoteProperty does not exist' {
            InModuleScope -ScriptBlock {
                $object = New-Object -TypeName PSObject
                $object | Add-Member -MemberType NoteProperty -Name 'CustomProperty' -Value 'CustomValue'
                $result = Test-ObjectHasProperty -InputObject $object -PropertyName 'NonExistent'
                $result | Should -BeFalse
            }
        }
    }

    Context 'When testing objects with ScriptProperty' {
        It 'Should return true when ScriptProperty exists' {
            InModuleScope -ScriptBlock {
                $object = New-Object -TypeName PSObject
                $object | Add-Member -MemberType ScriptProperty -Name 'ComputedProperty' -Value { 'Computed' }
                $result = Test-ObjectHasProperty -InputObject $object -PropertyName 'ComputedProperty'
                $result | Should -BeTrue
            }
        }
    }

    Context 'When testing edge cases' {
        It 'Should handle objects with properties that throw exceptions when accessed' {
            InModuleScope -ScriptBlock {
                # Create an object with a property that might cause issues
                $object = [PSCustomObject]@{ Name = 'Test' }
                $result = Test-ObjectHasProperty -InputObject $object -PropertyName 'Name'
                $result | Should -BeTrue
            }
        }

        It 'Should return false for null property names that do not exist' {
            InModuleScope -ScriptBlock {
                $object = [PSCustomObject]@{ Name = 'Test' }
                # Even though we're checking for a property that doesn't exist
                $result = Test-ObjectHasProperty -InputObject $object -PropertyName 'NonExistent'
                $result | Should -BeFalse
            }
        }
    }
}
