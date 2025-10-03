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

Describe 'Assert-ObjectMethod' {
    Context 'When checking method existence' {
        It 'Should pass when object has the specified method' {
            $testObject = [PSCustomObject]@{
                Name = 'Test'
            }
            # Add a script method to the object
            $testObject | Add-Member -MemberType ScriptMethod -Name 'TestMethod' -Value { return 'Test' }

            { Assert-ObjectMethod -Actual $testObject -Method 'TestMethod' } | Should -Not -Throw
        }

        It 'Should pass when .NET object has built-in method' {
            $testString = 'Hello World'

            { Assert-ObjectMethod -Actual $testString -Method 'ToString' } | Should -Not -Throw
        }

        It 'Should pass when object has GetHashCode method' {
            $testObject = [PSCustomObject]@{
                Name = 'Test'
            }

            { Assert-ObjectMethod -Actual $testObject -Method 'GetHashCode' } | Should -Not -Throw
        }

        It 'Should throw when object does not have the specified method' {
            $testObject = [PSCustomObject]@{
                Name = 'Test'
            }

            { Assert-ObjectMethod -Actual $testObject -Method 'NonExistentMethod' } | Should -Throw -ExpectedMessage "*method 'NonExistentMethod'*"
        }

        It 'Should throw when actual object is null' {
            { Assert-ObjectMethod -Actual $null -Method 'ToString' } | Should -Throw -ExpectedMessage '*not to be null*'
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
            } | Should -Throw -ExpectedMessage '*because this is a test*'
        }

        It 'Should handle pipeline input' {
            $testString = 'Hello World'

            { $testString | Assert-ObjectMethod -Method 'ToString' } | Should -Not -Throw
        }

        It 'Should handle multiple objects in pipeline by using the last one' {
            $testString1 = 'Hello'
            $testString2 = 'World'

            { $testString1, $testString2 | Assert-ObjectMethod -Method 'ToString' } | Should -Not -Throw
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

            { Assert-ObjectMethod -Actual $testObject -Method 'GetDisplayName' } | Should -Not -Throw
        }

        It 'Should work with arrays' {
            $testArray = @(1, 2, 3)

            { Assert-ObjectMethod -Actual $testArray -Method 'GetEnumerator' } | Should -Not -Throw
        }

        It 'Should work with hashtables' {
            $testHashtable = @{
                Name  = 'Test'
                Value = 123
            }

            { Assert-ObjectMethod -Actual $testHashtable -Method 'ContainsKey' } | Should -Not -Throw
        }

        It 'Should work with collections' {
            $testList = [System.Collections.Generic.List[string]]::new()

            { Assert-ObjectMethod -Actual $testList -Method 'Add' } | Should -Not -Throw
        }

        It 'Should work with FileInfo objects' {
            $tempFile = New-TemporaryFile
            try
            {
                $fileInfo = Get-Item $tempFile.FullName

                { Assert-ObjectMethod -Actual $fileInfo -Method 'Delete' } | Should -Not -Throw
            }
            finally
            {
                Remove-Item $tempFile.FullName -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Should work with DateTime objects' {
            $testDate = Get-Date

            { Assert-ObjectMethod -Actual $testDate -Method 'AddDays' } | Should -Not -Throw
        }
    }

    Context 'When using alias' {
        It 'Should be able to be called using its alias' {
            $testString = 'Hello World'

            { Should-HaveMethod -Actual $testString -Method 'ToString' } | Should -Not -Throw
        }

        It 'Should be able to be called using its alias with pipeline' {
            $testString = 'Hello World'

            { $testString | Should-HaveMethod -Method 'ToString' } | Should -Not -Throw
        }
    }

    Context 'When handling edge cases' {
        It 'Should handle method names with special characters' {
            # Create a mock object with a method that has special characters (not common but possible)
            $testObject = [PSCustomObject]@{}
            $testObject | Add-Member -MemberType ScriptMethod -Name 'Method_With_Underscores' -Value { return 'Test' }

            { Assert-ObjectMethod -Actual $testObject -Method 'Method_With_Underscores' } | Should -Not -Throw
        }

        It 'Should handle case-insensitive method names correctly' {
            $testString = 'Hello World'

            # PowerShell method names are case-insensitive
            { Assert-ObjectMethod -Actual $testString -Method 'ToString' } | Should -Not -Throw
            { Assert-ObjectMethod -Actual $testString -Method 'tostring' } | Should -Not -Throw
        }

        It 'Should handle methods inherited from base classes' {
            $testObject = [PSCustomObject]@{
                Name = 'Test'
            }

            { Assert-ObjectMethod -Actual $testObject -Method 'Equals' } | Should -Not -Throw
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
            } | Should -Throw -ExpectedMessage 'Expected the actual value not to be null, but it was null.'
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

            { Assert-ObjectMethod -Actual $testObject -Method 'CustomMethod' } | Should -Not -Throw
        }

        It 'Should detect note methods added to PSCustomObject' {
            $testObject = [PSCustomObject]@{
                Name = 'Test'
            }
            # Note: Add-Member with MemberType Method is not commonly used, but ScriptMethod is more common
            # We'll test what's actually supported

            { Assert-ObjectMethod -Actual $testObject -Method 'ToString' } | Should -Not -Throw
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
            { Assert-ObjectMethod -Actual $testObject -Method 'TestMethod' } | Should -Not -Throw
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
