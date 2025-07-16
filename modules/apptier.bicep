@description('location for AppTier resources')
param location string

@description('Admin username for AppTier VMs')
param adminUsername string = 'azureuser'

@secure()
param adminPassword string

param DB_USER string
@secure()
param DB_PASSWORD string
param DB_SERVER string
param DB_NAME string

@description('VMSS SKU properties for AppTier VMs')
param VMSSSKUName string = 'Standard_D2s_v3'
param VMSSskuTier string = 'Standard'
param VMSSInstanceCount int = 1

@description('Name of the AppTier VMSS')
param appTierVMSSName string = 'AppTierVMSS'

resource VMSS 'Microsoft.Compute/virtualMachineScaleSets@2024-03-01' = {
  name: appTierVMSSName
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
        computerNamePrefix: 'apptiervmss'
        adminUsername: adminUsername
        adminPassword: adminPassword
        linuxConfiguration: null
        customData: base64(
          replace(
            replace(
              replace(
                replace(
                  replace(
                    replace(
                      loadTextContent('../app/setup-app-tier.sh'), '__DB_USER__', DB_USER),
                      '__DB_PASSWORD__', DB_PASSWORD),
                      '__DB_SERVER__', DB_SERVER),
                      '__DB_DATABASE__', DB_NAME),
                      '__ADMIN_USER__', adminUsername),
                      '__APP_SOURCE_CODE__', base64(loadTextContent('../app/app.js'))))
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
                    loadBalancerBackendAddressPools: [
                      {
                        id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', 'InternalLoadBalancer', 'loadBalancerBackendPool')
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

