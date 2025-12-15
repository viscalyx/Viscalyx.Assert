[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Suppressing this rule because Script Analyzer does not understand Pester syntax.')]
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

Describe 'Assert-BitwiseType' {
    Context 'When validating compatible types' {
        It 'Should not throw for valid integer types' {
            InModuleScope -ScriptBlock {
                # Use actual invocation info from the calling function
                $mockInvocation = $MyInvocation

                { Assert-BitwiseType -Value 42 -ParameterName 'TestParam' -InvocationInfo $mockInvocation } | Should -Not -Throw
                { Assert-BitwiseType -Value ([Int64]::MaxValue) -ParameterName 'TestParam' -InvocationInfo $mockInvocation } | Should -Not -Throw
                { Assert-BitwiseType -Value ([Byte]255) -ParameterName 'TestParam' -InvocationInfo $mockInvocation } | Should -Not -Throw
            }
        }

        It 'Should not throw for enum types' {
            InModuleScope -ScriptBlock {
                # Use actual invocation info from the calling function
                $mockInvocation = $MyInvocation

                { Assert-BitwiseType -Value ([System.IO.FileAttributes]::ReadOnly) -ParameterName 'TestParam' -InvocationInfo $mockInvocation } | Should -Not -Throw
            }
        }
    }

    Context 'When validating incompatible types' {
        It 'Should throw for null value' {
            InModuleScope -ScriptBlock {
                # Use actual invocation info from the calling function
                $mockInvocation = $MyInvocation

                { Assert-BitwiseType -Value $null -ParameterName 'TestParam' -InvocationInfo $mockInvocation } |
                    Should -Throw -ExpectedMessage '*parameter TestParam*null*'
            }
        }

        It 'Should throw for string type' {
            InModuleScope -ScriptBlock {
                # Use actual invocation info from the calling function
                $mockInvocation = $MyInvocation

                { Assert-BitwiseType -Value 'not a number' -ParameterName 'TestParam' -InvocationInfo $mockInvocation } |
                    Should -Throw -ExpectedMessage '*parameter TestParam*System.String*'
            }
        }

        It 'Should throw for decimal type' {
            InModuleScope -ScriptBlock {
                # Use actual invocation info from the calling function
                $mockInvocation = $MyInvocation

                { Assert-BitwiseType -Value 3.14 -ParameterName 'TestParam' -InvocationInfo $mockInvocation } |
                    Should -Throw -ExpectedMessage '*parameter TestParam*System.Double*'
            }
        }

        It 'Should throw for boolean type' {
            InModuleScope -ScriptBlock {
                # Use actual invocation info from the calling function
                $mockInvocation = $MyInvocation

                { Assert-BitwiseType -Value $true -ParameterName 'TestParam' -InvocationInfo $mockInvocation } |
                    Should -Throw -ExpectedMessage '*parameter TestParam*System.Boolean*'
            }
        }

        It 'Should throw for hashtable type' {
            InModuleScope -ScriptBlock {
                # Use actual invocation info from the calling function
                $mockInvocation = $MyInvocation

                { Assert-BitwiseType -Value @{} -ParameterName 'TestParam' -InvocationInfo $mockInvocation } |
                    Should -Throw -ExpectedMessage '*parameter TestParam*System.Collections.Hashtable*'
            }
        }
    }

    Context 'When using -Because parameter' {
        It 'Should include reason in error message' {
            InModuleScope -ScriptBlock {
                { Assert-BitwiseType -Value 'invalid' -ParameterName 'TestParam' -Because 'testing error message' -InvocationInfo $MyInvocation } |
                    Should -Throw -ExpectedMessage '*because testing error message*'
            }
        }
    }

    Context 'When using different parameter names' {
        It 'Should include Expected parameter name in error message' {
            InModuleScope -ScriptBlock {
                # Use actual invocation info from the calling function
                $mockInvocation = $MyInvocation

                { Assert-BitwiseType -Value 'invalid' -ParameterName $script:localizedData.Common_WordExpected -InvocationInfo $mockInvocation } |
                    Should -Throw -ExpectedMessage '*parameter expected*'
            }
        }

        It 'Should include Actual parameter name in error message' {
            InModuleScope -ScriptBlock {
                # Use actual invocation info from the calling function
                $mockInvocation = $MyInvocation

                { Assert-BitwiseType -Value 'invalid' -ParameterName $script:localizedData.Common_WordActual -InvocationInfo $mockInvocation } |
                    Should -Throw -ExpectedMessage '*parameter actual*'
            }
        }
    }
}
