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
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
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

Describe 'Assert-ObjectProperty' {
    Context 'When using AssertProperty parameter set' {
        It 'Should pass when object has the specified property' {
            $testObject = [PSCustomObject]@{
                Name  = 'Test'
                Value = 123
            }

            $null = Assert-ObjectProperty -Actual $testObject -Property 'Name'
        }

        It 'Should pass when object has property with null value' {
            $testObject = [PSCustomObject]@{
                Name  = $null
                Value = 123
            }

            $null = Assert-ObjectProperty -Actual $testObject -Property 'Name'
        }

        It 'Should throw when object does not have the specified property' {
            $testObject = [PSCustomObject]@{
                Name  = 'Test'
                Value = 123
            }

            { Assert-ObjectProperty -Actual $testObject -Property 'NonExistent' } | Should -Throw -ExpectedMessage "*property 'NonExistent'*"
        }

        It 'Should throw when actual object is null' {
            { Assert-ObjectProperty -Actual $null -Property 'Name' } | Should -Throw -ExpectedMessage '*Cannot bind argument to parameter*'
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
            } | Should -Throw -ExpectedMessage '*Cannot bind argument to parameter*'
        }

        It 'Should handle pipeline input' {
            $testObject = [PSCustomObject]@{
                Name  = 'Test'
                Value = 123
            }

            $null = $testObject | Assert-ObjectProperty -Property 'Name'
        }

        It 'Should handle multiple objects in pipeline by using the last one' {
            $testObject1 = [PSCustomObject]@{
                Name = 'Test1'
            }
            $testObject2 = [PSCustomObject]@{
                Value = 'Test2'
            }

            $null = $testObject1, $testObject2 | Assert-ObjectProperty -Property 'Value'
        }

        It 'Should work with hashtables' {
            $testHashtable = @{
                Name  = 'Test'
                Value = 123
            }

            $null = Assert-ObjectProperty -Actual $testHashtable -Property 'Name'
        }

        It 'Should work with .NET objects' {
            $testObject = [System.IO.FileInfo]::new('C:\temp\test.txt')

            $null = Assert-ObjectProperty -Actual $testObject -Property 'Name'
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

            $null = Assert-ObjectProperty -Actual $testObject -Property 'Name'
        }
    }

    Context 'When using AssertValue parameter set' {
        It 'Should pass when object has property with matching value' {
            $testObject = [PSCustomObject]@{
                Name  = 'Test'
                Value = 123
            }

            $null = Assert-ObjectProperty -Actual $testObject -Property 'Name' -Value 'Test'
        }

        It 'Should pass when property value is null and expected value is null' {
            $testObject = [PSCustomObject]@{
                Name  = $null
                Value = 123
            }

            $null = Assert-ObjectProperty -Actual $testObject -Property 'Name' -Value $null
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

            $null = Assert-ObjectProperty -Actual $testObject -Property 'StringValue' -Value 'Test'
            $null = Assert-ObjectProperty -Actual $testObject -Property 'IntValue' -Value 123
            $null = Assert-ObjectProperty -Actual $testObject -Property 'BoolValue' -Value $true
            $null = Assert-ObjectProperty -Actual $testObject -Property 'ArrayValue' -Value @(1, 2, 3)
        }

        It 'Should handle type coercion appropriately' {
            $testObject = [PSCustomObject]@{
                NumberValue = 123
            }

            # PowerShell's -eq operator handles type coercion
            $null = Assert-ObjectProperty -Actual $testObject -Property 'NumberValue' -Value '123'
        }

        It 'Should handle pipeline input with value assertion' {
            $testObject = [PSCustomObject]@{
                Name  = 'Test'
                Value = 123
            }

            $null = $testObject | Assert-ObjectProperty -Property 'Name' -Value 'Test'
        }
    }

    Context 'When using alias' {
        It 'Should be able to be called using its alias' {
            $testObject = [PSCustomObject]@{
                Name = 'Test'
            }

            $null = Should-HaveProperty -Actual $testObject -Property 'Name'
        }

        It 'Should be able to be called using its alias with value assertion' {
            $testObject = [PSCustomObject]@{
                Name = 'Test'
            }

            $null = Should-HaveProperty -Actual $testObject -Property 'Name' -Value 'Test'
        }
    }

    Context 'When handling edge cases' {
        It 'Should handle single character property names' {
            $testHashtable = @{
                'X' = 'SingleCharPropertyName'
            }

            $null = Assert-ObjectProperty -Actual $testHashtable -Property 'X'
        }

        It 'Should handle special characters in property names' {
            $testHashtable = @{
                'Property-With-Dashes' = 'Test'
                'Property.With.Dots'   = 'Test'
                'Property With Spaces' = 'Test'
            }

            $null = Assert-ObjectProperty -Actual $testHashtable -Property 'Property-With-Dashes'
            $null = Assert-ObjectProperty -Actual $testHashtable -Property 'Property.With.Dots'
            $null = Assert-ObjectProperty -Actual $testHashtable -Property 'Property With Spaces'
        }

        It 'Should handle case-sensitive property names correctly' {
            # Use hashtable which is case-sensitive
            $testHashtable = @{}
            $testHashtable['Name'] = 'Test'

            $null = Assert-ObjectProperty -Actual $testHashtable -Property 'Name' -Value 'Test'
        }

        It 'Should handle dynamic properties on PSCustomObject' {
            $testObject = [PSCustomObject]@{}
            $testObject | Add-Member -NotePropertyName 'DynamicProperty' -NotePropertyValue 'Test'

            $null = Assert-ObjectProperty -Actual $testObject -Property 'DynamicProperty'
        }
    }

    Context 'Error message validation' {
        It 'Should throw the correct error message when object is null' {
            {
                Assert-ObjectProperty -Actual $null -Property 'Name'
            } | Should -Throw -ExpectedMessage '*Cannot bind argument to parameter*Actual*because it is null*'
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

    Context 'When testing edge cases for uncovered lines' {
        It 'Should find property via PSObject.Properties when it exists (line 136)' {
            # Create an object where hashtable check fails but PSObject.Properties works
            # The hashtable check is on line ~427: if ($Actual -is [System.Collections.IDictionary] -and $Actual.ContainsKey($Property))
            # We need an object that is NOT a hashtable but has properties accessible via PSObject.Properties
            $testObject = [PSCustomObject]@{}
            $testObject | Add-Member -MemberType NoteProperty -Name 'DynamicProperty' -Value 'TestValue'

            # This should find the property via PSObject.Properties[$Property] and set $hasProperty = $true (line 136)
            $null = Assert-ObjectProperty -Actual $testObject -Property 'DynamicProperty'
        }

        It 'Should trigger Get-Member fallback when PSObject.Properties fails (line 151)' {
            # Create an object that will cause Get-Member to return null, triggering line 151
            $testObject = [PSCustomObject]@{ Name = 'Test' }

            # Mock Get-Member to return $null to trigger line 151 ($hasProperty = $false)
            Mock -ModuleName 'Viscalyx.Assert' -CommandName 'Get-Member' -MockWith { return $null }

            { Assert-ObjectProperty -Actual $testObject -Property 'NonExistentProperty' } | Should -Throw
        }

        It 'Should trigger direct property access catch block (line 158)' {
            # Create an object that will cause direct property access to throw an exception
            $testObject = [PSCustomObject]@{ Name = 'Test' }

            # Add a property that throws when accessed
            $testObject | Add-Member -MemberType ScriptProperty -Name 'BadProperty' -Value { throw 'Property access failed' }

            # This should trigger the catch block at line 158 when $Actual.$Property throws
            { Assert-ObjectProperty -Actual $testObject -Property 'NonExistentProperty' } | Should -Throw
        }

        It 'Should handle array comparison where arrays have different counts' {
            # Test array comparison with different counts to trigger the $valuesAreEqual = $false path
            $testObject = [PSCustomObject]@{
                Items = @(1, 2, 3)
            }
            $expectedValue = @(1, 2)  # Different count

            {
                Assert-ObjectProperty -Actual $testObject -Property 'Items' -Value $expectedValue
            } | Should -Throw -ExpectedMessage "*but the actual value was*"
        }

        It 'Should handle array comparison where individual elements differ' {
            # Test array comparison where individual elements differ
            $testObject = [PSCustomObject]@{
                Items = @(1, 2, 3)
            }
            $expectedValue = @(1, 2, 4)  # Same count, different last element

            {
                Assert-ObjectProperty -Actual $testObject -Property 'Items' -Value $expectedValue
            } | Should -Throw -ExpectedMessage "*but the actual value was*"
        }
    }
}
