param location string

resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' = {
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
        name: 'BastionSubnet'
        properties: {
          addressPrefix: '10.0.1.0/24'
          networkSecurityGroup: {
            id: resourceId('Microsoft.Network/networkSecurityGroups', 'bastionNSG')
          }
        }
      }
      {
        name: 'ApplicationGatewaySubnet'
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

resource bastionNSG 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: 'bastionNSG'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowBastionInbound'
        properties: {
          priority: 100
          access: 'Allow'
          direction: 'Inbound'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource appNSG 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: 'appNSG'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowAppInbound'
        properties: {
          priority: 100
          access: 'Allow'
          direction: 'Inbound'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '80,3000,4000'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource webNSG 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: 'webNSG'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowWebInbound'
        properties: {
          priority: 100
          access: 'Allow'
          direction: 'Inbound'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '80,22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}
