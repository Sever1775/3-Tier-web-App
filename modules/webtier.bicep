param location string
param adminUsername string = 'azureuser'
@secure()
param adminPassword string

resource VMSS 'Microsoft.Compute/virtualMachineScaleSets@2024-03-01' = {
  name: 'myVMSS'
  location: location
  sku: {
    name: 'Standard_DS1_v2'
    tier: 'Standard'
    capacity: 2
  }
  properties: {
    singlePlacementGroup: false
    orchestrationMode: 'Uniform'
    upgradePolicy: {
      mode: 'Manual'
    }
    virtualMachineProfile: {
      osProfile: {
        computerNamePrefix: 'vmss'
        adminUsername: adminUsername
        adminPassword: adminPassword
      }
      storageProfile: {
        imageReference: {
          publisher: 'Canonical'
          offer: '0001-com-ubuntu-server-jammy'
          sku: '22_04-lts-gen2'
          version: 'latest'
        }
        osDisk: {
          createOption: 'FromImage'
          caching: 'ReadWrite'
        }
      }
      securityProfile: {
        securityType: 'TrustedLaunch'
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: 'vmssNicConfig'
            properties: {
              primary: true
              ipConfigurations: [
                {
                  name: 'vmssIpConfig'
                  properties: {
                    subnet: {
                      id: resourceId('Microsoft.Network/virtualNetworks/subnets', 'myVNet', 'AppSubnet')
                    }
                    loadBalancerBackendAddressPools: [
                      {
                        id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', 'myAppGateway', 'appGatewayBackendPool')
                      }
                    ]
                  }
                }
              ]
            }
          }
        ]
      }
    }
  }
}
