@description('Location for all resources')
param location string = 'northeurope'

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
    administratorLoginPassword: sqlAdminPassword  }
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



output dbServerFqdn string = '${sqlServer.name}.${environment().suffixes.sqlServerHostname}'
output dbName string = sqlDatabase.name
