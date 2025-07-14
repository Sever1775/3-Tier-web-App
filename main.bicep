param location string = resourceGroup().location
@secure()
param adminPassword string

module networkModule 'modules/network.bicep' = {
  name: 'deploynetworks'
  params: {
    location: location
  }
}

module appgwModule 'modules/appgw.bicep' = {
  name: 'deployappgateway'
  params: {
    location: location
  }
}

module webtierModule 'modules/webtier.bicep' = {
  name: 'deploywebtier'
  params: {
    location: location
    adminPassword : adminPassword
  }
}

module apptierModule 'modules/apptier.bicep' = {
  name: 'deployapptier'
  params: {
    location: location
    adminPassword : adminPassword
  }
}

module loadbalancerModule 'modules/loadbalancer.bicep' = {
  name: 'deployloadbalancer'
  params: {
    location: location
  }
}

module bastionModule 'modules/bastion.bicep' = {
  name: 'deploybastion'
  params: {
    location: location
  }
}

