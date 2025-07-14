param location string
param adminUsername string = 'azureuser'


@secure()
param adminPassword string


resource VMSS 'Microsoft.Compute/virtualMachineScaleSets@2024-03-01' = {
  name: 'AppTierVMSS'
  location: location
  sku: {
    name: 'Standard_d2s_v3'
    tier: 'Standard'
    capacity: 1
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
        computerNamePrefix: 'apptiervmss'
        adminUsername: adminUsername
        adminPassword: adminPassword
        linuxConfiguration: null
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
            name: 'apptiervmssNicConfig'
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
                  name: 'apptiervmssIpConfig'
                  properties: {
                    primary: true
                    subnet: {
                      id: resourceId('Microsoft.Network/virtualNetworks/subnets', 'myVNet', 'AppSubnet')
                    }
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
  }
}

