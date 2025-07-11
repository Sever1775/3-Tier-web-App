param location string 

var virtualNetworkName = 'my-vnet'
var subnet1Name = 'Subnet-1'
var subnet2Name = 'Subnet-2'

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
  }

  resource subnet1 'subnets' = {
    name: subnet1Name
    properties: {
      addressPrefix: '10.0.0.0/24'
    }  }

  resource subnet2 'subnets' = {
    name: subnet2Name
    properties: {
      addressPrefix: '10.0.1.0/24'
    }    
  }
}
