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

Describe 'Assert-BitwiseFlag' {
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
            $result = (Get-Command -Name 'Assert-BitwiseFlag').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }

        It 'Should have Flag parameter as mandatory' {
            (Get-Command -Name 'Assert-BitwiseFlag').Parameters['Expected'].Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have Actual parameter as mandatory' {
            (Get-Command -Name 'Assert-BitwiseFlag').Parameters['Actual'].Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have Actual parameter accept pipeline input' {
            (Get-Command -Name 'Assert-BitwiseFlag').Parameters['Actual'].Attributes.ValueFromPipeline | Should -BeTrue
        }
    }

    Context 'When asserting flag is set on single values' {
        It 'Should pass when flag is set' {
            $null = Assert-BitwiseFlag -Actual 7 -Expected 4
        }

        It 'Should pass when multiple flags are set' {
            $null = Assert-BitwiseFlag -Actual 15 -Expected 5
        }

        It 'Should throw when flag is not set' {
            { Assert-BitwiseFlag -Actual 3 -Expected 4 } | Should -Throw -ExpectedMessage "*flag '4' set*not set on '3'*"
        }

        It 'Should pass when flag is set with zero flag value' {
            $null = Assert-BitwiseFlag -Actual 7 -Expected 0
        }

        It 'Should pass when using enum flag that is set' {
            $fileAttributes = [System.IO.FileAttributes]::ReadOnly -bor [System.IO.FileAttributes]::Hidden
            $null = Assert-BitwiseFlag -Actual $fileAttributes -Expected ([System.IO.FileAttributes]::ReadOnly)
        }

        It 'Should throw when using enum flag that is not set' {
            $fileAttributes = [System.IO.FileAttributes]::ReadOnly
            { Assert-BitwiseFlag -Actual $fileAttributes -Expected ([System.IO.FileAttributes]::Hidden) } | Should -Throw
        }

        It 'Should pass with large Int64 values' {
            $value = [System.Int64]0x8000000000000001
            $flag = [System.Int64]0x8000000000000000
            $null = Assert-BitwiseFlag -Actual $value -Expected $flag
        }

        It 'Should pass with negative values' {
            $null = Assert-BitwiseFlag -Actual (-1) -Expected 1
        }
    }

    Context 'When asserting flag on array with -Each parameter' {
        It 'Should pass when all elements have the flag set (default -All behavior)' {
            $values = @(7, 15, 23)
            $null = Assert-BitwiseFlag -Actual $values -Expected 4 -Each
        }

        It 'Should pass when all elements have the flag set with -Each -All' {
            $values = @(7, 15, 23)
            $null = Assert-BitwiseFlag -Actual $values -Expected 4 -Each -All
        }

        It 'Should throw when one element does not have the flag set with -Each (default -All)' {
            $values = @(7, 3, 15)
            { Assert-BitwiseFlag -Actual $values -Expected 4 -Each } | Should -Throw -ExpectedMessage "*flag '4' set*not set on '3'*"
        }

        It 'Should throw when one element does not have the flag set with -Each -All' {
            $values = @(7, 3, 15)
            { Assert-BitwiseFlag -Actual $values -Expected 4 -Each -All } | Should -Throw -ExpectedMessage "*flag '4' set*not set on '3'*"
        }

        It 'Should pass when at least one element has the flag set with -Each -Any' {
            $values = @(1, 7, 3)
            $null = Assert-BitwiseFlag -Actual $values -Expected 4 -Each -Any
        }

        It 'Should throw when no elements have the flag set with -Each -Any' {
            $values = @(1, 2, 3)
            { Assert-BitwiseFlag -Actual $values -Expected 4 -Each -Any } | Should -Throw -ExpectedMessage "*at least one element*flag '4' set*"
        }

        It 'Should throw with empty array' {
            $values = @()
            { Assert-BitwiseFlag -Actual $values -Expected 4 -Each } | Should -Throw -ExpectedMessage "*bitwise-compatible type*"
        }

        It 'Should pass with single-element array' {
            $values = @(7)
            $null = Assert-BitwiseFlag -Actual $values -Expected 4 -Each
        }

        It 'Should throw when array contains null element' {
            $values = @(7, $null, 15)
            { Assert-BitwiseFlag -Actual $values -Expected 4 -Each } | Should -Throw -ExpectedMessage "*parameter actual*bitwise-compatible type*"
        }

        It 'Should throw when array contains non-compatible type' {
            $values = @(7, 'string', 15)
            { Assert-BitwiseFlag -Actual $values -Expected 4 -Each } | Should -Throw -ExpectedMessage "*bitwise-compatible type*"
        }
    }

    Context 'When validating parameter combinations' {
        It 'Should fail parameter binding when -All and -Any are used together' {
            { Assert-BitwiseFlag -Actual @(7) -Expected 4 -Each -All -Any } | Should -Throw -ExpectedMessage "*parameter set*"
        }
    }

    Context 'When asserting flag on array without -Each parameter' {
        It 'Should throw when checking array object itself' {
            $values = @(7, 15, 23)
            { Assert-BitwiseFlag -Actual $values -Expected 4 } | Should -Throw -ExpectedMessage "*bitwise-compatible type*"
        }
    }

    Context 'When using pipeline input' {
        It 'Should pass when piping single value with flag set' {
            $null = 7 | Assert-BitwiseFlag -Expected 4
        }

        It 'Should throw when piping single value without flag set' {
            { 3 | Assert-BitwiseFlag -Expected 4 } | Should -Throw
        }

        It 'Should pass when piping array with -Each (default -All)' {
            $null = @(7, 15, 23) | Assert-BitwiseFlag -Expected 4 -Each
        }

        It 'Should pass when piping array with -Each -All' {
            $null = @(7, 15, 23) | Assert-BitwiseFlag -Expected 4 -Each -All
        }

        It 'Should pass when piping last element of array without -Each' {
            # When piping an array without -Each, only the last element is checked
            $null = @(1, 2, 7) | Assert-BitwiseFlag -Expected 4
        }

        It 'Should unwrap single-element array without -Each' {
            $null = @(7) | Assert-BitwiseFlag -Expected 4
        }

        It 'Should not unwrap single-element array with -Each' {
            $null = @(7) | Assert-BitwiseFlag -Expected 4 -Each
        }
    }

    Context 'When validating input types' {
        It 'Should throw when actual value is null' {
            { Assert-BitwiseFlag -Actual $null -Expected 4 } | Should -Throw
        }

        It 'Should throw when flag is null' {
            # PowerShell parameter binding catches null before function code
            { Assert-BitwiseFlag -Actual 7 -Expected $null } | Should -Throw
        }

        It 'Should throw when flag is string' {
            { Assert-BitwiseFlag -Actual 7 -Expected 'test' } | Should -Throw -ExpectedMessage "*parameter expected*bitwise-compatible type*"
        }

        It 'Should throw when flag is decimal' {
            { Assert-BitwiseFlag -Actual 7 -Expected 123.45 } | Should -Throw -ExpectedMessage "*parameter expected*bitwise-compatible type*"
        }

        It 'Should throw when flag is boolean' {
            { Assert-BitwiseFlag -Actual 7 -Expected $true } | Should -Throw -ExpectedMessage "*parameter expected*bitwise-compatible type*"
        }

        It 'Should throw when flag is hashtable' {
            { Assert-BitwiseFlag -Actual 7 -Expected @{ Key = 'Value' } } | Should -Throw -ExpectedMessage "*parameter expected*bitwise-compatible type*"
        }

        It 'Should throw when actual value is string' {
            { Assert-BitwiseFlag -Actual 'test' -Expected 4 } | Should -Throw -ExpectedMessage "*bitwise-compatible type*"
        }

        It 'Should throw when actual value is decimal' {
            { Assert-BitwiseFlag -Actual 123.45 -Expected 4 } | Should -Throw -ExpectedMessage "*bitwise-compatible type*"
        }

        It 'Should throw when actual value is boolean' {
            { Assert-BitwiseFlag -Actual $true -Expected 4 } | Should -Throw -ExpectedMessage "*bitwise-compatible type*"
        }

        It 'Should throw when actual value is hashtable' {
            { Assert-BitwiseFlag -Actual @{ Key = 'Value' } -Expected 4 } | Should -Throw -ExpectedMessage "*bitwise-compatible type*"
        }

        It 'Should pass when flag is enum and actual is integer' {
            $null = Assert-BitwiseFlag -Actual 1 -Expected ([System.IO.FileAttributes]::ReadOnly)
        }

        It 'Should pass when flag is integer and actual is enum' {
            $fileAttributes = [System.IO.FileAttributes]::ReadOnly
            $null = Assert-BitwiseFlag -Actual $fileAttributes -Expected 1
        }
    }

    Context 'When using -Because parameter' {
        It 'Should include reason in error message' {
            $reason = 'execute permission is required'
            { Assert-BitwiseFlag -Actual 3 -Expected 4 -Because $reason } | Should -Throw -ExpectedMessage "*$reason*"
        }

        It 'Should include reason in error message with -Each' {
            $values = @(7, 3, 15)
            $reason = 'all values must have flag'
            { Assert-BitwiseFlag -Actual $values -Expected 4 -Each -Because $reason } | Should -Throw -ExpectedMessage "*$reason*"
        }
    }

    Context 'When using Should-HaveFlag alias' {
        It 'Should work with alias' {
            $null = Should-HaveFlag -Actual 7 -Expected 4
        }

        It 'Should throw with alias when flag not set' {
            { Should-HaveFlag -Actual 3 -Expected 4 } | Should -Throw
        }
    }

    Context 'When testing various integer types' {
        It 'Should pass with Byte type' {
            $value = [System.Byte]7
            $null = Assert-BitwiseFlag -Actual $value -Expected 4
        }

        It 'Should pass with Int16 type' {
            $value = [System.Int16]7
            $null = Assert-BitwiseFlag -Actual $value -Expected 4
        }

        It 'Should pass with UInt32 type' {
            $value = [System.UInt32]7
            $null = Assert-BitwiseFlag -Actual $value -Expected 4
        }

        It 'Should pass with UInt64 type' {
            $value = [System.UInt64]7
            $null = Assert-BitwiseFlag -Actual $value -Expected 4
        }
    }

    Context 'When testing edge cases with bitwise operations' {
        It 'Should pass when all bits are set' {
            $null = Assert-BitwiseFlag -Actual 0xFF -Expected 0x80
        }

        It 'Should pass when checking single bit in large value' {
            $value = 0x123456789ABCDEF
            $flag = 0x0000000000000001
            $null = Assert-BitwiseFlag -Actual $value -Expected $flag
        }

        It 'Should pass when checking multiple bits' {
            $value = 0b11110000
            $flag = 0b11000000
            $null = Assert-BitwiseFlag -Actual $value -Expected $flag
        }

        It 'Should throw when only some of the flag bits are set' {
            $value = 0b11010000
            $flag = 0b11110000
            { Assert-BitwiseFlag -Actual $value -Expected $flag } | Should -Throw
        }

        It 'Should pass with zero value and zero flag' {
            $null = Assert-BitwiseFlag -Actual 0 -Expected 0
        }

        It 'Should throw with zero value and non-zero flag' {
            { Assert-BitwiseFlag -Actual 0 -Expected 4 } | Should -Throw
        }
    }

    Context 'When testing Get-ProcessedPipelineInput integration' {
        It 'Should handle pipeline input correctly through a wrapper function' {
            InModuleScope -ScriptBlock {
                # Create a wrapper that demonstrates Get-ProcessedPipelineInput behavior
                # This indirectly tests the $Actual = $processedInput line
                function Test-BitwiseFlagWrapper {
                    [CmdletBinding()]
                    param(
                        [Parameter(ValueFromPipeline)]
                        $InputValue,

                        [Parameter()]
                        $Expected
                    )

                    # Simulate what Assert-BitwiseFlag does
                    $processedInput = Get-ProcessedPipelineInput -InvocationInfo $MyInvocation

                    if ($null -ne $processedInput) {
                        # This line mirrors what Assert-BitwiseFlag does
                        $testValue = $processedInput
                        Assert-BitwiseFlag -Actual $testValue -Expected $Expected
                    }
                    else {
                        Assert-BitwiseFlag -Actual $InputValue -Expected $Expected
                    }
                }

                # Test with pipeline input
                $null = 7 | Test-BitwiseFlagWrapper -Expected 4
            }
        }

        It 'Should properly unwrap single-element arrays from pipeline' {
            # This tests the interaction between pipeline processing and Get-ProcessedPipelineInput
            # When a single-element array is piped, it should be unwrapped
            $result = @(7) | Assert-BitwiseFlag -Expected 4
            $result | Should -BeNullOrEmpty
        }

        It 'Should handle multiple values with -Each parameter' {
            # Tests that -Each parameter properly processes array inputs
            $result = @(7, 15, 23) | Assert-BitwiseFlag -Expected 4 -Each
            $result | Should -BeNullOrEmpty
        }
    }
}
