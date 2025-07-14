@description('Location for all resources')
param location string = resourceGroup().location

@description('SQL Server name (must be globally unique)')
param sqlServerName string = 'mysqlserverforapptier'

@description('SQL Admin username')
param sqlAdminUsername string = 'sqldbadminuser'

@secure()
param sqlAdminPassword string

@description('SQL Database name')
param sqlDatabaseName string = 'appdb'

@description('Enable Azure services to access this server')
param allowAzureServices bool = true

// SQL Server
resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: sqlAdminUsername
    administratorLoginPassword: sqlAdminPassword
    publicNetworkAccess: 'Disabled' // for demo; use 'Disabled' and Private Endpoint in production
  }
}

// SQL Database
resource sqlDatabase 'Microsoft.Sql/servers/databases@2022-05-01-preview' = {
  parent: sqlServer
  name: sqlDatabaseName
  location: location
  sku: {
    name: 'Basic'
    tier: 'Basic'
    capacity: 5
  }
  properties: {
    readScale: 'Disabled'
  }
}

// Allow other Azure services (like App Tier) to access the DB (adds 0.0.0.0 rule)
resource sqlFirewall 'Microsoft.Sql/servers/firewallRules@2022-05-01-preview' = if (allowAzureServices) {
  parent: sqlServer
  name: 'AllowAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

output dbConnectionString string = 'Driver={ODBC Driver 18 for SQL Server};Server=tcp:${sqlServer.name}.database.windows.net,1433;Database=${sqlDatabase.name};Uid=${sqlAdminUsername};Pwd=${sqlAdminPassword};Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30;'
