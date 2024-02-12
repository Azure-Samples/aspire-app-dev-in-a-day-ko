using Aliencube.YouTubeSubtitlesExtractor;
using Aliencube.YouTubeSubtitlesExtractor.Abstractions;
using Aliencube.YouTubeSubtitlesExtractor.Models;

using Azure;
using Azure.AI.OpenAI;

using Microsoft.AspNetCore.Mvc;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddHttpClient<IYouTubeVideo, YouTubeVideo>();
builder.Services.AddScoped<OpenAIClient>(sp =>
{
    var config = sp.GetRequiredService<IConfiguration>();
    var endpoint = new Uri(config["OpenAI:Endpoint"]);
    var credential = new AzureKeyCredential(config["OpenAI:ApiKey"]);
    var client = new OpenAIClient(endpoint, credential);

    return client;
});
builder.Services.AddScoped<YouTubeSummariserService>();

// Add services to the container.
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

if (app.Environment.IsDevelopment())
{
    app.MapGet("/", () => Results.Redirect("/swagger")).ExcludeFromDescription();
}

var summaries = new[]
{
    "Freezing", "Bracing", "Chilly", "Cool", "Mild", "Warm", "Balmy", "Hot", "Sweltering", "Scorching"
};

app.MapGet("/weatherforecast", () =>
{
    var forecast =  Enumerable.Range(1, 5).Select(index =>
        new WeatherForecast
        (
            DateOnly.FromDateTime(DateTime.Now.AddDays(index)),
            Random.Shared.Next(-20, 55),
            summaries[Random.Shared.Next(summaries.Length)]
        ))
        .ToArray();
    return forecast;
})
.WithName("GetWeatherForecast")
.WithOpenApi();

app.MapPost("/summarise", async ([FromBody] SummaryRequest req, YouTubeSummariserService service) =>
{
    var summary = await service.SummariseAsync(req);
    return summary;
})
.WithName("GetSummary")
.WithOpenApi();

app.Run();

record WeatherForecast(DateOnly Date, int TemperatureC, string? Summary)
{
    public int TemperatureF => 32 + (int)(TemperatureC / 0.5556);
}

record SummaryRequest(string? YouTubeLinkUrl, string VideoLanguageCode, string? SummaryLanguageCode);

class YouTubeSummariserService(IYouTubeVideo youtube, OpenAIClient openai, IConfiguration config)
{
    private readonly IYouTubeVideo _youtube = youtube ?? throw new ArgumentNullException(nameof(youtube));
    private readonly OpenAIClient _openai = openai ?? throw new ArgumentNullException(nameof(openai));
    private readonly IConfiguration _config = config ?? throw new ArgumentNullException(nameof(config));

    public async Task<string> SummariseAsync(SummaryRequest req)
    {
        Subtitle subtitle = await this._youtube.ExtractSubtitleAsync(req.YouTubeLinkUrl, req.VideoLanguageCode).ConfigureAwait(false);
        string caption = subtitle.Content.Select(p => p.Text).Aggregate((a, b) => $"{a}\n{b}");

        ChatCompletionsOptions options = new()
        {
            DeploymentName = this._config["OpenAI:DeploymentName"],
            MaxTokens = int.Parse(this._config["Prompt:MaxTokens"]),
            Temperature = float.Parse(this._config["Prompt:Temperature"]),
        };
        options.Messages.Add(new ChatRequestSystemMessage(this._config["Prompt:System"]));
        options.Messages.Add(new ChatRequestSystemMessage($"Here's the transcript. Summarise it in 5 bullet point items in the given language code of \"{req.SummaryLanguageCode}\"."));
        options.Messages.Add(new ChatRequestUserMessage(caption));

        var response = await this._openai.GetChatCompletionsAsync(options).ConfigureAwait(false);
        string summary = response.Value.Choices[0].Message.Content;

        return summary;
    }
}
