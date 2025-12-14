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
}

AfterAll {
    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:moduleName -All | Remove-Module -Force
}

Describe 'Assert-NotBitwiseFlag' -Tag @('Integration') {
    Context 'When validating file system permissions' {
        It 'Should validate that Hidden flag is not set' {
            # Simulate checking file attributes
            $fileAttributes = [System.IO.FileAttributes]::ReadOnly -bor [System.IO.FileAttributes]::Archive

            # This demonstrates using Assert-NotBitwiseFlag for file attribute validation
            $fileAttributes | Should-NotHaveFlag -Flag ([System.IO.FileAttributes]::Hidden)
        }

        It 'Should validate multiple file attributes are not set' {
            # Simulate checking file attributes
            $fileAttributes = [System.IO.FileAttributes]::ReadOnly

            # Check that Hidden and System flags are not set
            $fileAttributes | Should-NotHaveFlag -Flag ([System.IO.FileAttributes]::Hidden)
            $fileAttributes | Should-NotHaveFlag -Flag ([System.IO.FileAttributes]::System)
        }

        It 'Should validate specific combination of flags is not present' {
            # Simulate checking file attributes
            $fileAttributes = [System.IO.FileAttributes]::ReadOnly

            # Check that both Hidden and System are not both set together
            $combinedFlags = [System.IO.FileAttributes]::Hidden -bor [System.IO.FileAttributes]::System
            $fileAttributes | Should-NotHaveFlag -Flag $combinedFlags
        }
    }

    Context 'When validating permission masks in security scenarios' {
        It 'Should validate write permission is not set for group' {
            # Simulate Unix-style permissions: rwxr-xr-x (755)
            $permissions = 0755

            # Check that write permission for group (bit 4: 0020 in octal) is not set
            $permissions | Should-NotHaveFlag -Flag 0020
        }

        It 'Should validate write permission is not set for others' {
            # Simulate Unix-style permissions: rwxr-x--- (750)
            $permissions = 0750

            # Check that any permission for others is not set
            $permissions | Should-NotHaveFlag -Flag 0007
        }

        It 'Should validate setuid bit is not set' {
            # Simulate Unix-style permissions: rwxr-xr-x (755)
            $permissions = 0755

            # Check that setuid bit (04000) is not set
            $permissions | Should-NotHaveFlag -Flag 04000
        }
    }

    Context 'When validating flags in configuration management' {
        It 'Should validate feature flag is disabled' {
            # Simulate feature flags configuration
            $enabledFeatures = 0b1011  # Features A, B, and D are enabled

            # Validate FeatureC (bit 2: 0b0100) is not enabled
            $enabledFeatures | Should-NotHaveFlag -Flag 0b0100
        }

        It 'Should validate multiple features are disabled' {
            # Simulate feature flags configuration
            $enabledFeatures = 0b0011  # Only Features A and B are enabled

            # Validate FeatureC and FeatureD are not enabled
            $enabledFeatures | Should-NotHaveFlag -Flag 0b0100  # FeatureC
            $enabledFeatures | Should-NotHaveFlag -Flag 0b1000  # FeatureD
        }

        It 'Should validate deprecated feature is not enabled' {
            # Simulate feature flags configuration
            $enabledFeatures = 0b00001111  # First 4 features enabled

            # Validate deprecated feature (bit 5: 0b00010000) is not enabled
            $enabledFeatures | Should-NotHaveFlag -Flag 0b00010000
        }
    }

    Context 'When validating enum flags in real-world scenarios' {
        It 'Should validate System.Reflection.BindingFlags does not have Static flag' {
            # Simulate binding flags for reflection operations
            $bindingFlags = [System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::Instance

            # Validate that Static flag is not set
            $bindingFlags | Should-NotHaveFlag -Flag ([System.Reflection.BindingFlags]::Static)
        }

        It 'Should validate System.Text.RegularExpressions.RegexOptions does not have unwanted flags' {
            # Simulate regex options
            $regexOptions = [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [System.Text.RegularExpressions.RegexOptions]::Multiline

            # Validate that Singleline option is not set
            $regexOptions | Should-NotHaveFlag -Flag ([System.Text.RegularExpressions.RegexOptions]::Singleline)

            # Validate that ExplicitCapture is not set
            $regexOptions | Should-NotHaveFlag -Flag ([System.Text.RegularExpressions.RegexOptions]::ExplicitCapture)
        }
    }

    Context 'When validating bit masks in network programming' {
        It 'Should validate TCP FIN flag is not set' {
            # Simulate TCP flags: SYN=0x02, ACK=0x10
            # SYN-ACK packet would have both flags set
            $tcpFlags = 0x12  # SYN + ACK

            # Validate FIN flag is not set
            $tcpFlags | Should-NotHaveFlag -Flag 0x01
        }

        It 'Should validate TCP RST flag is not set in normal communication' {
            # Simulate TCP flags for normal data transfer: ACK=0x10, PSH=0x08
            $tcpFlags = 0x18  # ACK + PSH

            # Validate RST flag is not set
            $tcpFlags | Should-NotHaveFlag -Flag 0x04
        }

        It 'Should validate IP More Fragments flag is not set' {
            # Simulate IP flags: Don't Fragment=0x4000
            $ipFlags = 0x4000

            # Validate More Fragments is not set
            $ipFlags | Should-NotHaveFlag -Flag 0x2000
        }
    }

    Context 'When validating flags in testing frameworks' {
        It 'Should validate StopOnFailure is not enabled' {
            # Simulate test execution options
            $testOptions = 11  # ParallelExecution + VerboseOutput + GenerateCoverage (1+2+8)

            # Validate StopOnFailure is not enabled
            $testOptions | Should-NotHaveFlag -Flag 4
        }

        It 'Should validate debug mode is not enabled' {
            # Simulate production test execution options
            $testOptions = 1  # Only ParallelExecution

            # Validate debug flags are not enabled
            $testOptions | Should-NotHaveFlag -Flag 16  # DebugMode
            $testOptions | Should-NotHaveFlag -Flag 32  # VerboseDebug
        }
    }

    Context 'When validating flags with Because parameter for documentation' {
        It 'Should provide clear error messages when validating flag should not be set' {
            # Simulate security permissions
            $guestPermissions = 0b0101  # Read and execute permissions

            # This would fail with descriptive message
            {
                $guestPermissions | Should-NotHaveFlag -Flag 0b0100 -Because 'guest users should not have execute permission'
            } | Should-Throw -Because 'the error should mention the security context'
        }

        It 'Should provide clear error messages for security validation' {
            # Simulate checking admin permissions
            $userPermissions = 0b0001  # Only read permission

            # This will pass
            $userPermissions | Should-NotHaveFlag -Flag 0b1000 -Because 'regular users should not have admin privileges'
        }
    }

    Context 'When validating large bit values' {
        It 'Should handle 64-bit flag values that are not set' {
            # Simulate 64-bit flag value
            $largeValue = [System.Int64]0x0000000000000001

            # Check that high bit is not set
            $largeValue | Should-NotHaveFlag -Flag ([System.Int64]0x8000000000000000)
        }

        It 'Should validate specific bits are not set in large values' {
            # Simulate large bit mask
            $value = [System.Int64]0x00000000FFFFFFFF

            # Validate high 32 bits are not set
            $value | Should-NotHaveFlag -Flag ([System.Int64]0xFFFF000000000000)
        }
    }

    Context 'When processing multiple values in pipeline' {
        It 'Should validate flags are not set on multiple values with -Each -All' {
            # Simulate guest account permissions (all should have only read)
            $guestPermissions = @(
                0b001,  # Read only
                0b001,  # Read only
                0b001   # Read only
            )

            # Validate that no guest has write permission
            $guestPermissions | Should-NotHaveFlag -Flag 0b010 -Each -All
        }

        It 'Should validate administrative flags are not set on user accounts with -Each -All' {
            # Simulate multiple user permissions
            $userPermissions = @(
                0b0011,  # Read and write
                0b0001,  # Read only
                0b0011   # Read and write
            )

            # Validate that no user has admin flag (0b1000)
            $userPermissions | Should-NotHaveFlag -Flag 0b1000 -Each -All
        }

        It 'Should validate dangerous flags are not present in any configuration with -Each -All' {
            # Simulate multiple configuration sets
            $configurations = @(
                0b00001111,  # Safe features
                0b00000111,  # Safe features
                0b00001011   # Safe features
            )

            # Validate dangerous flag (0b10000000) is not present in any config
            $configurations | Should-NotHaveFlag -Flag 0b10000000 -Each -All
        }

        It 'Should validate at least one value does not have flag with -Each -Any' {
            # Simulate multiple permission sets
            $permissions = @(
                0b111,  # Read, Write, Execute
                0b001,  # Read only (no execute)
                0b111   # Read, Write, Execute
            )

            # Validate at least one user does not have execute permission
            Should-NotHaveFlag -Actual $permissions -Flag 0b100 -Each -Any
        }
    }

    Context 'When validating security-critical scenarios' {
        It 'Should ensure elevated privileges are not accidentally granted' {
            # Simulate user permissions
            $normalUserPerms = 0x0001  # Read only

            # Ensure admin bit is not set
            $normalUserPerms | Should-NotHaveFlag -Flag 0x8000 -Because 'normal users should never have admin privileges'
        }

        It 'Should validate write access is properly restricted' {
            # Simulate read-only access
            $readOnlyAccess = 0x0004  # Read permission

            # Ensure write and delete are not granted
            $readOnlyAccess | Should-NotHaveFlag -Flag 0x0002 -Because 'read-only users cannot have write access'
            $readOnlyAccess | Should-NotHaveFlag -Flag 0x0008 -Because 'read-only users cannot have delete access'
        }
    }
}
