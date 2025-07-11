param location string = resourceGroup().location
@secure()
param adminPassword string

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
    adminPassword : adminPassword
  }
}


