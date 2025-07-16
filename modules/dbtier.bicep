@description('Location for Database resources')
param location string = 'northeurope'

@description('SQL Server name (must be globally unique)')
param sqlServerName string = 'mysqlserverforapptier9514789'

@description('SQL Admin username')
param sqlAdminUsername string = 'sqldbadminuser'

@secure()
param sqlAdminPassword string

@description('SQL Database name')
param sqlDatabaseName string = 'appdb'

@secure()
param natGatewaypip string

// SQL Server
resource sqlServer 'Microsoft.Sql/servers@2024-05-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: sqlAdminUsername
    administratorLoginPassword: sqlAdminPassword  }

}

resource sqlFirewallRule 'Microsoft.Sql/servers/firewallRules@2024-05-01-preview' = {
  parent: sqlServer
  name: 'AllowAllAzureIPs'
  properties: {
    startIpAddress: natGatewaypip
    endIpAddress: natGatewaypip
  }
}

// SQL Database
resource sqlDatabase 'Microsoft.Sql/servers/databases@2024-05-01-preview' = {
  parent: sqlServer
  name: sqlDatabaseName
  location: location
  sku: {
    name: 'Basic'
    tier: 'Basic'
    capacity: 5
  }
}

output DB_USER string = sqlAdminUsername
output DB_NAME string = sqlDatabaseName
output DB_SERVER string = reference(sqlServer.id, '2021-11-01').fullyQualifiedDomainName
