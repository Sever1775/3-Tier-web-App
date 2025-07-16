@description('Location for Network resources')
param location string

@description('natGatewayId for the App Subnet')
param natGatewayId string

@description('Name of the Virtual Network')
param vnetName string = 'myVNet'

@description('Name of the Network Security Group for the Web Subnet')
param webSubnetNSGName string = 'webNSG'

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
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


resource webNSG 'Microsoft.Network/networkSecurityGroups@2024-07-01' = {
  name: webSubnetNSGName
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
