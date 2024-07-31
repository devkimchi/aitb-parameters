var builder = DistributedApplication.CreateBuilder(args);

var numberOfDays = builder.AddParameter("NumberOfDays");

var secrets = builder.AddAzureKeyVault("secrets");

var apim = builder.AddBicepTemplate(name: "apim",
                                    bicepFile: "../infra/core/gateway/apim.bicep")
                  .WithParameter("name", "apim-aitb4567")
                  .WithParameter("keyVaultName", secrets.Resource.Name);

var apimServiceName = apim.GetOutput("apimServiceName");
//var apimSubscriptionKey = apim.GetOutput("apimSubscriptionKey");
var apimSubscriptionKey = apim.GetSecretOutput("apimSubscriptionKey");

var apiService = builder.AddProject<Projects.AspireInTheBelly_ApiService>("apiservice")
                        .WithEnvironment("NUMBER_OF_DAYS", numberOfDays)
                        .WithEnvironment("APIM_BASE_URL", $"https://{apimServiceName}.azure-api.net")
                        .WithEnvironment("APIM_SUBSCRIPTION_KEY", apimSubscriptionKey);

builder.AddProject<Projects.AspireInTheBelly_Web>("webfrontend")
    .WithExternalHttpEndpoints()
    .WithReference(apiService);

builder.Build().Run();
