var builder = DistributedApplication.CreateBuilder(args);
var apiapp = builder.AddProject<Projects.AspireYouTubeSummariser_ApiApp>("apiapp");

builder.AddProject<Projects.AspireYouTubeSummariser_WebApp>("webapp")
       .WithReference(apiapp);
builder.Build().Run();
