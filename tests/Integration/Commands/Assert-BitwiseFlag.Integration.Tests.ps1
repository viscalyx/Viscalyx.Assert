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

Describe 'Assert-BitwiseFlag' -Tag @('Integration') {
    Context 'When validating file system permissions' {
        It 'Should validate file attributes using ReadOnly flag' {
            # Simulate checking file attributes
            $fileAttributes = [System.IO.FileAttributes]::ReadOnly -bor [System.IO.FileAttributes]::Archive

            # This demonstrates using Assert-BitwiseFlag for file attribute validation
            $fileAttributes | Should-HaveFlag -Expected ([System.IO.FileAttributes]::ReadOnly)
        }

        It 'Should validate multiple file attributes are set' {
            # Simulate checking file attributes with multiple flags
            $fileAttributes = [System.IO.FileAttributes]::ReadOnly -bor [System.IO.FileAttributes]::Hidden -bor [System.IO.FileAttributes]::System

            # Check each flag individually
            $fileAttributes | Should-HaveFlag -Expected ([System.IO.FileAttributes]::ReadOnly)
            $fileAttributes | Should-HaveFlag -Expected ([System.IO.FileAttributes]::Hidden)
            $fileAttributes | Should-HaveFlag -Expected ([System.IO.FileAttributes]::System)
        }

        It 'Should validate combined file attributes flags' {
            # Simulate checking file attributes
            $fileAttributes = [System.IO.FileAttributes]::ReadOnly -bor [System.IO.FileAttributes]::Hidden

            # Check that both ReadOnly and Hidden are set together
            $combinedFlags = [System.IO.FileAttributes]::ReadOnly -bor [System.IO.FileAttributes]::Hidden
            $fileAttributes | Should-HaveFlag -Expected $combinedFlags
        }
    }

    Context 'When validating permission masks in security scenarios' {
        It 'Should validate read permission is set in Unix-style permissions' {
            # Simulate Unix-style permissions: rwxr-xr-x (755 octal = 493 decimal = 0x1ED)
            $permissions = 0x1ED

            # Check read permission for owner (bit 8: 0400 octal = 256 decimal = 0x100)
            $permissions | Should-HaveFlag -Expected 0x100
        }

        It 'Should validate execute permission is set for all users' {
            # Simulate Unix-style permissions: rwxr-xr-x (755 octal = 493 decimal = 0x1ED)
            $permissions = 0x1ED

            # Check execute permission for owner, group, and others
            $permissions | Should-HaveFlag -Expected 0x40  # Owner execute (64 decimal)
            $permissions | Should-HaveFlag -Expected 0x08  # Group execute (8 decimal)
            $permissions | Should-HaveFlag -Expected 0x01  # Others execute (1 decimal)
        }
    }

    Context 'When validating flags in configuration management' {
        It 'Should validate feature flags are enabled' {
            # Simulate feature flags configuration
            # Bit 0: FeatureA, Bit 1: FeatureB, Bit 2: FeatureC, Bit 3: FeatureD
            $enabledFeatures = 0b1011  # Features A, B, and D are enabled

            # Validate specific features are enabled
            $enabledFeatures | Should-HaveFlag -Expected 0b0001  # FeatureA
            $enabledFeatures | Should-HaveFlag -Expected 0b0010  # FeatureB
            $enabledFeatures | Should-HaveFlag -Expected 0b1000  # FeatureD
        }

        It 'Should validate multiple feature flags using array with -Each -All' {
            # Simulate multiple configuration objects
            $configs = @(
                0b1111,  # All features enabled
                0b1110,  # Features B, C, D enabled
                0b1100   # Features C, D enabled
            )

            # Validate that all configs have FeatureC (bit 2: 0b0100) enabled
            $configs | Should-HaveFlag -Expected 0b0100 -Each -All
        }

        It 'Should validate at least one feature flag using array with -Each -Any' {
            # Simulate multiple configuration objects
            $configs = @(
                0b0001,  # Only FeatureA enabled
                0b0110,  # Features B, C enabled
                0b1000   # Only FeatureD enabled
            )

            # Validate that at least one config has FeatureC (bit 2: 0b0100) enabled
            Should-HaveFlag -Actual $configs -Expected 0b0100 -Each -Any
        }
    }

    Context 'When validating enum flags in real-world scenarios' {
        It 'Should validate System.Reflection.BindingFlags for method reflection' {
            # Simulate binding flags for reflection operations
            $bindingFlags = [System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::Instance

            # Validate that Public flag is set
            $bindingFlags | Should-HaveFlag -Expected ([System.Reflection.BindingFlags]::Public)

            # Validate that Instance flag is set
            $bindingFlags | Should-HaveFlag -Expected ([System.Reflection.BindingFlags]::Instance)
        }

        It 'Should validate System.Text.RegularExpressions.RegexOptions' {
            # Simulate regex options
            $regexOptions = [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [System.Text.RegularExpressions.RegexOptions]::Multiline

            # Validate specific options are set
            $regexOptions | Should-HaveFlag -Expected ([System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
            $regexOptions | Should-HaveFlag -Expected ([System.Text.RegularExpressions.RegexOptions]::Multiline)
        }
    }

    Context 'When validating bit masks in network programming' {
        It 'Should validate TCP flags in packet analysis' {
            # Simulate TCP flags: SYN=0x02, ACK=0x10
            # SYN-ACK packet would have both flags set
            $tcpFlags = 0x12  # SYN + ACK

            # Validate SYN flag is set
            $tcpFlags | Should-HaveFlag -Expected 0x02

            # Validate ACK flag is set
            $tcpFlags | Should-HaveFlag -Expected 0x10
        }

        It 'Should validate IP protocol flags' {
            # Simulate IP flags: Reserved=0x8000, Don't Fragment=0x4000, More Fragments=0x2000
            $ipFlags = 0x4000  # Don't Fragment set

            # Validate Don't Fragment is set
            $ipFlags | Should-HaveFlag -Expected 0x4000
        }
    }

    Context 'When validating flags in testing frameworks' {
        It 'Should validate test execution options' {
            # Simulate test execution options
            # Bit flags: ParallelExecution=1, VerboseOutput=2, StopOnFailure=4, GenerateCoverage=8
            $testOptions = 11  # ParallelExecution + VerboseOutput + GenerateCoverage (1+2+8)

            # Validate specific options are enabled
            $testOptions | Should-HaveFlag -Expected 1  # ParallelExecution
            $testOptions | Should-HaveFlag -Expected 2  # VerboseOutput
            $testOptions | Should-HaveFlag -Expected 8  # GenerateCoverage
        }
    }

    Context 'When validating flags with Because parameter for documentation' {
        It 'Should provide clear error messages with business context' {
            # Simulate checking permissions
            $userPermissions = 0b0001  # Only read permission

            # This will pass
            $userPermissions | Should-HaveFlag -Expected 0b0001 -Because 'users must have read access to view reports'

            # This would fail with descriptive message
            {
                $userPermissions | Should-HaveFlag -Expected 0b0010 -Because 'users must have write access to create reports'
            } | Should-Throw -Because 'the error should mention the business context'
        }
    }

    Context 'When validating large bit values' {
        It 'Should handle 64-bit flag values' {
            # Simulate 64-bit flag value
            $largeValue = [System.Int64]0x8000000000000001

            # Check that high bit is set
            $largeValue | Should-HaveFlag -Expected ([System.Int64]0x8000000000000000)

            # Check that low bit is set
            $largeValue | Should-HaveFlag -Expected 1
        }

        It 'Should handle large unsigned 64-bit values' {
            # Simulate large UInt64 value with multiple bits set
            $largeValue = [System.UInt64]0x0FFFFFFFFFFFFFFF

            # Multiple flags should be set
            $largeValue | Should-HaveFlag -Expected 0xFF
            $largeValue | Should-HaveFlag -Expected 0xFFFF
            $largeValue | Should-HaveFlag -Expected ([System.Int64]0x0FFFFFFF00000000)
        }
    }

    Context 'When processing multiple values in pipeline' {
        It 'Should validate flags on multiple permission sets with -Each -All' {
            # Simulate multiple permission sets for different users
            $userPermissions = @(
                0b111,  # Read, Write, Execute
                0b111,  # Read, Write, Execute
                0b111   # Read, Write, Execute
            )

            # Validate all users have read permission
            $userPermissions | Should-HaveFlag -Expected 0b001 -Each -All
        }

        It 'Should validate at least one user has permission with -Each -Any' {
            # Simulate multiple permission sets for different users
            $userPermissions = @(
                0b001,  # Read only
                0b111,  # Read, Write, Execute
                0b001   # Read only
            )

            # Validate at least one user has execute permission
            Should-HaveFlag -Actual $userPermissions -Expected 0b100 -Each -Any
        }
    }
}
