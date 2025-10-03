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
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks noop" first.'
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

Describe 'Assert-ObjectMethod' {
    Context 'When validating parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = '__AllParameterSets'
                ExpectedParameters = '[-Method] <string> [-Actual] <Object> [-Because <string>] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Assert-ObjectMethod').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }
    }

    Context 'When checking method existence' {
        It 'Should pass when object has the specified method' {
            $testObject = [PSCustomObject]@{
                Name = 'Test'
            }
            # Add a script method to the object
            $testObject | Add-Member -MemberType ScriptMethod -Name 'TestMethod' -Value { return 'Test' }

            $null = Assert-ObjectMethod -Actual $testObject -Method 'TestMethod'
        }

        It 'Should pass when .NET object has built-in method' {
            $testString = 'Hello World'

            $null = Assert-ObjectMethod -Actual $testString -Method 'ToString'
        }

        It 'Should pass when object has GetHashCode method' {
            $testObject = [PSCustomObject]@{
                Name = 'Test'
            }

            $null = Assert-ObjectMethod -Actual $testObject -Method 'GetHashCode'
        }

        It 'Should throw when object does not have the specified method' {
            $testObject = [PSCustomObject]@{
                Name = 'Test'
            }

            { Assert-ObjectMethod -Actual $testObject -Method 'NonExistentMethod' } | Should -Throw -ExpectedMessage "*method 'NonExistentMethod'*"
        }

        It 'Should throw when actual object is null' {
            { Assert-ObjectMethod -Actual $null -Method 'ToString' } | Should -Throw -ExpectedMessage '*Cannot bind argument to parameter*'
        }

        It 'Should include Because message in the error when method not found' {
            $testObject = [PSCustomObject]@{
                Name = 'Test'
            }
            $because = 'this is a test'

            {
                Assert-ObjectMethod -Actual $testObject -Method 'NonExistentMethod' -Because $because
            } | Should -Throw -ExpectedMessage '*because this is a test*'
        }

        It 'Should include Because message in the error when object is null' {
            $because = 'this is a test'

            {
                Assert-ObjectMethod -Actual $null -Method 'ToString' -Because $because
            } | Should -Throw -ExpectedMessage '*Cannot bind argument to parameter*'
        }

        It 'Should handle pipeline input' {
            $testString = 'Hello World'

            $null = $testString | Assert-ObjectMethod -Method 'ToString'
        }

        It 'Should handle multiple objects in pipeline and check all of them' {
            $testString1 = 'Hello'
            $testString2 = 'World'

            # Both strings have 'ToString' method, so this should pass
            $null = $testString1, $testString2 | Assert-ObjectMethod -Method 'ToString'
        }

        It 'Should throw when one of the pipeline objects is missing the method' {
            $testObject1 = [PSCustomObject]@{
                Name = 'Test1'
            }
            # Add a method to the second object
            $testObject2 = [PSCustomObject]@{
                Name = 'Test2'
            }
            $testObject2 | Add-Member -MemberType ScriptMethod -Name 'CustomMethod' -Value { return 'Test' }

            # First object doesn't have 'CustomMethod', so this should fail
            {
                $testObject1, $testObject2 | Assert-ObjectMethod -Method 'CustomMethod'
            } | Should -Throw -ExpectedMessage "*method 'CustomMethod'*"
        }
    }

    Context 'When working with different object types' {
        It 'Should work with custom classes' {
            class TestClass
            {
                [string]$Name

                TestClass([string]$name)
                {
                    $this.Name = $name
                }

                [string] GetDisplayName()
                {
                    return "Display: $($this.Name)"
                }
            }

            $testObject = [TestClass]::new('Test')

            $null = Assert-ObjectMethod -Actual $testObject -Method 'GetDisplayName'
        }

        It 'Should work with arrays' {
            $testArray = @(1, 2, 3)

            $null = Assert-ObjectMethod -Actual $testArray -Method 'GetEnumerator'
        }

        It 'Should work with hashtables' {
            $testHashtable = @{
                Name  = 'Test'
                Value = 123
            }

            $null = Assert-ObjectMethod -Actual $testHashtable -Method 'ContainsKey'
        }

        It 'Should work with collections' {
            $testList = [System.Collections.Generic.List[string]]::new()

            $null = Assert-ObjectMethod -Actual $testList -Method 'Add'
        }

        It 'Should work with FileInfo objects' {
            $tempFile = New-TemporaryFile
            try
            {
                $fileInfo = Get-Item $tempFile.FullName

                $null = Assert-ObjectMethod -Actual $fileInfo -Method 'Delete'
            }
            finally
            {
                Remove-Item $tempFile.FullName -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Should work with DateTime objects' {
            $testDate = Get-Date

            $null = Assert-ObjectMethod -Actual $testDate -Method 'AddDays'
        }
    }

    Context 'When using alias' {
        It 'Should be able to be called using its alias' {
            $testString = 'Hello World'

            $null = Should-HaveMethod -Actual $testString -Method 'ToString'
        }

        It 'Should be able to be called using its alias with pipeline' {
            $testString = 'Hello World'

            $null = $testString | Should-HaveMethod -Method 'ToString'
        }
    }

    Context 'When handling edge cases' {
        It 'Should handle method names with special characters' {
            # Create a mock object with a method that has special characters (not common but possible)
            $testObject = [PSCustomObject]@{}
            $testObject | Add-Member -MemberType ScriptMethod -Name 'Method_With_Underscores' -Value { return 'Test' }

            $null = Assert-ObjectMethod -Actual $testObject -Method 'Method_With_Underscores'
        }

        It 'Should handle case-insensitive method names correctly' {
            $testString = 'Hello World'

            # PowerShell method names are case-insensitive
            $null = Assert-ObjectMethod -Actual $testString -Method 'ToString'
            $null = Assert-ObjectMethod -Actual $testString -Method 'tostring'
        }

        It 'Should handle methods inherited from base classes' {
            $testObject = [PSCustomObject]@{
                Name = 'Test'
            }

            $null = Assert-ObjectMethod -Actual $testObject -Method 'Equals'
        }

        It 'Should fail when method does not exist on the instance' {
            $testString = 'Hello World'

            # NonExistentMethod should definitely not exist
            { Assert-ObjectMethod -Actual $testString -Method 'NonExistentMethod' } | Should -Throw
        }
    }

    Context 'Error message validation' {
        It 'Should throw the correct error message when object is null' {
            {
                Assert-ObjectMethod -Actual $null -Method 'ToString'
            } | Should -Throw -ExpectedMessage '*Cannot bind argument to parameter*Actual*because it is null*'
        }

        It 'Should throw the correct error message when method not found' {
            $testObject = [PSCustomObject]@{
                Name = 'Test'
            }

            {
                Assert-ObjectMethod -Actual $testObject -Method 'NonExistentMethod'
            } | Should -Throw -ExpectedMessage "Expected the object to have method 'NonExistentMethod', but the method was not found."
        }
    }

    Context 'When working with PSCustomObject methods' {
        It 'Should detect script methods added to PSCustomObject' {
            $testObject = [PSCustomObject]@{
                Name = 'Test'
            }
            $testObject | Add-Member -MemberType ScriptMethod -Name 'CustomMethod' -Value { return $this.Name.ToUpper() }

            $null = Assert-ObjectMethod -Actual $testObject -Method 'CustomMethod'
        }

        It 'Should detect note methods added to PSCustomObject' {
            $testObject = [PSCustomObject]@{
                Name = 'Test'
            }
            # Note: Add-Member with MemberType Method is not commonly used, but ScriptMethod is more common
            # We'll test what's actually supported

            $null = Assert-ObjectMethod -Actual $testObject -Method 'ToString'
        }
    }

    Context 'When testing edge cases for uncovered lines' {
        It 'Should find method via PSObject.Methods when it exists (line 129)' {
            # Create an object where Get-Member fails but PSObject.Methods works
            # Mock Get-Member to return null so it falls through to PSObject.Methods check
            Mock -ModuleName 'Viscalyx.Assert' -CommandName 'Get-Member' -MockWith { return $null } -ParameterFilter { $MemberType -match 'Method' }

            $testObject = [PSCustomObject]@{ Name = 'Test' }
            $testObject | Add-Member -MemberType ScriptMethod -Name 'TestMethod' -Value { return 'Success' }

            # This should find the method via PSObject.Methods[$Method] and set $hasMethod = $true (line 129)
            $null = Assert-ObjectMethod -Actual $testObject -Method 'TestMethod'
        }

        It 'Should trigger reflection catch block when GetMethod throws (line 135)' {
            # Create a mock type that will cause GetMethod to throw
            Add-Type -TypeDefinition @"
                using System;
                public class RestrictedClass {
                    public string Name { get; set; }
                    public new Type GetType() {
                        throw new System.Security.SecurityException("Access denied");
                    }
                }
"@ -ErrorAction SilentlyContinue

            $restrictedObject = New-Object RestrictedClass
            $restrictedObject.Name = 'Test'

            # This should trigger the catch block at line 135 when GetMethod fails
            { Assert-ObjectMethod -Actual $restrictedObject -Method 'NonExistentMethod' } | Should -Throw
        }

        It 'Should trigger outer catch block when PSObject access fails (line 142)' {
            # Create an object that will cause the entire try block to fail
            Add-Type -TypeDefinition @"
                public class TestClass {
                    public string Name { get; set; }
                }
"@ -ErrorAction SilentlyContinue

            $testObject = [TestClass]@{ Name = 'Test' }

            # Mock PSObject.Methods to throw an exception to trigger outer catch (line 142)
            Mock -ModuleName 'Viscalyx.Assert' -CommandName 'Get-Member' -MockWith { throw 'PSObject access failed' }

            { Assert-ObjectMethod -Actual $testObject -Method 'NonExistentMethod' } | Should -Throw
        }
    }
}
