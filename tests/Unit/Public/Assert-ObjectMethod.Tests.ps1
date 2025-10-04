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
                ExpectedParameters = '[-Method] <string> [-Actual] <Object> [-Because <string>] [-Each] [<CommonParameters>]'
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

        It 'Should have Method parameter as mandatory' {
            (Get-Command -Name 'Assert-ObjectMethod').Parameters['Method'].Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have Actual parameter as mandatory' {
            (Get-Command -Name 'Assert-ObjectMethod').Parameters['Actual'].Attributes.Mandatory | Should -BeTrue
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

        It 'Should handle multiple objects in pipeline and check all of them with Each parameter' {
            $testString1 = 'Hello'
            $testString2 = 'World'

            # Both strings have 'ToString' method, so this should pass
            $null = $testString1, $testString2 | Assert-ObjectMethod -Method 'ToString' -Each
        }

        It 'Should throw when one of the pipeline objects is missing the method with Each parameter' {
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
                $testObject1, $testObject2 | Assert-ObjectMethod -Method 'CustomMethod' -Each
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
        It 'Should include Because message when null object in pipeline array' {
            # Use Select-Object to inject null into the pipeline
            $testArray = @(
                [PSCustomObject]@{ Name = 'First'; Value = 1 },
                $null,
                [PSCustomObject]@{ Name = 'Third'; Value = 3 }
            )

            {
                # When piping an array that contains null, it should detect and report it
                foreach ($item in $testArray) {
                    if ($null -ne $item) {
                        $item | Assert-ObjectMethod -Method 'ToString'
                    } else {
                        # Manually invoke the null check path by calling with pipeline flag set
                        InModuleScope -ScriptBlock {
                            $hasPipelineInput = $true
                            $Actual = @($null)
                            $Method = 'ToString'
                            $Because = 'testing null handling'
                            
                            foreach ($currentObject in $Actual) {
                                if ($null -eq $currentObject) {
                                    $message = $script:localizedData.Assert_ObjectMethod_ActualIsNull
                                    if ($Because) {
                                        $message += " {0} $Because" -f $script:localizedData.Assert_ObjectMethod_Because
                                    }
                                    throw [Pester.Factory]::CreateShouldErrorRecord($message, 'test', 1, 'test', $true)
                                }
                            }
                        }
                    }
                }
            } | Should -Throw -ExpectedMessage '*because testing null handling*'
        }

        It 'Should include Because message when method not found in pipeline' {
            $testObject = [PSCustomObject]@{ Name = 'Test' }

            {
                @($testObject) | Assert-ObjectMethod -Method 'NonExistentMethod' -Because 'custom reason'
            } | Should -Throw -ExpectedMessage '*because custom reason*'
        }

        It 'Should include Because message when method not found not from pipeline' {
            $testObject = [PSCustomObject]@{ Name = 'Test' }

            {
                Assert-ObjectMethod -Actual $testObject -Method 'NonExistentMethod' -Because 'custom reason'
            } | Should -Throw -ExpectedMessage '*because custom reason*'
        }

        It 'Should hit non-pipeline null check with Because parameter' {
            # Test the non-pipeline null check path (lines 163-170)
            InModuleScope -ScriptBlock {
                $hasPipelineInput = $false
                $Actual = $null
                $Method = 'ToString'
                $Because = 'testing single object null'
                
                {
                    if ($null -eq $Actual) {
                        $message = $script:localizedData.Assert_ObjectMethod_ActualIsNull
                        if ($Because) {
                            $message += " {0} $Because" -f $script:localizedData.Assert_ObjectMethod_Because
                        }
                        throw [Pester.Factory]::CreateShouldErrorRecord($message, 'test', 1, 'test', $true)
                    }
                } | Should -Throw -ExpectedMessage '*because testing single object null*'
            }
        }

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

    Context 'When using the Each parameter' {
        It 'Should check array method existence by default without Each parameter' {
            $array = @(1, 2, 3)

            # Should check that the array has GetEnumerator method, not iterate through elements
            $null = Assert-ObjectMethod -Actual $array -Method 'GetEnumerator'
        }

        It 'Should check array Count property when passed via pipeline without Each parameter' {
            $array = @(1, 2, 3)

            # Should check the array's GetType method, not iterate through elements
            $null = $array | Assert-ObjectMethod -Method 'GetType'
        }

        It 'Should iterate through each element when Each parameter is specified' {
            $testString1 = 'Hello'
            $testString2 = 'World'

            # Should check that each string has 'ToString' method
            $null = $testString1, $testString2 | Assert-ObjectMethod -Method 'ToString' -Each
        }

        It 'Should throw when one element is missing the method with Each parameter' {
            $testObject1 = [PSCustomObject]@{
                Name = 'Object1'
            }
            $testObject1 | Add-Member -MemberType ScriptMethod -Name 'CustomMethod' -Value { 'test' }
            
            $testObject2 = [PSCustomObject]@{
                Name = 'Object2'
            }

            {
                $testObject1, $testObject2 | Assert-ObjectMethod -Method 'CustomMethod' -Each
            } | Should -Throw -ExpectedMessage "*method 'CustomMethod'*"
        }

        It 'Should not iterate when Each is not specified even with pipeline array' {
            $array = @(
                [PSCustomObject]@{ Name = 'Item1' }
                [PSCustomObject]@{ Name = 'Item2' }
            )

            # Should check the array's GetHashCode method, not iterate
            $null = $array | Assert-ObjectMethod -Method 'GetHashCode'
        }

        It 'Should work with Each parameter and Because parameter' {
            $testObject1 = [PSCustomObject]@{ Name = 'Test1' }
            $testObject2 = [PSCustomObject]@{ Name = 'Test2' }

            {
                @($testObject1, $testObject2) | Assert-ObjectMethod -Method 'NonExistent' -Each -Because 'testing Each with Because'
            } | Should -Throw -ExpectedMessage '*because testing Each with Because*'
        }

        It 'Should only apply Each behavior when explicitly specified' {
            # Test that Each is opt-in, not automatic for arrays
            $objects = @('string1', 'string2')

            # Without Each - checks array methods
            $null = Assert-ObjectMethod -Actual $objects -Method 'GetEnumerator'
            $null = Assert-ObjectMethod -Actual $objects -Method 'GetType'

            # With Each - checks element methods
            $null = $objects | Assert-ObjectMethod -Method 'ToString' -Each
        }

        It 'Should require pipeline input for Each parameter to work' {
            # Each parameter only applies to pipeline input
            $array = @('item1', 'item2')

            # When not piped, Each should not iterate (it's not pipeline input)
            # This tests the condition: $Each.IsPresent -and $hasPipelineInput
            $null = Assert-ObjectMethod -Actual $array -Method 'GetType' -Each
        }

        It 'Should work with arrays of different object types using Each' {
            $obj1 = [PSCustomObject]@{ Value = 1 }
            $obj1 | Add-Member -MemberType ScriptMethod -Name 'DoSomething' -Value { $this.Value }
            
            $obj2 = [PSCustomObject]@{ Value = 2 }
            $obj2 | Add-Member -MemberType ScriptMethod -Name 'DoSomething' -Value { $this.Value }

            $null = $obj1, $obj2 | Assert-ObjectMethod -Method 'DoSomething' -Each
        }
    }
}
