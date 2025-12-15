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

Describe 'Assert-NotBitwiseFlag' {
    Context 'When validating parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = 'Default'
                ExpectedParameters = '[-Expected] <Object> [-Actual] <Object> [-Because <string>] [<CommonParameters>]'
            }
            @{
                ExpectedParameterSetName = 'EachDefault'
                ExpectedParameters = '[-Expected] <Object> [-Actual] <Object> -Each [-Because <string>] [<CommonParameters>]'
            }
            @{
                ExpectedParameterSetName = 'EachAll'
                ExpectedParameters = '[-Expected] <Object> [-Actual] <Object> -Each -All [-Because <string>] [<CommonParameters>]'
            }
            @{
                ExpectedParameterSetName = 'EachAny'
                ExpectedParameters = '[-Expected] <Object> [-Actual] <Object> -Each -Any [-Because <string>] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Assert-NotBitwiseFlag').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }

        It 'Should have Flag parameter as mandatory' {
            (Get-Command -Name 'Assert-NotBitwiseFlag').Parameters['Expected'].Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have Actual parameter as mandatory' {
            (Get-Command -Name 'Assert-NotBitwiseFlag').Parameters['Actual'].Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have Actual parameter accept pipeline input' {
            (Get-Command -Name 'Assert-NotBitwiseFlag').Parameters['Actual'].Attributes.ValueFromPipeline | Should -BeTrue
        }
    }

    Context 'When asserting flag is NOT set on single values' {
        It 'Should pass when flag is not set' {
            $null = Assert-NotBitwiseFlag -Actual 3 -Expected 4
        }

        It 'Should throw when flag is set' {
            { Assert-NotBitwiseFlag -Actual 7 -Expected 4 } | Should -Throw -ExpectedMessage "*NOT to have flag '4' set*set on '7'*"
        }

        It 'Should pass when using enum flag that is not set' {
            $fileAttributes = [System.IO.FileAttributes]::ReadOnly
            $null = Assert-NotBitwiseFlag -Actual $fileAttributes -Expected ([System.IO.FileAttributes]::Hidden)
        }

        It 'Should throw when using enum flag that is set' {
            $fileAttributes = [System.IO.FileAttributes]::ReadOnly -bor [System.IO.FileAttributes]::Hidden
            { Assert-NotBitwiseFlag -Actual $fileAttributes -Expected ([System.IO.FileAttributes]::ReadOnly) } | Should -Throw
        }

        It 'Should throw when flag is zero (always set)' {
            { Assert-NotBitwiseFlag -Actual 7 -Expected 0 } | Should -Throw
        }

        It 'Should pass when checking single bit not set' {
            $null = Assert-NotBitwiseFlag -Actual 0b1010 -Expected 0b0001
        }

        It 'Should pass with negative values where flag is not set' {
            $null = Assert-NotBitwiseFlag -Actual (-2) -Expected 1
        }
    }

    Context 'When asserting flag on array with -Each parameter' {
        It 'Should pass when all elements do not have the flag set (default -All behavior)' {
            $values = @(1, 2, 3)
            $null = Assert-NotBitwiseFlag -Actual $values -Expected 4 -Each
        }

        It 'Should pass when all elements do not have the flag set with -Each -All' {
            $values = @(1, 2, 3)
            $null = Assert-NotBitwiseFlag -Actual $values -Expected 4 -Each -All
        }

        It 'Should throw when one element has the flag set with -Each (default -All)' {
            $values = @(1, 7, 3)
            { Assert-NotBitwiseFlag -Actual $values -Expected 4 -Each } | Should -Throw -ExpectedMessage "*NOT to have flag '4' set*set on '7'*"
        }

        It 'Should throw when one element has the flag set with -Each -All' {
            $values = @(1, 7, 3)
            { Assert-NotBitwiseFlag -Actual $values -Expected 4 -Each -All } | Should -Throw -ExpectedMessage "*NOT to have flag '4' set*set on '7'*"
        }

        It 'Should pass when at least one element does not have the flag set with -Each -Any' {
            $values = @(7, 3, 7)
            $null = Assert-NotBitwiseFlag -Actual $values -Expected 4 -Each -Any
        }

        It 'Should throw when all elements have the flag set with -Each -Any' {
            $values = @(7, 15, 23)
            { Assert-NotBitwiseFlag -Actual $values -Expected 4 -Each -Any } | Should -Throw -ExpectedMessage "*at least one element NOT to have flag '4' set*"
        }

        It 'Should throw with empty array' {
            $values = @()
            { Assert-NotBitwiseFlag -Actual $values -Expected 4 -Each } | Should -Throw -ExpectedMessage "*bitwise-compatible type*"
        }

        It 'Should pass with single-element array' {
            $values = @(3)
            $null = Assert-NotBitwiseFlag -Actual $values -Expected 4 -Each
        }

        It 'Should throw when array contains null element' {
            $values = @(3, $null, 1)
            { Assert-NotBitwiseFlag -Actual $values -Expected 4 -Each } | Should -Throw -ExpectedMessage "*parameter actual*bitwise-compatible type*"
        }

        It 'Should throw when array contains non-compatible type' {
            $values = @(3, 'string', 1)
            { Assert-NotBitwiseFlag -Actual $values -Expected 4 -Each } | Should -Throw -ExpectedMessage "*bitwise-compatible type*"
        }

        It 'Should pass when all elements in array do not have multiple flags' {
            $values = @(0b0001, 0b0010, 0b0001)
            $null = Assert-NotBitwiseFlag -Actual $values -Expected 0b1100 -Each
        }
    }

    Context 'When validating parameter combinations' {
        It 'Should fail parameter binding when -All and -Any are used together' {
            { Assert-NotBitwiseFlag -Actual @(3) -Expected 4 -Each -All -Any } | Should -Throw -ExpectedMessage "*parameter set*"
        }
    }

    Context 'When asserting flag on array without -Each parameter' {
        It 'Should throw when checking array object itself' {
            $values = @(1, 2, 3)
            { Assert-NotBitwiseFlag -Actual $values -Expected 4 } | Should -Throw -ExpectedMessage "*bitwise-compatible type*"
        }
    }

    Context 'When using pipeline input' {
        It 'Should pass when piping single value without flag set' {
            $null = 3 | Assert-NotBitwiseFlag -Expected 4
        }

        It 'Should throw when piping single value with flag set' {
            { 7 | Assert-NotBitwiseFlag -Expected 4 } | Should -Throw
        }

        It 'Should pass when piping array with -Each where no elements have flag (default -All)' {
            $null = @(1, 2, 3) | Assert-NotBitwiseFlag -Expected 4 -Each
        }

        It 'Should pass when piping array with -Each -All where no elements have flag' {
            $null = @(1, 2, 3) | Assert-NotBitwiseFlag -Expected 4 -Each -All
        }

        It 'Should pass when piping last element of array without -Each' {
            # When piping an array without -Each, only the last element is checked
            $null = @(7, 15, 3) | Assert-NotBitwiseFlag -Expected 4
        }

        It 'Should unwrap single-element array without -Each' {
            $null = @(3) | Assert-NotBitwiseFlag -Expected 4
        }

        It 'Should not unwrap single-element array with -Each' {
            $null = @(3) | Assert-NotBitwiseFlag -Expected 4 -Each
        }
    }

    Context 'When validating input types' {
        It 'Should throw when actual value is null' {
            { Assert-NotBitwiseFlag -Actual $null -Expected 4 } | Should -Throw
        }

        It 'Should throw when flag is null' {
            # PowerShell parameter binding catches null before function code
            { Assert-NotBitwiseFlag -Actual 7 -Expected $null } | Should -Throw
        }

        It 'Should throw when flag is string' {
            { Assert-NotBitwiseFlag -Actual 7 -Expected 'test' } | Should -Throw -ExpectedMessage "*parameter expected*bitwise-compatible type*"
        }

        It 'Should throw when flag is decimal' {
            { Assert-NotBitwiseFlag -Actual 7 -Expected 123.45 } | Should -Throw -ExpectedMessage "*parameter expected*bitwise-compatible type*"
        }

        It 'Should throw when flag is boolean' {
            { Assert-NotBitwiseFlag -Actual 7 -Expected $true } | Should -Throw -ExpectedMessage "*parameter expected*bitwise-compatible type*"
        }

        It 'Should throw when flag is hashtable' {
            { Assert-NotBitwiseFlag -Actual 7 -Expected @{ Key = 'Value' } } | Should -Throw -ExpectedMessage "*parameter expected*bitwise-compatible type*"
        }

        It 'Should throw when actual value is string' {
            { Assert-NotBitwiseFlag -Actual 'test' -Expected 4 } | Should -Throw -ExpectedMessage "*bitwise-compatible type*"
        }

        It 'Should throw when actual value is decimal' {
            { Assert-NotBitwiseFlag -Actual 123.45 -Expected 4 } | Should -Throw -ExpectedMessage "*bitwise-compatible type*"
        }

        It 'Should throw when actual value is boolean' {
            { Assert-NotBitwiseFlag -Actual $true -Expected 4 } | Should -Throw -ExpectedMessage "*bitwise-compatible type*"
        }

        It 'Should throw when actual value is hashtable' {
            { Assert-NotBitwiseFlag -Actual @{ Key = 'Value' } -Expected 4 } | Should -Throw -ExpectedMessage "*bitwise-compatible type*"
        }

        It 'Should pass when flag is enum and actual is integer without flag' {
            $null = Assert-NotBitwiseFlag -Actual 2 -Expected ([System.IO.FileAttributes]::ReadOnly)
        }

        It 'Should pass when flag is integer and actual is enum without flag' {
            $fileAttributes = [System.IO.FileAttributes]::Hidden
            $null = Assert-NotBitwiseFlag -Actual $fileAttributes -Expected 1
        }
    }

    Context 'When using -Because parameter' {
        It 'Should include reason in error message' {
            $reason = 'write permission should not be granted'
            { Assert-NotBitwiseFlag -Actual 7 -Expected 4 -Because $reason } | Should -Throw -ExpectedMessage "*$reason*"
        }

        It 'Should include reason in error message with -Each' {
            $values = @(1, 7, 3)
            $reason = 'no value should have this flag'
            { Assert-NotBitwiseFlag -Actual $values -Expected 4 -Each -Because $reason } | Should -Throw -ExpectedMessage "*$reason*"
        }
    }

    Context 'When using Should-NotHaveFlag alias' {
        It 'Should work with alias' {
            $null = Should-NotHaveFlag -Actual 3 -Expected 4
        }

        It 'Should throw with alias when flag is set' {
            { Should-NotHaveFlag -Actual 7 -Expected 4 } | Should -Throw
        }
    }

    Context 'When testing various integer types' {
        It 'Should pass with Byte type when flag not set' {
            $value = [System.Byte]3
            $null = Assert-NotBitwiseFlag -Actual $value -Expected 4
        }

        It 'Should pass with Int16 type when flag not set' {
            $value = [System.Int16]3
            $null = Assert-NotBitwiseFlag -Actual $value -Expected 4
        }

        It 'Should pass with UInt32 type when flag not set' {
            $value = [System.UInt32]3
            $null = Assert-NotBitwiseFlag -Actual $value -Expected 4
        }

        It 'Should pass with UInt64 type when flag not set' {
            $value = [System.UInt64]3
            $null = Assert-NotBitwiseFlag -Actual $value -Expected 4
        }
    }

    Context 'When testing edge cases with bitwise operations' {
        It 'Should pass when specific bit is not set' {
            $null = Assert-NotBitwiseFlag -Actual 0x7F -Expected 0x80
        }

        It 'Should throw when all bits are set' {
            { Assert-NotBitwiseFlag -Actual 0xFF -Expected 0x80 } | Should -Throw
        }

        It 'Should pass when checking single bit not in large value' {
            $value = 0x123456789ABCDEF
            $flag = 0x0000000000000010
            $null = Assert-NotBitwiseFlag -Actual $value -Expected $flag
        }

        It 'Should pass when none of the flag bits are set' {
            $value = 0b00001111
            $flag = 0b11110000
            $null = Assert-NotBitwiseFlag -Actual $value -Expected $flag
        }

        It 'Should pass when only some of the flag bits are set' {
            $value = 0b11010000
            $flag = 0b11110000
            $null = Assert-NotBitwiseFlag -Actual $value -Expected $flag
        }

        It 'Should pass with zero value and non-zero flag' {
            $null = Assert-NotBitwiseFlag -Actual 0 -Expected 4
        }

        It 'Should throw with zero value and zero flag' {
            { Assert-NotBitwiseFlag -Actual 0 -Expected 0 } | Should -Throw
        }

        It 'Should throw when value has all flag bits set' {
            $value = 0xFF
            $flag = 0x0F
            { Assert-NotBitwiseFlag -Actual $value -Expected $flag } | Should -Throw
        }
    }

    Context 'When testing with large bit values' {
        It 'Should pass when 64-bit flag is not set' {
            $largeValue = [System.Int64]0x0000000000000001
            $null = Assert-NotBitwiseFlag -Actual $largeValue -Expected ([System.Int64]0x8000000000000000)
        }

        It 'Should throw when 64-bit flag is set' {
            $largeValue = [System.Int64]0x8000000000000001
            { Assert-NotBitwiseFlag -Actual $largeValue -Expected ([System.Int64]0x8000000000000000) } | Should -Throw
        }
    }

    Context 'When testing Get-ProcessedPipelineInput integration' {
        It 'Should handle pipeline input correctly through a wrapper function' {
            InModuleScope -ScriptBlock {
                # Create a wrapper that demonstrates Get-ProcessedPipelineInput behavior
                # This indirectly tests the $Actual = $processedInput line
                function Test-NotBitwiseFlagWrapper {
                    [CmdletBinding()]
                    param(
                        [Parameter(ValueFromPipeline)]
                        $InputValue,

                        [Parameter()]
                        $Expected
                    )

                    # Simulate what Assert-NotBitwiseFlag does
                    $processedInput = Get-ProcessedPipelineInput -InvocationInfo $MyInvocation
                    
                    if ($null -ne $processedInput) {
                        # This line mirrors what Assert-NotBitwiseFlag does
                        $testValue = $processedInput
                        Assert-NotBitwiseFlag -Actual $testValue -Expected $Expected
                    }
                    else {
                        Assert-NotBitwiseFlag -Actual $InputValue -Expected $Expected
                    }
                }

                # Test with pipeline input
                $null = 3 | Test-NotBitwiseFlagWrapper -Expected 4
            }
        }

        It 'Should properly unwrap single-element arrays from pipeline' {
            # This tests the interaction between pipeline processing and Get-ProcessedPipelineInput
            # When a single-element array is piped, it should be unwrapped
            $result = @(3) | Assert-NotBitwiseFlag -Expected 4
            $result | Should -BeNullOrEmpty
        }

        It 'Should handle multiple values with -Each parameter' {
            # Tests that -Each parameter properly processes array inputs
            $result = @(3, 2, 1) | Assert-NotBitwiseFlag -Expected 4 -Each
            $result | Should -BeNullOrEmpty
        }
    }
}
