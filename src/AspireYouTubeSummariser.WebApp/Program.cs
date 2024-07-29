using AspireYouTubeSummariser.WebApp.Clients;
using AspireYouTubeSummariser.WebApp.Components;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddScoped<YouTubeSummariserService>();

builder.AddServiceDefaults();

builder.AddRedisOutputCache("cache");

// Add services to the container.
builder.Services.AddRazorComponents()
    .AddInteractiveServerComponents();

// builder.Services.AddHttpClient<IApiAppClient, ApiAppClient>(p => p.BaseAddress = new Uri("http://localhost:5050"));
builder.Services.AddHttpClient<IApiAppClient, ApiAppClient>(p => p.BaseAddress = new Uri("https+http://apiapp"));

var app = builder.Build();

app.UseOutputCache();

app.MapDefaultEndpoints();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapGet("/", () => Results.Redirect("/swagger")).ExcludeFromDescription();
}

app.UseHttpsRedirection();

app.UseStaticFiles();
app.UseAntiforgery();

app.MapPost("/summarise", async ([FromBody] SummaryRequest req, YouTubeSummariserService service) =>
{
    var summary = await service.SummariseAsync(req);
    return summary;
})
.WithName("GetSummary")
.WithOpenApi();

class YouTubeSummariserService
{
    public async Task<string> SummariseAsync(SummaryRequest req)
    {
        string summary = "This is a summary of the YouTube video.";

        return await Task.FromResult(summary).ConfigureAwait(false);
    }
}

app.Run();

record SummaryRequest(string? YouTubeLinkUrl, string VideoLanguageCode, string? SummaryLanguageCode);