var builder = DistributedApplication.CreateBuilder(args);

var cache = builder.AddRedis("cache");

var config = builder.Configuration;

var apiapp = builder.AddProject<Projects.AspireYouTubeSummariser_ApiApp>("apiapp")
                    .WithEnvironment("OpenAI__Endpoint", config["OpenAI:Endpoint"])
                    .WithEnvironment("OpenAI__ApiKey", config["OpenAI:ApiKey"])
                    .WithEnvironment("OpenAI__DeploymentName", config["OpenAI:DeploymentName"]);

builder.AddProject<Projects.AspireYouTubeSummariser_WebApp>("webapp")
       .WithExternalHttpEndpoints()
       .WithReference(cache)
       .WithReference(apiapp);

builder.AddProject<Projects.AspireYouTubeSummariser_ConsoleApp>("consoleapp")
       .WithEnvironment("KernelMemory__Services__AzureOpenAIText__Auth", config["KernelMemory:Services:AzureOpenAIText:Auth"])
       .WithEnvironment("KernelMemory__Services__AzureOpenAIText__Endpoint", config["KernelMemory:Services:AzureOpenAIText:Endpoint"])
       .WithEnvironment("KernelMemory__Services__AzureOpenAIText__APIKey", config["KernelMemory:Services:AzureOpenAIText:APIKey"])
       .WithEnvironment("KernelMemory__Services__AzureOpenAIText__Deployment", config["KernelMemory:Services:AzureOpenAIText:Deployment"])
       .WithEnvironment("KernelMemory__Services__AzureOpenAIText__MaxTokenTotal", config["KernelMemory:Services:AzureOpenAIText:MaxTokenTotal"])
       .WithEnvironment("KernelMemory__Services__AzureOpenAIText__APIType", config["KernelMemory:Services:AzureOpenAIText:APIType"])
       .WithEnvironment("KernelMemory__Services__AzureOpenAIText__MaxRetries", config["KernelMemory:Services:AzureOpenAIText:MaxRetries"])
       .WithEnvironment("KernelMemory__Services__AzureOpenAIEmbedding__Auth", config["KernelMemory:Services:AzureOpenAIEmbedding:Auth"])
       .WithEnvironment("KernelMemory__Services__AzureOpenAIEmbedding__Endpoint", config["KernelMemory:Services:AzureOpenAIEmbedding:Endpoint"])
       .WithEnvironment("KernelMemory__Services__AzureOpenAIEmbedding__APIKey", config["KernelMemory:Services:AzureOpenAIEmbedding:APIKey"])
       .WithEnvironment("KernelMemory__Services__AzureOpenAIEmbedding__Deployment", config["KernelMemory:Services:AzureOpenAIEmbedding:Deployment"])
       .WithEnvironment("KernelMemory__Services__AzureOpenAIEmbedding__MaxTokenTotal", config["KernelMemory:Services:AzureOpenAIEmbedding:MaxTokenTotal"])
       .WithEnvironment("KernelMemory__Services__AzureOpenAIEmbedding__EmbeddingDimensions", config["KernelMemory:Services:AzureOpenAIEmbedding:EmbeddingDimensions"])
       .WithEnvironment("KernelMemory__Services__AzureOpenAIEmbedding__MaxEmbeddingBatchSize", config["KernelMemory:Services:AzureOpenAIEmbedding:MaxEmbeddingBatchSize"])
       .WithEnvironment("KernelMemory__Services__AzureOpenAIEmbedding__MaxRetries", config["KernelMemory:Services:AzureOpenAIEmbedding:MaxRetries"])
       ;

builder.Build().Run();
