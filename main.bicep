param location string = resourceGroup().location

module networkModule 'modules/network.bicep' = {
  name: 'deploynetworks'
  params: {
    location: location
  }
}
