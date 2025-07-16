@description('Location for Load Balancer resources')
param location string

@description('Name of the Internal Load Balancer')
param loadBalancerName string = 'InternalLoadBalancer'

@description('Name of the NAT Gateway')
param natgatewayname string = 'NatGatewayILB'

@description('Name of the Public IP for NAT Gateway')
param natgatewaypublicIPName string = 'NatGateway-PIP'

resource loadbalancer 'Microsoft.Network/loadBalancers@2024-05-01' = {
  name: loadBalancerName
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
  name: natgatewaypublicIPName
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
  name: natgatewayname
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
