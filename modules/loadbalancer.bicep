param location string

resource loadbalancer 'Microsoft.Network/loadBalancers@2024-05-01' = {
  name: 'InternalLoadBalancer'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: 'loadBalancerFrontend'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', 'myVNet', 'WebSubnet')
          }
          
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'loadBalancerBackendPool'
      }
    ]
    loadBalancingRules: [
      {
        name: 'httpRule'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', 'InternalLoadBalancer', 'loadBalancerFrontend')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', 'InternalLoadBalancer', 'loadBalancerBackendPool')
          }
          protocol: 'Tcp'
          frontendPort: 80
          backendPort: 3000
          idleTimeoutInMinutes: 4
          enableFloatingIP: false
          disableOutboundSnat: false
        }
      }
    ]
  }
}

resource natgatewaypip 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: 'NatGateway-PIP'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}


resource natgateway 'Microsoft.Network/natGateways@2024-05-01' = {
  name: 'NatGatewayILB'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIpAddresses: [
      {
        id: natgatewaypip.id
      }
    ]
    idleTimeoutInMinutes: 4
  }
}



output ilbprivateIP string = loadbalancer.properties.frontendIPConfigurations[0].properties.privateIPAddress
output natgatewayId string = natgateway.id
output natgatewaypip string = natgatewaypip.properties.ipAddress
