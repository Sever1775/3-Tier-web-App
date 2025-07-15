param location string
param adminUsername string = 'azureuser'

@description('Private IP of App Tier Load Balancer')
param ilbPrivateIP string


@secure()
param adminPassword string

var appTierIpPlaceholder = '__APP_TIER_IP_PLACEHOLDER__'

var webVmCloudInit = '''
#cloud-config
package_update: true
package_upgrade: true
packages:
  - nginx
runcmd:
  # 1. Remove the default Nginx page
  - rm /var/www/html/index.nginx-debian.html
  # 2. Create the new index.html file with your content
  - echo '${loadTextContent('./modules/index.html')}' > /var/www/html/index.html
  # 3. Use 'sed' to find the placeholder and replace it with the actual ILB IP
  - sed -i 's/${appTierIpPlaceholder}/${ilbPrivateIp}/g' /var/www/html/index.html
'''

resource VMSS 'Microsoft.Compute/virtualMachineScaleSets@2024-03-01' = {
  name: 'WebTierVMSS'
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
        computerNamePrefix: 'webtiervmss'
        adminUsername: adminUsername
        adminPassword: adminPassword
        linuxConfiguration: null
        customData: base64(webVmCloudInit)
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


