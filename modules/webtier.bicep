param location string
param adminUsername string = 'azureuser'

@description('Private IP of App Tier Load Balancer')
param ilbPrivateIP string

@description('Backend Address Pool ID for Application Gateway')
param backendAddressPoolId string

@secure()
param adminPassword string

@description('VMSS SKU properties for AppTier VMs')
param VMSSSKUName string = 'Standard_D2s_v3'
param VMSSskuTier string = 'Standard'
param VMSSInstanceCount int = 1

resource VMSS 'Microsoft.Compute/virtualMachineScaleSets@2024-03-01' = {
  name: 'WebTierVMSS'
  location: location
  sku: {
    name: VMSSSKUName
    tier: VMSSskuTier
    capacity: VMSSInstanceCount
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
        computerNamePrefix: 'webtiervmss'
        adminUsername: adminUsername
        adminPassword: adminPassword
        linuxConfiguration: null
        customData: base64(replace(loadTextContent('../web/web-cloudinit.sh'), '__APP_TIER_IP_PLACEHOLDER__', ilbPrivateIP))
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
            name: 'webtiervmssNicConfig'
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
                  name: 'webtiervmssIpConfig'
                  properties: {
                    primary: true
                    subnet: {
                      id: resourceId('Microsoft.Network/virtualNetworks/subnets', 'myVNet', 'WebSubnet')
                    }
                    applicationGatewayBackendAddressPools: [
                      {
                        id: backendAddressPoolId
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
  }
}
