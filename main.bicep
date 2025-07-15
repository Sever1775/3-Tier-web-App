param location string = resourceGroup().location
@secure()
param adminPassword string


@secure()
param sqlAdminPassword string



module networkModule 'modules/network.bicep' = {
  name: 'deploynetworks'
  params: {
    location: location
    natGatewayId: loadbalancerModule.outputs.natgatewayId
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
    backendAddressPoolId: appgwModule.outputs.backendAddressPoolId
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


module apptierModule 'modules/apptier.bicep' = {
  name: 'deployapptier'
  params: {
    location: location
    adminPassword : adminPassword
    DB_USER: dbtierModule.outputs.DB_USER
    DB_SERVER: dbtierModule.outputs.DB_SERVER
    DB_NAME: dbtierModule.outputs.DB_NAME
    DB_PASSWORD: sqlAdminPassword
  }
}

module bastionModule 'modules/bastion.bicep' = {
  name: 'deploybastion'
  params: {
    location: location
  }
}
