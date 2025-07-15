param location string = resourceGroup().location
@secure()
param adminPassword string

param sqlAdminUsername string = 'sqldbadminuser'

@secure()
param sqlAdminPassword string



module networkModule 'modules/network.bicep' = {
  name: 'deploynetworks'
  params: {
    location: location
  }
}

module appgwModule 'modules/appgw.bicep' = {
  name: 'deployappgateway'
  params: {
    location: location
  }
}

module webtierModule 'modules/webtier.bicep' = {
  name: 'deploywebtier'
  params: {
    location: location
    adminPassword : adminPassword
    ilbPrivateIP: loadbalancerModule.outputs.ilbprivateIP
  }
}

module loadbalancerModule 'modules/loadbalancer.bicep' = {
  name: 'deployloadbalancer'
  params: {
    location: location
  }
}

module dbtierModule 'modules/dbtier.bicep' = {
  name: 'deploydbtier'
  params: {
    sqlAdminPassword: sqlAdminPassword
  }
}

var dbConnectionString = 'Driver={ODBC Driver 18 for SQL Server};Server=tcp:${dbtierModule.outputs.dbServerFqdn},1433;Database=${dbtierModule.outputs.dbName};Uid=${sqlAdminUsername};Pwd=${sqlAdminPassword};Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30;'

module apptierModule 'modules/apptier.bicep' = {
  name: 'deployapptier'
  params: {
    location: location
    adminPassword : adminPassword
    dbConnectionString: dbConnectionString
  }
}

module bastionModule 'modules/bastion.bicep' = {
  name: 'deploybastion'
  params: {
    location: location
  }
}
