param location string

param natGatewayId string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: 'myVNet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'Default'
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: '10.0.1.0/26'
        }
      }
      {
        name: 'AppGatewaySubnet'
        properties: {
          addressPrefix: '10.0.2.0/24'
        }
      }
      {
        name: 'DatabaseSubnet'
        properties: {
          addressPrefix: '10.0.3.0/24'
        }
      }
      {
        name: 'AppSubnet'
        properties: {
          addressPrefix: '10.0.4.0/24'
          natGateway: {
            id: natGatewayId
          }
          networkSecurityGroup: {
            id: resourceId('Microsoft.Network/networkSecurityGroups', 'appNSG')
          }
        }
      }
      {
        name: 'WebSubnet'
        properties: {
          addressPrefix: '10.0.5.0/24'
          networkSecurityGroup: {
            id: resourceId('Microsoft.Network/networkSecurityGroups', 'webNSG')
          }
        }
      }
    ]
  }
}


resource appNSG 'Microsoft.Network/networkSecurityGroups@2024-07-01' = {
  name: 'appNSG'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allowport3000Inbound'
        properties: {
          priority: 100
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'TCP'
          sourcePortRange: '*'
          destinationPortRange: '3000'
          sourceAddressPrefix: virtualNetwork.properties.addressSpace.addressPrefixes[5]
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource webNSG 'Microsoft.Network/networkSecurityGroups@2024-07-01' = {
  name: 'webNSG'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allowport80Inbound'
        properties: {
          priority: 100
          access: 'Allow'
          direction: 'Inbound'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
} 
