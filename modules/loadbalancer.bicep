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
          privateIPAddress: '10.0.5.10'
          privateIPAllocationMethod: 'Static'
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
          backendPort: 4000
          idleTimeoutInMinutes: 4
          enableFloatingIP: false
          disableOutboundSnat: false
        }
      }
    ]
  }
}
