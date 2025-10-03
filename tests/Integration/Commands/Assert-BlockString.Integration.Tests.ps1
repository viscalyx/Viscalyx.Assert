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

Describe 'Assert-BlockString' -Tag @('Integration') {
    Context 'When validating configuration files in test scenarios' {
        It 'Should validate JSON configuration content using Should-BeBlockString' {
            # Simulate validating generated JSON configuration
            $actualJson = @'
{
    "name": "TestApp",
    "version": "1.0.0",
    "dependencies": {
        "lodash": "^4.17.21"
    }
}
'@

            $expectedJson = @'
{
    "name": "TestApp",
    "version": "1.0.0",
    "dependencies": {
        "lodash": "^4.17.21"
    }
}
'@

            # This demonstrates using Should-BeBlockString for configuration validation
            $actualJson | Should-BeBlockString -Expected $expectedJson
        }

        It 'Should validate XML configuration content using Should-BeBlockString' {
            # Simulate validating generated XML configuration
            $actualXml = @'
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <appSettings>
        <add key="DatabaseConnection" value="Server=localhost;Database=TestDB" />
        <add key="LogLevel" value="Info" />
    </appSettings>
</configuration>
'@

            $expectedXml = @'
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <appSettings>
        <add key="DatabaseConnection" value="Server=localhost;Database=TestDB" />
        <add key="LogLevel" value="Info" />
    </appSettings>
</configuration>
'@

            $actualXml | Should-BeBlockString -Expected $expectedXml
        }

        It 'Should validate YAML configuration content using Should-BeBlockString' {
            # Simulate validating generated YAML configuration
            $actualYaml = @'
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: default
data:
  database.url: "jdbc:postgresql://localhost:5432/testdb"
  cache.enabled: "true"
  log.level: "INFO"
'@

            $expectedYaml = @'
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: default
data:
  database.url: "jdbc:postgresql://localhost:5432/testdb"
  cache.enabled: "true"
  log.level: "INFO"
'@

            $actualYaml | Should-BeBlockString -Expected $expectedYaml
        }
    }

    Context 'When validating generated code output' {
        It 'Should validate generated PowerShell code using Should-BeBlockString' {
            # Simulate code generation scenario
            $actualPowerShell = @'
function Get-UserInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Username
    )

    Write-Output "Getting information for user: $Username"

    return @{
        Name = $Username
        LastLogin = Get-Date
        IsActive = $true
    }
}
'@

            $expectedPowerShell = @'
function Get-UserInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Username
    )

    Write-Output "Getting information for user: $Username"

    return @{
        Name = $Username
        LastLogin = Get-Date
        IsActive = $true
    }
}
'@

            $actualPowerShell | Should-BeBlockString -Expected $expectedPowerShell
        }

        It 'Should validate generated SQL script using Should-BeBlockString' {
            # Simulate SQL script generation validation
            $actualSql = @'
CREATE TABLE Users (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Username NVARCHAR(50) NOT NULL UNIQUE,
    Email NVARCHAR(100) NOT NULL,
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    IsActive BIT DEFAULT 1
);

CREATE INDEX IX_Users_Username ON Users(Username);
CREATE INDEX IX_Users_Email ON Users(Email);
'@

            $expectedSql = @'
CREATE TABLE Users (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Username NVARCHAR(50) NOT NULL UNIQUE,
    Email NVARCHAR(100) NOT NULL,
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    IsActive BIT DEFAULT 1
);

CREATE INDEX IX_Users_Username ON Users(Username);
CREATE INDEX IX_Users_Email ON Users(Email);
'@

            $actualSql | Should-BeBlockString -Expected $expectedSql
        }
    }

    Context 'When validating log output and structured data' {
        It 'Should validate application log output using Should-BeBlockString' {
            # Simulate log validation scenario
            $actualLog = @'
2023-10-03 10:15:23.456 [INFO] Application starting...
2023-10-03 10:15:23.789 [INFO] Database connection established
2023-10-03 10:15:24.012 [INFO] Cache initialized with 256MB limit
2023-10-03 10:15:24.234 [WARN] Configuration file backup not found
2023-10-03 10:15:24.567 [INFO] Application ready to accept requests
'@

            $expectedLog = @'
2023-10-03 10:15:23.456 [INFO] Application starting...
2023-10-03 10:15:23.789 [INFO] Database connection established
2023-10-03 10:15:24.012 [INFO] Cache initialized with 256MB limit
2023-10-03 10:15:24.234 [WARN] Configuration file backup not found
2023-10-03 10:15:24.567 [INFO] Application ready to accept requests
'@

            $actualLog | Should-BeBlockString -Expected $expectedLog
        }

        It 'Should validate CSV data output using Should-BeBlockString' {
            # Simulate CSV export validation
            $actualCsv = @'
Name,Age,Department,Salary
John Doe,30,Engineering,75000
Jane Smith,28,Marketing,65000
Bob Johnson,35,Sales,70000
Alice Brown,32,Engineering,80000
'@

            $expectedCsv = @'
Name,Age,Department,Salary
John Doe,30,Engineering,75000
Jane Smith,28,Marketing,65000
Bob Johnson,35,Sales,70000
Alice Brown,32,Engineering,80000
'@

            $actualCsv | Should-BeBlockString -Expected $expectedCsv
        }
    }

    Context 'When validating template and documentation output' {
        It 'Should validate generated Markdown documentation using Should-BeBlockString' {
            # Simulate documentation generation validation
            $actualMarkdown = @'
# User Management API

## Overview
This API provides endpoints for managing user accounts.

## Endpoints

### GET /api/users
Returns a list of all users.

**Parameters:**
- `page` (optional): Page number for pagination
- `limit` (optional): Number of users per page

**Response:**
```json
{
    "users": [...],
    "totalCount": 150,
    "page": 1,
    "limit": 10
}
```

### POST /api/users
Creates a new user account.
'@

            $expectedMarkdown = @'
# User Management API

## Overview
This API provides endpoints for managing user accounts.

## Endpoints

### GET /api/users
Returns a list of all users.

**Parameters:**
- `page` (optional): Page number for pagination
- `limit` (optional): Number of users per page

**Response:**
```json
{
    "users": [...],
    "totalCount": 150,
    "page": 1,
    "limit": 10
}
```

### POST /api/users
Creates a new user account.
'@

            $actualMarkdown | Should-BeBlockString -Expected $expectedMarkdown
        }

        It 'Should validate HTML template output using Should-BeBlockString' {
            # Simulate HTML template generation validation
            $actualHtml = @'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>User Dashboard</title>
    <link rel="stylesheet" href="/styles/main.css">
</head>
<body>
    <header>
        <h1>Welcome to User Dashboard</h1>
        <nav>
            <a href="/dashboard">Dashboard</a>
            <a href="/profile">Profile</a>
            <a href="/settings">Settings</a>
        </nav>
    </header>
    <main>
        <div class="content">
            <!-- Content will be populated here -->
        </div>
    </main>
</body>
</html>
'@

            $expectedHtml = @'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>User Dashboard</title>
    <link rel="stylesheet" href="/styles/main.css">
</head>
<body>
    <header>
        <h1>Welcome to User Dashboard</h1>
        <nav>
            <a href="/dashboard">Dashboard</a>
            <a href="/profile">Profile</a>
            <a href="/settings">Settings</a>
        </nav>
    </header>
    <main>
        <div class="content">
            <!-- Content will be populated here -->
        </div>
    </main>
</body>
</html>
'@

            $actualHtml | Should-BeBlockString -Expected $expectedHtml
        }
    }

    Context 'When validating array of strings in complex scenarios' {
        It 'Should validate command output lines using Should-BeBlockString' {
            # Simulate validating command-line tool output
            $actualOutput = @(
                'Starting backup process...',
                'Connecting to database server...',
                'Backup file: backup_20231003_101523.sql',
                'Tables backed up: 15',
                'Data size: 2.3 GB',
                'Backup completed successfully.',
                'Total time: 00:05:47'
            )

            $expectedOutput = @(
                'Starting backup process...',
                'Connecting to database server...',
                'Backup file: backup_20231003_101523.sql',
                'Tables backed up: 15',
                'Data size: 2.3 GB',
                'Backup completed successfully.',
                'Total time: 00:05:47'
            )

            $actualOutput | Should-BeBlockString -Expected $expectedOutput
        }

        It 'Should validate configuration validation messages using Should-BeBlockString' {
            # Simulate configuration validation output
            $actualMessages = @(
                '[PASS] Database connection string is valid',
                '[PASS] API endpoints are reachable',
                '[WARN] SSL certificate expires in 30 days',
                '[PASS] Log directory has sufficient space',
                '[FAIL] Redis cache server is unreachable',
                '[PASS] Email SMTP settings are correct',
                'Validation completed with 1 error and 1 warning'
            )

            $expectedMessages = @(
                '[PASS] Database connection string is valid',
                '[PASS] API endpoints are reachable',
                '[WARN] SSL certificate expires in 30 days',
                '[PASS] Log directory has sufficient space',
                '[FAIL] Redis cache server is unreachable',
                '[PASS] Email SMTP settings are correct',
                'Validation completed with 1 error and 1 warning'
            )

            $actualMessages | Should-BeBlockString -Expected $expectedMessages
        }
    }

    Context 'When validating infrastructure as code templates' {
        It 'Should validate Terraform configuration using Should-BeBlockString' {
            # Simulate Terraform template validation
            $actualTerraform = @'
resource "aws_instance" "web_server" {
  ami           = "ami-0c55b159cbfafe1d0"
  instance_type = "t3.micro"
  key_name      = var.key_name

  tags = {
    Name        = "WebServer"
    Environment = "Production"
    Project     = "MyApp"
  }

  vpc_security_group_ids = [aws_security_group.web_sg.id]
  subnet_id              = aws_subnet.public_subnet.id

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
  EOF
}
'@

            $expectedTerraform = @'
resource "aws_instance" "web_server" {
  ami           = "ami-0c55b159cbfafe1d0"
  instance_type = "t3.micro"
  key_name      = var.key_name

  tags = {
    Name        = "WebServer"
    Environment = "Production"
    Project     = "MyApp"
  }

  vpc_security_group_ids = [aws_security_group.web_sg.id]
  subnet_id              = aws_subnet.public_subnet.id

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
  EOF
}
'@

            $actualTerraform | Should-BeBlockString -Expected $expectedTerraform
        }

        It 'Should validate Docker Compose file using Should-BeBlockString' {
            # Simulate Docker Compose validation
            $actualDockerCompose = @'
version: '3.8'

services:
  web:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DATABASE_URL=postgresql://user:pass@db:5432/myapp
    depends_on:
      - db
      - redis

  db:
    image: postgres:13
    environment:
      POSTGRES_DB: myapp
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:6-alpine
    ports:
      - "6379:6379"

volumes:
  postgres_data:
'@

            $expectedDockerCompose = @'
version: '3.8'

services:
  web:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DATABASE_URL=postgresql://user:pass@db:5432/myapp
    depends_on:
      - db
      - redis

  db:
    image: postgres:13
    environment:
      POSTGRES_DB: myapp
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:6-alpine
    ports:
      - "6379:6379"

volumes:
  postgres_data:
'@

            $actualDockerCompose | Should-BeBlockString -Expected $expectedDockerCompose
        }
    }

    Context 'When validating test data and mock responses' {
        It 'Should validate API response JSON using Should-BeBlockString' {
            # Simulate API response validation in integration tests
            $actualApiResponse = @'
{
  "status": "success",
  "data": {
    "users": [
      {
        "id": 1,
        "username": "john.doe",
        "email": "john@example.com",
        "profile": {
          "firstName": "John",
          "lastName": "Doe",
          "department": "Engineering"
        },
        "permissions": ["read", "write", "admin"]
      },
      {
        "id": 2,
        "username": "jane.smith",
        "email": "jane@example.com",
        "profile": {
          "firstName": "Jane",
          "lastName": "Smith",
          "department": "Marketing"
        },
        "permissions": ["read", "write"]
      }
    ]
  },
  "meta": {
    "totalCount": 2,
    "page": 1,
    "limit": 10
  }
}
'@

            $expectedApiResponse = @'
{
  "status": "success",
  "data": {
    "users": [
      {
        "id": 1,
        "username": "john.doe",
        "email": "john@example.com",
        "profile": {
          "firstName": "John",
          "lastName": "Doe",
          "department": "Engineering"
        },
        "permissions": ["read", "write", "admin"]
      },
      {
        "id": 2,
        "username": "jane.smith",
        "email": "jane@example.com",
        "profile": {
          "firstName": "Jane",
          "lastName": "Smith",
          "department": "Marketing"
        },
        "permissions": ["read", "write"]
      }
    ]
  },
  "meta": {
    "totalCount": 2,
    "page": 1,
    "limit": 10
  }
}
'@

            $actualApiResponse | Should-BeBlockString -Expected $expectedApiResponse
        }

        It 'Should validate multi-line test data using Should-BeBlockString in realistic scenario' {
            # Simulate validating test data generation for integration tests
            $actualTestData = @'
-- Test Data Setup Script
INSERT INTO departments (name, code, manager_id) VALUES
    ('Engineering', 'ENG', 1),
    ('Marketing', 'MKT', 2),
    ('Sales', 'SAL', 3),
    ('Human Resources', 'HR', 4);

INSERT INTO employees (first_name, last_name, email, department_id, hire_date) VALUES
    ('John', 'Doe', 'john.doe@company.com', 1, '2020-01-15'),
    ('Jane', 'Smith', 'jane.smith@company.com', 2, '2019-03-22'),
    ('Bob', 'Johnson', 'bob.johnson@company.com', 3, '2021-07-10'),
    ('Alice', 'Brown', 'alice.brown@company.com', 1, '2020-11-05');

-- Create test projects
INSERT INTO projects (name, description, department_id, start_date, status) VALUES
    ('Website Redesign', 'Complete overhaul of company website', 2, '2023-01-01', 'Active'),
    ('API Development', 'Build new REST API for mobile app', 1, '2023-02-15', 'Active'),
    ('Sales Dashboard', 'Create analytics dashboard for sales team', 3, '2023-03-01', 'Planning');
'@

            $expectedTestData = @'
-- Test Data Setup Script
INSERT INTO departments (name, code, manager_id) VALUES
    ('Engineering', 'ENG', 1),
    ('Marketing', 'MKT', 2),
    ('Sales', 'SAL', 3),
    ('Human Resources', 'HR', 4);

INSERT INTO employees (first_name, last_name, email, department_id, hire_date) VALUES
    ('John', 'Doe', 'john.doe@company.com', 1, '2020-01-15'),
    ('Jane', 'Smith', 'jane.smith@company.com', 2, '2019-03-22'),
    ('Bob', 'Johnson', 'bob.johnson@company.com', 3, '2021-07-10'),
    ('Alice', 'Brown', 'alice.brown@company.com', 1, '2020-11-05');

-- Create test projects
INSERT INTO projects (name, description, department_id, start_date, status) VALUES
    ('Website Redesign', 'Complete overhaul of company website', 2, '2023-01-01', 'Active'),
    ('API Development', 'Build new REST API for mobile app', 1, '2023-02-15', 'Active'),
    ('Sales Dashboard', 'Create analytics dashboard for sales team', 3, '2023-03-01', 'Planning');
'@

            # This demonstrates how Should-BeBlockString would be used in a real integration test
            # to validate that generated test data matches expected output exactly
            $actualTestData | Should-BeBlockString -Expected $expectedTestData
        }
    }
}
