namespace AspireYouTubeSummariser.WebApp.Clients;

public interface IApiAppClient
{
    Task<string> SummariseAsync(string youTubeLinkUrl, string videoLanguageCode, string summaryLanguageCode);
}

public class ApiAppClient(HttpClient http) : IApiAppClient
{
    private readonly HttpClient _http = http ?? throw new ArgumentNullException(nameof(http));

    public async Task<string> SummariseAsync(string youTubeLinkUrl, string videoLanguageCode, string summaryLanguageCode)
    {
        using var response = await _http.PostAsJsonAsync(
            "summarise",
            new { youTubeLinkUrl, videoLanguageCode, summaryLanguageCode }).ConfigureAwait(false);

        var summary = await response.Content.ReadAsStringAsync().ConfigureAwait(false);
        return summary;
    }
}
