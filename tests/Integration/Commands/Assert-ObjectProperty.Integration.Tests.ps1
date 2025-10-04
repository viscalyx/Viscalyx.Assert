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

Describe 'Assert-ObjectProperty' {
    Context 'Testing mock objects in typical Pester scenarios' {
        BeforeAll {
            # Create a mock configuration object like you'd see in real tests
            $script:mockConfig = [PSCustomObject]@{
                ServerName         = 'TestServer'
                Port               = 8080
                DatabaseConnection = [PSCustomObject]@{
                    Server   = 'db.test.local'
                    Database = 'TestDB'
                    Timeout  = 30
                }
                Features           = @('Logging', 'Caching', 'Authentication')
                Settings           = @{
                    Debug          = $true
                    LogLevel       = 'Verbose'
                    MaxConnections = 100
                }
            }
        }

        It 'Should verify mock configuration object has expected properties' {
            # Using the alias in pipeline style - common Pester pattern
            $script:mockConfig | Should-HaveProperty -Property 'ServerName' -Value 'TestServer'
            $script:mockConfig | Should-HaveProperty -Property 'Port' -Value 8080
            $script:mockConfig | Should-HaveProperty -Property 'DatabaseConnection'
            $script:mockConfig | Should-HaveProperty -Property 'Features'
            $script:mockConfig | Should-HaveProperty -Property 'Settings'
        }

        It 'Should verify nested mock properties' {
            # Testing nested object properties
            $script:mockConfig.DatabaseConnection | Should-HaveProperty -Property 'Server' -Value 'db.test.local'
            $script:mockConfig.DatabaseConnection | Should-HaveProperty -Property 'Database' -Value 'TestDB'
            $script:mockConfig.DatabaseConnection | Should-HaveProperty -Property 'Timeout' -Value 30
        }

        It 'Should verify hashtable properties in mock settings' {
            $script:mockConfig.Settings | Should-HaveProperty -Property 'Debug' -Value $true
            $script:mockConfig.Settings | Should-HaveProperty -Property 'LogLevel' -Value 'Verbose'
            $script:mockConfig.Settings | Should-HaveProperty -Property 'MaxConnections' -Value 100
        }
    }

    Context 'Testing system objects with Should-HaveProperty' {
        It 'Should verify Process object properties' {
            $currentProcess = Get-Process -Id $PID

            # Using alias to verify system object properties
            $currentProcess | Should-HaveProperty -Property 'ProcessName'
            $currentProcess | Should-HaveProperty -Property 'Id' -Value $PID
            $currentProcess | Should-HaveProperty -Property 'StartTime'
            $currentProcess | Should-HaveProperty -Property 'Threads'
        }

        It 'Should verify FileInfo object properties' {
            $tempFile = New-TemporaryFile
            try
            {
                $fileInfo = Get-Item $tempFile.FullName -ErrorAction Stop

                # Common pattern: verifying file system objects
                $fileInfo | Should-HaveProperty -Property 'Name' -Value $tempFile.Name
                $fileInfo | Should-HaveProperty -Property 'Exists' -Value $true
                $fileInfo | Should-HaveProperty -Property 'Length'
                $fileInfo | Should-HaveProperty -Property 'CreationTime'
                $fileInfo | Should-HaveProperty -Property 'Directory'
            }
            finally
            {
                Remove-Item $tempFile.FullName -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Should verify DateTime properties using pipeline' {
            $testDate = Get-Date -Year 2023 -Month 12 -Day 25 -Hour 10 -Minute 30 -Second 45

            # Pipeline usage with Should-HaveProperty
            $testDate | Should-HaveProperty -Property 'Year' -Value 2023
            $testDate | Should-HaveProperty -Property 'Month' -Value 12
            $testDate | Should-HaveProperty -Property 'Day' -Value 25
            $testDate | Should-HaveProperty -Property 'DayOfWeek' -Value 'Monday'
            $testDate | Should-HaveProperty -Property 'Kind'
        }
    }

    Context 'Testing custom PowerShell classes with Should-HaveProperty' {
        BeforeAll {
            # Define a test class like you might in integration tests
            class TestService
            {
                [string]$Name
                [string]$Status
                [int]$Port
                [datetime]$LastStarted
                [hashtable]$Configuration

                TestService([string]$name, [int]$port)
                {
                    $this.Name = $name
                    $this.Port = $port
                    $this.Status = 'Stopped'
                    $this.Configuration = @{}
                }

                [void]Start()
                {
                    $this.Status = 'Running'
                    $this.LastStarted = Get-Date
                }
            }

            $script:testService = [TestService]::new('WebAPI', 8080)
            $script:testService.Configuration = @{
                'MaxRequestSize' = 1048576
                'EnableCors'     = $true
                'AllowedOrigins' = @('localhost', '127.0.0.1')
            }
            $script:testService.Start()
        }

        It 'Should verify custom class properties' {
            # Typical integration test pattern for custom objects
            $script:testService | Should-HaveProperty -Property 'Name' -Value 'WebAPI'
            $script:testService | Should-HaveProperty -Property 'Status' -Value 'Running'
            $script:testService | Should-HaveProperty -Property 'Port' -Value 8080
            $script:testService | Should-HaveProperty -Property 'LastStarted'
            $script:testService | Should-HaveProperty -Property 'Configuration'
        }

        It 'Should verify configuration hashtable properties' {
            # Testing nested hashtable properties
            $script:testService.Configuration | Should-HaveProperty -Property 'MaxRequestSize' -Value 1048576
            $script:testService.Configuration | Should-HaveProperty -Property 'EnableCors' -Value $true
            $script:testService.Configuration | Should-HaveProperty -Property 'AllowedOrigins'
        }
    }

    Context 'Testing array and collection properties' {
        BeforeAll {
            $script:mockServiceCollection = @(
                [PSCustomObject]@{ Name = 'Service1'; Port = 8001; Type = 'Web' }
                [PSCustomObject]@{ Name = 'Service2'; Port = 8002; Type = 'API' }
                [PSCustomObject]@{ Name = 'Service3'; Port = 8003; Type = 'Database' }
            )
        }

        It 'Should verify properties of objects in collections' {
            # Common pattern: testing collections of objects using -Each parameter
            $script:mockServiceCollection | Should-HaveProperty -Property 'Name' -Each
            $script:mockServiceCollection | Should-HaveProperty -Property 'Port' -Each
            $script:mockServiceCollection | Should-HaveProperty -Property 'Type' -Each
        }

        It 'Should verify specific service properties by filtering' {
            $webService = $script:mockServiceCollection | Where-Object Type -eq 'Web'
            $webService | Should-HaveProperty -Property 'Name' -Value 'Service1'
            $webService | Should-HaveProperty -Property 'Port' -Value 8001

            $apiService = $script:mockServiceCollection | Where-Object Type -eq 'API'
            $apiService | Should-HaveProperty -Property 'Name' -Value 'Service2'
            $apiService | Should-HaveProperty -Property 'Port' -Value 8002
        }
    }

    Context 'Testing error scenarios with meaningful messages' {
        BeforeAll {
            $script:testObject = [PSCustomObject]@{
                ValidProperty   = 'TestValue'
                AnotherProperty = 123
            }
        }

        It 'Should fail gracefully when property does not exist' {
            { $script:testObject | Should-HaveProperty -Property 'NonExistentProperty' } | Should -Throw
        }

        It 'Should fail gracefully when property value does not match' {
            { $script:testObject | Should-HaveProperty -Property 'ValidProperty' -Value 'WrongValue' } | Should -Throw
        }

        It 'Should fail gracefully with null objects' {
            { $null | Should-HaveProperty -Property 'AnyProperty' } | Should -Throw
        }

        It 'Should provide meaningful error with Because parameter' {
            try
            {
                $script:testObject | Should-HaveProperty -Property 'MissingProperty' -Because 'this property is required for the integration test'
                throw 'Should have thrown an exception'
            }
            catch
            {
                $_.Exception.Message | Should -Match 'because this property is required for the integration test'
            }
        }
    }

    Context 'Testing complex real-world scenarios' {
        It 'Should validate a complete configuration hierarchy' {
            # Simulate a complex configuration object from a real application
            $appConfig = [PSCustomObject]@{
                Application = [PSCustomObject]@{
                    Name        = 'MyWebApp'
                    Version     = '2.1.0'
                    Environment = 'Production'
                }
                Server      = [PSCustomObject]@{
                    Host = '0.0.0.0'
                    Port = 443
                    SSL  = [PSCustomObject]@{
                        Enabled     = $true
                        Certificate = 'mycert.pfx'
                        Protocols   = @('TLS1.2', 'TLS1.3')
                    }
                }
                Database    = [PSCustomObject]@{
                    Primary     = [PSCustomObject]@{
                        ConnectionString = 'Server=primary-db;Database=MyApp'
                        MaxPoolSize      = 100
                    }
                    ReadReplica = [PSCustomObject]@{
                        ConnectionString = 'Server=replica-db;Database=MyApp'
                        MaxPoolSize      = 50
                    }
                }
                Features    = @{
                    'Caching'      = $true
                    'Logging'      = $true
                    'Metrics'      = $true
                    'HealthChecks' = $true
                }
            }

            # Validate the complete hierarchy using Should-HaveProperty
            $appConfig | Should-HaveProperty -Property 'Application'
            $appConfig | Should-HaveProperty -Property 'Server'
            $appConfig | Should-HaveProperty -Property 'Database'
            $appConfig | Should-HaveProperty -Property 'Features'

            # Validate nested application properties
            $appConfig.Application | Should-HaveProperty -Property 'Name' -Value 'MyWebApp'
            $appConfig.Application | Should-HaveProperty -Property 'Version' -Value '2.1.0'
            $appConfig.Application | Should-HaveProperty -Property 'Environment' -Value 'Production'

            # Validate server configuration
            $appConfig.Server | Should-HaveProperty -Property 'Host' -Value '0.0.0.0'
            $appConfig.Server | Should-HaveProperty -Property 'Port' -Value 443
            $appConfig.Server | Should-HaveProperty -Property 'SSL'

            # Validate SSL configuration
            $appConfig.Server.SSL | Should-HaveProperty -Property 'Enabled' -Value $true
            $appConfig.Server.SSL | Should-HaveProperty -Property 'Certificate' -Value 'mycert.pfx'
            $appConfig.Server.SSL | Should-HaveProperty -Property 'Protocols' -Value @('TLS1.2', 'TLS1.3')

            # Validate database configuration
            $appConfig.Database | Should-HaveProperty -Property 'Primary'
            $appConfig.Database | Should-HaveProperty -Property 'ReadReplica'
            $appConfig.Database.Primary | Should-HaveProperty -Property 'MaxPoolSize' -Value 100
            $appConfig.Database.ReadReplica | Should-HaveProperty -Property 'MaxPoolSize' -Value 50

            # Validate feature flags
            $appConfig.Features | Should-HaveProperty -Property 'Caching' -Value $true
            $appConfig.Features | Should-HaveProperty -Property 'Logging' -Value $true
            $appConfig.Features | Should-HaveProperty -Property 'Metrics' -Value $true
            $appConfig.Features | Should-HaveProperty -Property 'HealthChecks' -Value $true
        }
    }

    Context 'Testing Each parameter for array element validation' {
        BeforeAll {
            $script:serviceArray = @(
                [PSCustomObject]@{ Name = 'WebServer'; Status = 'Running'; Port = 80 }
                [PSCustomObject]@{ Name = 'Database'; Status = 'Running'; Port = 5432 }
                [PSCustomObject]@{ Name = 'Cache'; Status = 'Running'; Port = 6379 }
            )
        }

        It 'Should verify array properties without Each parameter' {
            # Without -Each, should check properties on the array itself
            $script:serviceArray | Should-HaveProperty -Property 'Count' -Value 3
            $script:serviceArray | Should-HaveProperty -Property 'Length' -Value 3
        }

        It 'Should verify each element has Name property with Each parameter' {
            # With -Each, should check each element in the array
            $script:serviceArray | Should-HaveProperty -Property 'Name' -Each
        }

        It 'Should verify each element has Status property with value Running using Each' {
            $script:serviceArray | Should-HaveProperty -Property 'Status' -Value 'Running' -Each
        }

        It 'Should verify each element has Port property using Each' {
            $script:serviceArray | Should-HaveProperty -Property 'Port' -Each
        }

        It 'Should fail when checking for non-existent property on elements with Each' {
            {
                $script:serviceArray | Should-HaveProperty -Property 'NonExistent' -Each
            } | Should -Throw
        }

        It 'Should work with Each parameter on configuration objects' {
            $configObjects = @(
                @{ Setting1 = 'Value1'; Setting2 = 'Value2' }
                @{ Setting1 = 'Value3'; Setting2 = 'Value4' }
                @{ Setting1 = 'Value5'; Setting2 = 'Value6' }
            )

            # Each hashtable should have Setting1 and Setting2
            $configObjects | Should-HaveProperty -Property 'Setting1' -Each
            $configObjects | Should-HaveProperty -Property 'Setting2' -Each
        }

        It 'Should validate array property vs element property distinction' {
            $testArray = @(
                [PSCustomObject]@{ Id = 1; Name = 'Item1' }
                [PSCustomObject]@{ Id = 2; Name = 'Item2' }
            )

            # Without -Each: check array properties
            $testArray | Should-HaveProperty -Property 'Count' -Value 2

            # With -Each: check element properties
            $testArray | Should-HaveProperty -Property 'Id' -Each
            $testArray | Should-HaveProperty -Property 'Name' -Each
        }

        It 'Should work with Each and Because parameters together' {
            $services = @(
                [PSCustomObject]@{ Name = 'Service1'; Active = $true }
                [PSCustomObject]@{ Name = 'Service2'; Active = $true }
            )

            $services | Should-HaveProperty -Property 'Active' -Value $true -Each -Because 'all services must be active in production'
        }

        It 'Should validate mixed object types with Each parameter' {
            $mixedObjects = @(
                [PSCustomObject]@{ Status = 'OK'; Code = 200 }
                [PSCustomObject]@{ Status = 'OK'; Code = 201 }
                [PSCustomObject]@{ Status = 'OK'; Code = 204 }
            )

            # All should have Status property with value 'OK'
            $mixedObjects | Should-HaveProperty -Property 'Status' -Value 'OK' -Each
            # All should have Code property (different values)
            $mixedObjects | Should-HaveProperty -Property 'Code' -Each
        }
    }
}
