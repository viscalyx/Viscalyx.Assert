[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies has been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies has not been resolved, this will throw an error.
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

Describe 'Assert-ObjectProperty' {
    Context 'When using AssertProperty parameter set' {
        It 'Should pass when object has the specified property' {
            $testObject = [PSCustomObject]@{
                Name  = 'Test'
                Value = 123
            }

            { Assert-ObjectProperty -Actual $testObject -Property 'Name' } | Should -Not -Throw
        }

        It 'Should pass when object has property with null value' {
            $testObject = [PSCustomObject]@{
                Name  = $null
                Value = 123
            }

            { Assert-ObjectProperty -Actual $testObject -Property 'Name' } | Should -Not -Throw
        }

        It 'Should throw when object does not have the specified property' {
            $testObject = [PSCustomObject]@{
                Name  = 'Test'
                Value = 123
            }

            { Assert-ObjectProperty -Actual $testObject -Property 'NonExistent' } | Should -Throw -ExpectedMessage "*property 'NonExistent'*"
        }

        It 'Should throw when actual object is null' {
            { Assert-ObjectProperty -Actual $null -Property 'Name' } | Should -Throw -ExpectedMessage '*not to be null*'
        }

        It 'Should include Because message in the error when property not found' {
            $testObject = [PSCustomObject]@{
                Name = 'Test'
            }
            $because = 'this is a test'

            {
                Assert-ObjectProperty -Actual $testObject -Property 'NonExistent' -Because $because
            } | Should -Throw -ExpectedMessage '*because this is a test*'
        }

        It 'Should include Because message in the error when object is null' {
            $because = 'this is a test'

            {
                Assert-ObjectProperty -Actual $null -Property 'Name' -Because $because
            } | Should -Throw -ExpectedMessage '*because this is a test*'
        }

        It 'Should handle pipeline input' {
            $testObject = [PSCustomObject]@{
                Name  = 'Test'
                Value = 123
            }

            { $testObject | Assert-ObjectProperty -Property 'Name' } | Should -Not -Throw
        }

        It 'Should handle multiple objects in pipeline by using the last one' {
            $testObject1 = [PSCustomObject]@{
                Name = 'Test1'
            }
            $testObject2 = [PSCustomObject]@{
                Value = 'Test2'
            }

            { $testObject1, $testObject2 | Assert-ObjectProperty -Property 'Value' } | Should -Not -Throw
        }

        It 'Should work with hashtables' {
            $testHashtable = @{
                Name  = 'Test'
                Value = 123
            }

            { Assert-ObjectProperty -Actual $testHashtable -Property 'Name' } | Should -Not -Throw
        }

        It 'Should work with .NET objects' {
            $testObject = [System.IO.FileInfo]::new('C:\temp\test.txt')

            { Assert-ObjectProperty -Actual $testObject -Property 'Name' } | Should -Not -Throw
        }

        It 'Should work with custom classes' {
            class TestClass
            {
                [string]$Name
                [int]$Value

                TestClass([string]$name, [int]$value)
                {
                    $this.Name = $name
                    $this.Value = $value
                }
            }

            $testObject = [TestClass]::new('Test', 123)

            { Assert-ObjectProperty -Actual $testObject -Property 'Name' } | Should -Not -Throw
        }
    }

    Context 'When using AssertValue parameter set' {
        It 'Should pass when object has property with matching value' {
            $testObject = [PSCustomObject]@{
                Name  = 'Test'
                Value = 123
            }

            { Assert-ObjectProperty -Actual $testObject -Property 'Name' -Value 'Test' } | Should -Not -Throw
        }

        It 'Should pass when property value is null and expected value is null' {
            $testObject = [PSCustomObject]@{
                Name  = $null
                Value = 123
            }

            { Assert-ObjectProperty -Actual $testObject -Property 'Name' -Value $null } | Should -Not -Throw
        }

        It 'Should throw when property value does not match expected value' {
            $testObject = [PSCustomObject]@{
                Name  = 'Test'
                Value = 123
            }

            {
                Assert-ObjectProperty -Actual $testObject -Property 'Name' -Value 'Different'
            } | Should -Throw -ExpectedMessage "*Expected property 'Name' to have value 'Different'*"
        }

        It 'Should throw when object does not have the specified property' {
            $testObject = [PSCustomObject]@{
                Name  = 'Test'
                Value = 123
            }

            {
                Assert-ObjectProperty -Actual $testObject -Property 'NonExistent' -Value 'Test'
            } | Should -Throw -ExpectedMessage "*property 'NonExistent'*"
        }

        It 'Should include Because message in the error when value mismatch' {
            $testObject = [PSCustomObject]@{
                Name = 'Test'
            }
            $because = 'this is a test'

            {
                Assert-ObjectProperty -Actual $testObject -Property 'Name' -Value 'Different' -Because $because
            } | Should -Throw -ExpectedMessage '*because this is a test*'
        }

        It 'Should handle different data types correctly' {
            $testObject = [PSCustomObject]@{
                StringValue = 'Test'
                IntValue    = 123
                BoolValue   = $true
                ArrayValue  = @(1, 2, 3)
            }

            { Assert-ObjectProperty -Actual $testObject -Property 'StringValue' -Value 'Test' } | Should -Not -Throw
            { Assert-ObjectProperty -Actual $testObject -Property 'IntValue' -Value 123 } | Should -Not -Throw
            { Assert-ObjectProperty -Actual $testObject -Property 'BoolValue' -Value $true } | Should -Not -Throw
            { Assert-ObjectProperty -Actual $testObject -Property 'ArrayValue' -Value @(1, 2, 3) } | Should -Not -Throw
        }

        It 'Should handle type coercion appropriately' {
            $testObject = [PSCustomObject]@{
                NumberValue = 123
            }

            # PowerShell's -eq operator handles type coercion
            { Assert-ObjectProperty -Actual $testObject -Property 'NumberValue' -Value '123' } | Should -Not -Throw
        }

        It 'Should handle pipeline input with value assertion' {
            $testObject = [PSCustomObject]@{
                Name  = 'Test'
                Value = 123
            }

            { $testObject | Assert-ObjectProperty -Property 'Name' -Value 'Test' } | Should -Not -Throw
        }
    }

    Context 'When using alias' {
        It 'Should be able to be called using its alias' {
            $testObject = [PSCustomObject]@{
                Name = 'Test'
            }

            { Should-HaveProperty -Actual $testObject -Property 'Name' } | Should -Not -Throw
        }

        It 'Should be able to be called using its alias with value assertion' {
            $testObject = [PSCustomObject]@{
                Name = 'Test'
            }

            { Should-HaveProperty -Actual $testObject -Property 'Name' -Value 'Test' } | Should -Not -Throw
        }
    }

    Context 'When handling edge cases' {
        It 'Should handle single character property names' {
            $testHashtable = @{
                'X' = 'SingleCharPropertyName'
            }

            { Assert-ObjectProperty -Actual $testHashtable -Property 'X' } | Should -Not -Throw
        }

        It 'Should handle special characters in property names' {
            $testHashtable = @{
                'Property-With-Dashes' = 'Test'
                'Property.With.Dots'   = 'Test'
                'Property With Spaces' = 'Test'
            }

            { Assert-ObjectProperty -Actual $testHashtable -Property 'Property-With-Dashes' } | Should -Not -Throw
            { Assert-ObjectProperty -Actual $testHashtable -Property 'Property.With.Dots' } | Should -Not -Throw
            { Assert-ObjectProperty -Actual $testHashtable -Property 'Property With Spaces' } | Should -Not -Throw
        }

        It 'Should handle case-sensitive property names correctly' {
            # Use hashtable which is case-sensitive
            $testHashtable = @{}
            $testHashtable['Name'] = 'Test'

            { Assert-ObjectProperty -Actual $testHashtable -Property 'Name' -Value 'Test' } | Should -Not -Throw
        }

        It 'Should handle dynamic properties on PSCustomObject' {
            $testObject = [PSCustomObject]@{}
            $testObject | Add-Member -NotePropertyName 'DynamicProperty' -NotePropertyValue 'Test'

            { Assert-ObjectProperty -Actual $testObject -Property 'DynamicProperty' } | Should -Not -Throw
        }
    }

    Context 'Error message validation' {
        It 'Should throw the correct error message when object is null' {
            {
                Assert-ObjectProperty -Actual $null -Property 'Name'
            } | Should -Throw -ExpectedMessage 'Expected the actual value not to be null, but it was null.'
        }

        It 'Should throw the correct error message when property not found' {
            $testObject = [PSCustomObject]@{
                Name = 'Test'
            }

            {
                Assert-ObjectProperty -Actual $testObject -Property 'NonExistent'
            } | Should -Throw -ExpectedMessage "Expected the object to have property 'NonExistent', but the property was not found."
        }

        It 'Should throw the correct error message when value mismatch' {
            $testObject = [PSCustomObject]@{
                Name = 'Test'
            }

            {
                Assert-ObjectProperty -Actual $testObject -Property 'Name' -Value 'Expected'
            } | Should -Throw -ExpectedMessage "Expected property 'Name' to have value 'Expected', but the actual value was 'Test'."
        }
    }
}
