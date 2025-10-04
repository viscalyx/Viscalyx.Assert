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

Describe 'Get-TypeName' {
    Context 'When getting type name of null value' {
        It 'Should return the string "null"' {
            InModuleScope -ScriptBlock {
                $result = Get-TypeName -Value $null

                $result | Should-BeString -CaseSensitive 'null'
            }
        }
    }

    Context 'When getting type name of primitive types' {
        It 'Should return "System.String" for a string value' {
            InModuleScope -ScriptBlock {
                $result = Get-TypeName -Value 'Hello'

                $result | Should-BeString -CaseSensitive 'System.String'
            }
        }

        It 'Should return "System.Int32" for an integer value' {
            InModuleScope -ScriptBlock {
                $result = Get-TypeName -Value 123

                $result | Should-BeString -CaseSensitive 'System.Int32'
            }
        }

        It 'Should return "System.Int64" for a long integer value' {
            InModuleScope -ScriptBlock {
                $result = Get-TypeName -Value ([System.Int64] 123)

                $result | Should-BeString -CaseSensitive 'System.Int64'
            }
        }

        It 'Should return "System.Double" for a double value' {
            InModuleScope -ScriptBlock {
                $result = Get-TypeName -Value 123.45

                $result | Should-BeString -CaseSensitive 'System.Double'
            }
        }

        It 'Should return "System.Boolean" for a boolean value' {
            InModuleScope -ScriptBlock {
                $result = Get-TypeName -Value $true

                $result | Should-BeString -CaseSensitive 'System.Boolean'
            }
        }
    }

    Context 'When getting type name of collection types' {
        It 'Should return "System.Object[]" for an array' {
            InModuleScope -ScriptBlock {
                $result = Get-TypeName -Value @(1, 2, 3)

                $result | Should-BeString -CaseSensitive 'System.Object[]'
            }
        }

        It 'Should return "System.Int32[]" for a strongly-typed integer array' {
            InModuleScope -ScriptBlock {
                $result = Get-TypeName -Value ([System.Int32[]] @(1, 2, 3))

                $result | Should-BeString -CaseSensitive 'System.Int32[]'
            }
        }

        It 'Should return "System.Collections.Hashtable" for a hashtable' {
            InModuleScope -ScriptBlock {
                $result = Get-TypeName -Value @{ Name = 'Test' }

                $result | Should-BeString -CaseSensitive 'System.Collections.Hashtable'
            }
        }
    }

    Context 'When getting type name of custom objects' {
        It 'Should return "System.Management.Automation.PSCustomObject" for a PSCustomObject' {
            InModuleScope -ScriptBlock {
                $customObject = [PSCustomObject] @{
                    Name  = 'Test'
                    Value = 123
                }

                $result = Get-TypeName -Value $customObject

                $result | Should-BeString -CaseSensitive 'System.Management.Automation.PSCustomObject'
            }
        }
    }
}
