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
    scaleInPolicy: {
      rules: [
    'Default'
      ]
      forceDeletion: false
    }
    virtualMachineProfile: {
      osProfile: {
        computerNamePrefix: 'vmss'
        adminUsername: adminUsername
        adminPassword: adminPassword
        secrets: []
        allowExtensionOperations: true
        requireGuestProvisionSignal: true
      }
      storageProfile: {
        imageReference: {
          publisher: 'canonical'
          offer: '0001-com-ubuntu-server-jammy'
          sku: '22_04-lts-gen2'
          version: 'latest'
        }
        osDisk: {
          osType: 'Linux'
          createOption: 'FromImage'
          caching: 'ReadWrite'
          managedDisk: {
            storageAccountType: 'Premium_LRS'
          }
          diskSizeGB: 30
        }
        diskControllerType: 'SCSI'
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: 'vmssNicConfig'
            properties: {
              primary: true
              enableAcceleratedNetworking: false
              disableTcpStateTracking: false
              dnsSettings: {
                dnsServers: []
              }
              enableIPForwarding: false
              ipConfigurations: [
                {
                  name: 'vmssIpConfig'
                  properties: {
                    primary: true
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
      diagnosticsProfile: {
        bootDiagnostics: {
          enabled: false        }
      }
    }
    overprovision: false
    platformFaultDomainCount: 1
  }
}

