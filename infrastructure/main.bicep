param name string = 'ees-api-docs'

@allowed(['centralus', 'eastus2', 'eastasia', 'westeurope', 'westus2'])
param location string = 'westeurope'

@allowed(['Free', 'Standard'])
param sku string = 'Free'

resource staticWebApp 'Microsoft.Web/staticSites@2021-01-15' = {
    name: name
    location: location
    tags: null
    properties: {}
    sku: {
        name: sku
        size: sku
    }
}
