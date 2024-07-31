metadata description = 'Creates an Azure API Management instance.'
param name string
param location string = resourceGroup().location
param keyVaultName string
param tags object = {}

@description('The email address of the owner of the service')
@minLength(1)
param publisherEmail string = 'noreply@microsoft.com'

@description('The name of the owner of the service')
@minLength(1)
param publisherName string = 'n/a'

@description('The pricing tier of this API Management service')
@allowed([
  'Consumption'
  'Developer'
  'Standard'
  'Premium'
])
param sku string = 'Consumption'

@description('The instance size of this API Management service.')
@allowed([ 0, 1, 2 ])
param skuCount int = 0

resource apimService 'Microsoft.ApiManagement/service@2021-08-01' = {
  name: name
  location: location
  tags: union(tags, { 'azd-service-name': name })
  sku: {
    name: sku
    capacity: (sku == 'Consumption') ? 0 : ((sku == 'Developer') ? 1 : skuCount)
  }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
    // Custom properties are not supported for Consumption SKU
    customProperties: sku == 'Consumption' ? {} : {
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_RSA_WITH_AES_128_GCM_SHA256': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_RSA_WITH_AES_256_CBC_SHA256': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_RSA_WITH_AES_128_CBC_SHA256': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_RSA_WITH_AES_256_CBC_SHA': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_RSA_WITH_AES_128_CBC_SHA': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TripleDes168': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls10': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls11': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Ssl30': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls10': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls11': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Ssl30': 'false'
    }
  }
}

resource apimSubscription 'Microsoft.ApiManagement/service/subscriptions@2021-08-01' existing = {
  name: 'master'
  parent: apimService
}

resource vault 'Microsoft.KeyVault/vaults@2023-07-01' existing = if (keyVaultName != null) {
  name: keyVaultName

  resource secret 'secrets@2023-07-01' = {
      name: 'apimSubscriptionKey'
      properties: {
          value: apimSubscription.listSecrets().primaryKey
      }
  }
}

output apimServiceName string = apimService.name
//output apimSubscriptionKey string = apimSubscription.listSecrets().primaryKey
