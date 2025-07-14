param location string

resource bastionHost 'Microsoft.Network/bastionHosts@2024-05-01' = {
  name: 'myBastionHost'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'bastionIpConfig'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', 'myVNet', 'AzureBastionSubnet')
          }
          publicIPAddress: {
            id: bastionPublicIP.id
          }
        }
      }
    ]
  }
}

resource bastionPublicIP 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: 'BastionPublicIP'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 30
  }
}
