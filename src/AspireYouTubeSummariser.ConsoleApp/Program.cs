using System.Text;

using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Microsoft.KernelMemory;
using Microsoft.KernelMemory.AI.OpenAI;

var config = new ConfigurationBuilder()
                 .AddEnvironmentVariables()
                 .AddJsonFile("appsettings.json", optional: false, reloadOnChange: true)
                 .AddJsonFile("appsettings.Development.json", optional: true, reloadOnChange: true)
                 .Build();

var questions = config.GetSection("Questions").Get<List<string>>();
var km = config.GetSection("KernelMemory")
               .Get<KernelMemoryConfig>();
var openaiText = config.GetSection("KernelMemory")
                       .GetSection("Services")
                       .GetSection("AzureOpenAIText")
                       .Get<AzureOpenAIConfig>();
var openaiEmbedding = config.GetSection("KernelMemory")
                            .GetSection("Services")
                            .GetSection("AzureOpenAIEmbedding")
                            .Get<AzureOpenAIConfig>();

var tokeniser = new DefaultGPTTokenizer();

var memory = new KernelMemoryBuilder()
                 .Configure(kmb => kmb.Services.AddLogging(lb =>
                 {
                     lb.SetMinimumLevel(LogLevel.Trace);
                     lb.AddSimpleConsole(c => c.SingleLine = true);
                 }))
                 .AddSingleton(km!)
                 .WithAzureOpenAITextGeneration(openaiText!, tokeniser)
                 .WithAzureOpenAITextEmbeddingGeneration(openaiEmbedding!, tokeniser)
                 .Build<MemoryServerless>();

var memories = await LoadJson(memory);
await AskQuestions(memory, questions);
await DeleteMemories(memory, memories);

Console.ForegroundColor = ConsoleColor.Green;
Console.WriteLine("\n# DONE");
Console.ResetColor();

static async Task<List<string>> LoadJson(MemoryServerless memory)
{
    var memories = new List<string>();

    Console.ForegroundColor = ConsoleColor.Cyan;
    Console.WriteLine("Storing JSON data to the memory...");
    Console.ResetColor();

    var today = DateTimeOffset.UtcNow
                              .ToOffset(TimeZoneInfo.FindSystemTimeZoneById("Korea Standard Time").BaseUtcOffset)
                              .ToString("yyyyMMdd");
    var http = new HttpClient();
    var data = await http.GetStringAsync($"https://raw.githubusercontent.com/aliencube/MelonChart.NET/main/data/top100-{today}.json");

    using var ms = new MemoryStream(Encoding.UTF8.GetBytes(data));

    var docId = await memory.ImportDocumentAsync(ms, documentId: $"top100-{today}");

    Console.ForegroundColor = ConsoleColor.Cyan;
    Console.WriteLine($"- Document Id: {docId}");
    Console.ResetColor();

    memories.Add(docId);

    return memories;
}

static async Task AskQuestions(MemoryServerless memory, List<string> questions)
{
    foreach (var question in questions)
    {
        Console.ForegroundColor = ConsoleColor.Cyan;
        Console.WriteLine($"\nQuestion: {question}\n");
        Console.ResetColor();

        var answer = await memory.AskAsync(question);

        Console.ForegroundColor = ConsoleColor.Cyan;
        Console.WriteLine($"\nAnswer: {answer.Result}\n");
        Console.ResetColor();
    }

    Console.ForegroundColor = ConsoleColor.Yellow;
    Console.WriteLine("\n====================================\n");
    Console.ResetColor();
}

static async Task DeleteMemories(MemoryServerless memory, List<string> memories)
{
    foreach (var docId in memories)
    {
        Console.ForegroundColor = ConsoleColor.Cyan;
        Console.WriteLine($"Deleting memories derived from {docId}");
        Console.ResetColor();

        await memory.DeleteDocumentAsync(docId);
    }
}
