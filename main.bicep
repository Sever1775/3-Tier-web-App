param location string = resourceGroup().location
@secure()
param adminPassword string

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
  }
}

module apptierModule 'modules/apptier.bicep' = {
  name: 'deployapptier'
  params: {
    location: location
    adminPassword : adminPassword
    dbConnectionString: dbtierModule.outputs.dbConnectionString
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
    location: location
    sqlAdminPassword: sqlAdminPassword
  }
}
