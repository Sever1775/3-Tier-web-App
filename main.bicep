param location string = resourceGroup().location
@secure()
param adminPassword string

module networkModule 'modules/network.bicep' = {
  name: 'deploynetworks'
  params: {
    location: location
  }
}
module webTierModule 'modules/webtier.bicep' = {
  name: 'deploywebtier'
  params: {
    location: location
    adminPassword: adminPassword
  }
}
module appGatewayModule 'modules/appgw.bicep' = {
  name: 'deployappgateway'
  params: {
    location: location
  }
}
