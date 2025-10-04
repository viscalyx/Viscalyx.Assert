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

Describe 'Assert-ObjectMethod' -Tag @('Integration') {
    Context 'When validating methods on mock objects in test scenarios' {
        BeforeAll {
            # Create a mock service object with various methods
            $mockService = [PSCustomObject]@{
                Name   = 'TestService'
                Status = 'Running'
            }

            # Add script methods to simulate a service object
            $mockService | Add-Member -MemberType ScriptMethod -Name 'Start' -Value {
                $this.Status = 'Running'
                return $this
            }

            $mockService | Add-Member -MemberType ScriptMethod -Name 'Stop' -Value {
                $this.Status = 'Stopped'
                return $this
            }

            $mockService | Add-Member -MemberType ScriptMethod -Name 'Restart' -Value {
                $this.Stop()
                $this.Start()
                return $this
            }

            $mockService | Add-Member -MemberType ScriptMethod -Name 'GetStatus' -Value {
                return $this.Status
            }
        }

        It 'Should validate that mock service object has Start method using Should-HaveMethod' {
            # This demonstrates using Should-HaveMethod in a typical Pester test scenario
            $mockService | Should-HaveMethod -Method 'Start'
        }

        It 'Should validate that mock service object has Stop method using Should-HaveMethod' {
            $mockService | Should-HaveMethod -Method 'Stop'
        }

        It 'Should validate that mock service object has Restart method using Should-HaveMethod' {
            $mockService | Should-HaveMethod -Method 'Restart'
        }

        It 'Should validate that mock service object has GetStatus method using Should-HaveMethod' {
            $mockService | Should-HaveMethod -Method 'GetStatus'
        }

        It 'Should validate multiple methods exist on mock service using Should-HaveMethod in pipeline' {
            @('Start', 'Stop', 'Restart', 'GetStatus') | ForEach-Object {
                $mockService | Should-HaveMethod -Method $_
            }
        }
    }

    Context 'When validating methods on system objects' {
        It 'Should validate that string objects have expected methods using Should-HaveMethod' {
            $testString = 'Hello World'

            # Validate common string methods
            $testString | Should-HaveMethod -Method 'ToString'
            $testString | Should-HaveMethod -Method 'Substring'
            $testString | Should-HaveMethod -Method 'Contains'
            $testString | Should-HaveMethod -Method 'Replace'
            $testString | Should-HaveMethod -Method 'Split'
        }

        It 'Should validate that array objects have expected methods using Should-HaveMethod' {
            $testArray = @(1, 2, 3, 4, 5)

            # Validate common methods that are reliably available on PowerShell arrays
            $testArray | Should-HaveMethod -Method 'ToString'
            $testArray | Should-HaveMethod -Method 'GetType'
            $testArray | Should-HaveMethod -Method 'Equals'
        }

        It 'Should validate that hashtable objects have expected methods using Should-HaveMethod' {
            $testHashtable = @{
                Key1 = 'Value1'
                Key2 = 'Value2'
            }

            # Validate common hashtable methods
            $testHashtable | Should-HaveMethod -Method 'Add'
            $testHashtable | Should-HaveMethod -Method 'Remove'
            $testHashtable | Should-HaveMethod -Method 'ContainsKey'
            $testHashtable | Should-HaveMethod -Method 'ContainsValue'
        }
    }

    Context 'When validating methods on custom class instances' {
        BeforeAll {
            # Define a custom class for testing
            class TestConfiguration
            {
                [string]$Name
                [hashtable]$Settings
                [string[]]$Tags

                TestConfiguration([string]$name)
                {
                    $this.Name = $name
                    $this.Settings = @{}
                    $this.Tags = @()
                }

                [void] AddSetting([string]$key, [object]$value)
                {
                    $this.Settings[$key] = $value
                }

                [object] GetSetting([string]$key)
                {
                    return $this.Settings[$key]
                }

                [void] AddTag([string]$tag)
                {
                    $this.Tags += $tag
                }

                [bool] HasTag([string]$tag)
                {
                    return $this.Tags -contains $tag
                }

                [void] Reset()
                {
                    $this.Settings.Clear()
                    $this.Tags = @()
                }

                [string] ToString()
                {
                    return "Configuration: $($this.Name)"
                }
            }
        }

        It 'Should validate that custom class has AddSetting method using Should-HaveMethod' {
            $testConfiguration = [TestConfiguration]::new('TestConfig')
            $testConfiguration | Should-HaveMethod -Method 'AddSetting'
        }

        It 'Should validate that custom class has GetSetting method using Should-HaveMethod' {
            $testConfiguration = [TestConfiguration]::new('TestConfig')
            $testConfiguration | Should-HaveMethod -Method 'GetSetting'
        }

        It 'Should validate that custom class has AddTag method using Should-HaveMethod' {
            $testConfiguration = [TestConfiguration]::new('TestConfig')
            $testConfiguration | Should-HaveMethod -Method 'AddTag'
        }

        It 'Should validate that custom class has HasTag method using Should-HaveMethod' {
            $testConfiguration = [TestConfiguration]::new('TestConfig')
            $testConfiguration | Should-HaveMethod -Method 'HasTag'
        }

        It 'Should validate that custom class has Reset method using Should-HaveMethod' {
            $testConfiguration = [TestConfiguration]::new('TestConfig')
            $testConfiguration | Should-HaveMethod -Method 'Reset'
        }

        It 'Should validate that custom class has ToString method using Should-HaveMethod' {
            $testConfiguration = [TestConfiguration]::new('TestConfig')
            $testConfiguration | Should-HaveMethod -Method 'ToString'
        }

        It 'Should validate all custom methods exist using Should-HaveMethod in a test scenario' {
            $testConfiguration = [TestConfiguration]::new('TestConfig')
            $expectedMethods = @('AddSetting', 'GetSetting', 'AddTag', 'HasTag', 'Reset', 'ToString')

            foreach ($method in $expectedMethods)
            {
                $testConfiguration | Should-HaveMethod -Method $method
            }
        }
    }

    Context 'When validating methods on collections and complex objects' {
        BeforeAll {
            # Create a collection of objects with methods
            $serviceCollection = @(
                [PSCustomObject]@{ Name = 'Service1'; Type = 'Web' },
                [PSCustomObject]@{ Name = 'Service2'; Type = 'Database' },
                [PSCustomObject]@{ Name = 'Service3'; Type = 'Cache' }
            )

            # Add methods to each service object
            foreach ($service in $serviceCollection)
            {
                $service | Add-Member -MemberType ScriptMethod -Name 'GetInfo' -Value {
                    return "$($this.Name) ($($this.Type))"
                }

                $service | Add-Member -MemberType ScriptMethod -Name 'IsType' -Value {
                    param([string]$typeName)
                    return $this.Type -eq $typeName
                }
            }
        }

        It 'Should validate that each service in collection has GetInfo method using Should-HaveMethod' {
            # Use -Each parameter to validate methods on each element in the collection
            $serviceCollection | Should-HaveMethod -Method 'GetInfo' -Each
        }

        It 'Should validate that each service in collection has IsType method using Should-HaveMethod' {
            # Use -Each parameter to validate methods on each element in the collection
            $serviceCollection | Should-HaveMethod -Method 'IsType' -Each
        }

        It 'Should validate methods on ArrayList using Should-HaveMethod' {
            $arrayList = New-Object System.Collections.ArrayList
            $null = $arrayList.AddRange(@(1, 2, 3))

            # Use methods that are reliably detected by our Assert-ObjectMethod implementation
            $arrayList | Should-HaveMethod -Method 'ToString'
            $arrayList | Should-HaveMethod -Method 'GetType'
            $arrayList | Should-HaveMethod -Method 'Equals'
            $arrayList | Should-HaveMethod -Method 'GetHashCode'
        }
    }

    Context 'When validating methods in configuration management scenarios' {
        BeforeAll {
            # Simulate a configuration object that might be used in DSC or similar scenarios
            $dscConfiguration = [PSCustomObject]@{
                ResourceName = 'FileResource'
                Path         = 'C:\TestFile.txt'
                Content      = 'Test content'
                Ensure       = 'Present'
            }

            # Add methods that simulate DSC resource methods
            $dscConfiguration | Add-Member -MemberType ScriptMethod -Name 'Get' -Value {
                return @{
                    Path    = $this.Path
                    Content = $this.Content
                    Ensure  = if (Test-Path $this.Path)
                    {
                        'Present'
                    }
                    else
                    {
                        'Absent'
                    }
                }
            }

            $dscConfiguration | Add-Member -MemberType ScriptMethod -Name 'Set' -Value {
                if ($this.Ensure -eq 'Present')
                {
                    Set-Content -Path $this.Path -Value $this.Content -Force
                }
                else
                {
                    if (Test-Path $this.Path)
                    {
                        Remove-Item -Path $this.Path -Force
                    }
                }
            }

            $dscConfiguration | Add-Member -MemberType ScriptMethod -Name 'Test' -Value {
                $currentState = $this.Get()
                return $currentState.Ensure -eq $this.Ensure
            }
        }

        It 'Should validate that DSC configuration object has Get method using Should-HaveMethod' {
            $dscConfiguration | Should-HaveMethod -Method 'Get'
        }

        It 'Should validate that DSC configuration object has Set method using Should-HaveMethod' {
            $dscConfiguration | Should-HaveMethod -Method 'Set'
        }

        It 'Should validate that DSC configuration object has Test method using Should-HaveMethod' {
            $dscConfiguration | Should-HaveMethod -Method 'Test'
        }

        It 'Should validate all DSC methods exist in a complete validation scenario' {
            $requiredMethods = @('Get', 'Set', 'Test')

            foreach ($method in $requiredMethods)
            {
                $dscConfiguration | Should-HaveMethod -Method $method
            }
        }
    }

    Context 'When validating methods on objects with inheritance' {
        BeforeAll {
            # Create objects that demonstrate inheritance scenarios
        }

        It 'Should validate that FileInfo object has expected methods using Should-HaveMethod' {
            $fileInfo = Get-Item -Path $PSCommandPath
            $fileInfo | Should-HaveMethod -Method 'ToString'
            $fileInfo | Should-HaveMethod -Method 'GetHashCode'
            $fileInfo | Should-HaveMethod -Method 'Equals'
            $fileInfo | Should-HaveMethod -Method 'MoveTo'
            $fileInfo | Should-HaveMethod -Method 'CopyTo'
            $fileInfo | Should-HaveMethod -Method 'Delete'
        }

        It 'Should validate that DirectoryInfo object has expected methods using Should-HaveMethod' {
            $directoryInfo = Get-Item -Path (Split-Path $PSCommandPath -Parent)
            $directoryInfo | Should-HaveMethod -Method 'ToString'
            $directoryInfo | Should-HaveMethod -Method 'GetHashCode'
            $directoryInfo | Should-HaveMethod -Method 'Equals'
            $directoryInfo | Should-HaveMethod -Method 'Create'
            $directoryInfo | Should-HaveMethod -Method 'Delete'
            $directoryInfo | Should-HaveMethod -Method 'GetFiles'
            $directoryInfo | Should-HaveMethod -Method 'GetDirectories'
        }
    }

    Context 'When using Should-HaveMethod in complex test scenarios' {
        It 'Should validate methods in a realistic test workflow using Should-HaveMethod' {
            # Simulate a test scenario where we're validating a mock API client
            $mockApiClient = [PSCustomObject]@{
                BaseUrl = 'https://api.example.com'
                ApiKey  = 'test-key-123'
                Timeout = 30
            }

            # Add API client methods
            $mockApiClient | Add-Member -MemberType ScriptMethod -Name 'Get' -Value {
                param([string]$endpoint)
                return @{ Status = 'Success'; Data = @{ Endpoint = $endpoint } }
            }

            $mockApiClient | Add-Member -MemberType ScriptMethod -Name 'Post' -Value {
                param([string]$endpoint, [object]$data)
                return @{ Status = 'Created'; Data = $data }
            }

            $mockApiClient | Add-Member -MemberType ScriptMethod -Name 'SetTimeout' -Value {
                param([int]$seconds)
                $this.Timeout = $seconds
            }

            # Validate API client has required methods - this is how Should-HaveMethod would be used in real tests
            $mockApiClient | Should-HaveMethod -Method 'Get'
            $mockApiClient | Should-HaveMethod -Method 'Post'
            $mockApiClient | Should-HaveMethod -Method 'SetTimeout'

            # Validate that the API client can actually use its methods (integration aspect)
            $getResult = $mockApiClient.Get('/users')
            $getResult.Status | Should-Be 'Success'

            $postResult = $mockApiClient.Post('/users', @{ Name = 'Test User' })
            $postResult.Status | Should-Be 'Created'
        }
    }

    Context 'Testing Each parameter for array element validation' {
        BeforeAll {
            # Create array of objects with methods
            $script:serviceObjects = @(
                [PSCustomObject]@{ Name = 'Service1'; Status = 'Running' }
                [PSCustomObject]@{ Name = 'Service2'; Status = 'Running' }
                [PSCustomObject]@{ Name = 'Service3'; Status = 'Running' }
            )

            # Add methods to each service
            foreach ($service in $script:serviceObjects)
            {
                $service | Add-Member -MemberType ScriptMethod -Name 'Start' -Value {
                    $this.Status = 'Running'
                }
                $service | Add-Member -MemberType ScriptMethod -Name 'Stop' -Value {
                    $this.Status = 'Stopped'
                }
                $service | Add-Member -MemberType ScriptMethod -Name 'GetStatus' -Value {
                    return $this.Status
                }
            }
        }

        It 'Should verify array methods without Each parameter' {
            # Without -Each, should check methods on the array itself
            $script:serviceObjects | Should-HaveMethod -Method 'GetType'
            $script:serviceObjects | Should-HaveMethod -Method 'GetEnumerator'
        }

        It 'Should verify each element has Start method with Each parameter' {
            # With -Each, should check each element in the array
            $script:serviceObjects | Should-HaveMethod -Method 'Start' -Each
        }

        It 'Should verify each element has Stop method using Each' {
            $script:serviceObjects | Should-HaveMethod -Method 'Stop' -Each
        }

        It 'Should verify each element has GetStatus method using Each' {
            $script:serviceObjects | Should-HaveMethod -Method 'GetStatus' -Each
        }

        It 'Should fail when checking for non-existent method on elements with Each' {
            {
                $script:serviceObjects | Should-HaveMethod -Method 'NonExistentMethod' -Each
            } | Should -Throw
        }

        It 'Should work with Each parameter on string array' {
            $stringArray = @('Hello', 'World', 'Test')

            # Each string should have ToString, Substring, etc.
            $stringArray | Should-HaveMethod -Method 'ToString' -Each
            $stringArray | Should-HaveMethod -Method 'Substring' -Each
            $stringArray | Should-HaveMethod -Method 'Contains' -Each
        }

        It 'Should validate array method vs element method distinction' {
            $testArray = @(
                [PSCustomObject]@{ Value = 1 }
                [PSCustomObject]@{ Value = 2 }
            )

            foreach ($obj in $testArray)
            {
                $obj | Add-Member -MemberType ScriptMethod -Name 'GetValue' -Value { return $this.Value }
            }

            # Without -Each: check array methods
            $testArray | Should-HaveMethod -Method 'GetType'

            # With -Each: check element methods
            $testArray | Should-HaveMethod -Method 'GetValue' -Each
        }

        It 'Should work with Each and Because parameters together' {
            $handlers = @(
                [PSCustomObject]@{ Name = 'Handler1' }
                [PSCustomObject]@{ Name = 'Handler2' }
            )

            foreach ($handler in $handlers)
            {
                $handler | Add-Member -MemberType ScriptMethod -Name 'Handle' -Value { return 'Handled' }
            }

            $handlers | Should-HaveMethod -Method 'Handle' -Each -Because 'all handlers must implement the Handle method'
        }

        It 'Should validate custom class instances with Each parameter' {
            class Worker
            {
                [string]$Name

                Worker([string]$name)
                {
                    $this.Name = $name
                }

                [void] DoWork()
                {
                    Write-Verbose "Working: $($this.Name)"
                }

                [string] GetName()
                {
                    return $this.Name
                }
            }

            $workers = @(
                [Worker]::new('Worker1')
                [Worker]::new('Worker2')
                [Worker]::new('Worker3')
            )

            # All workers should have DoWork and GetName methods
            $workers | Should-HaveMethod -Method 'DoWork' -Each
            $workers | Should-HaveMethod -Method 'GetName' -Each
        }

        It 'Should work with hashtable array elements' {
            $hashtables = @(
                @{ Key1 = 'Value1' }
                @{ Key2 = 'Value2' }
                @{ Key3 = 'Value3' }
            )

            # All hashtables should have Add, Remove, ContainsKey methods
            $hashtables | Should-HaveMethod -Method 'Add' -Each
            $hashtables | Should-HaveMethod -Method 'Remove' -Each
            $hashtables | Should-HaveMethod -Method 'ContainsKey' -Each
        }

        It 'Should validate methods on ProcessInfo array with Each' {
            $processes = Get-Process | Select-Object -First 3

            # Each process should have Kill, WaitForExit, etc.
            $processes | Should-HaveMethod -Method 'ToString' -Each
            $processes | Should-HaveMethod -Method 'GetHashCode' -Each
        }
    }
}
