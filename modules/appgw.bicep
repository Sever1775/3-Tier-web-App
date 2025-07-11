param adminUsername string = 'azureuser'


@secure()
param adminPassword string



param location string 

resource appGateway 'Microsoft.Network/applicationGateways@2024-05-01' = {
  name: 'myAppGateway'
  location: location
    properties: {
     sku: {
      name: 'Standard_v2'
      tier: 'Standard_v2'
      family: 'Generation_1'
      capacity: 2 
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', 'myVNet', 'Default')
          }
        }
      }
    ]
    sslCertificates: []
    trustedRootCertificates: []
    trustedClientCertificates: []
    sslProfiles: []
    frontendIPConfigurations: [
      {
        name: 'appGatewayFrontendIP'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: appGatewayPublicIP.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'appGatewayFrontendPort'
        properties: {
          port: 80
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'appGatewayBackendPool'
        properties: {
          backendAddresses: []
        }
      }
    ]
    loadDistributionPolicies: []
    backendHttpSettingsCollection: [
      {
        name: 'appGatewayBackendHttpSettings'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: false
          requestTimeout: 20
        }
      }
    ]
    backendSettingsCollection: []
    httpListeners: [
      {
        name: 'appGatewayHttpListener'
        properties: { 
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', 'myAppGateway', 'appGatewayFrontendIP')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', 'myAppGateway', 'appGatewayFrontendPort')
          }
          protocol: 'Http'
          hostNames: []
          requireServerNameIndication: false
          customErrorConfigurations: []
        }
      }
    ]
    listeners: []
    urlPathMaps: []
    requestRoutingRules: [
      {
        name: 'appGatewayRoutingRule'
        properties: {
          ruleType: 'Basic'
          priority: 100
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', 'myAppGateway', 'appGatewayHttpListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', 'myAppGateway', 'appGatewayBackendPool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', 'myAppGateway', 'appGatewayBackendHttpSettings')
          }
        }
      }
    ]
    routingRules: []
    probes: []
    rewriteRuleSets: []
    redirectConfigurations: []
    privateLinkConfigurations: []
    enableHttp2: true
  }
}

resource appGatewayPublicIP 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: 'myPublicIP'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
  }
}


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
        linuxConfiguration: null
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
    platformFaultDomainCount: 2
  }
}
