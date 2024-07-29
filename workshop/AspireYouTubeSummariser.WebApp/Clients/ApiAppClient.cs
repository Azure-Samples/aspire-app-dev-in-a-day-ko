namespace AspireYouTubeSummariser.WebApp.Clients;

public interface IApiAppClient
{
    Task<List<ApiAppClient.WeatherForecast>> WeatherForecastAsync();
    Task<string> SummariseAsync(string youTubeLinkUrl, string videoLanguageCode, string summaryLanguageCode);
}

public class ApiAppClient(HttpClient http) : IApiAppClient
{
    private readonly HttpClient _http = http ?? throw new ArgumentNullException(nameof(http));

    public async Task<List<WeatherForecast>> WeatherForecastAsync()
    {
        using var response = await _http.GetAsync("weatherforecast").ConfigureAwait(false);

        var forecasts = await response.Content.ReadFromJsonAsync<List<WeatherForecast>>().ConfigureAwait(false);
        return forecasts ?? [];
    }

    public async Task<string> SummariseAsync(string youTubeLinkUrl, string videoLanguageCode, string summaryLanguageCode)
    {
        using var response = await _http.PostAsJsonAsync(
            "summarise",
            new { youTubeLinkUrl, videoLanguageCode, summaryLanguageCode }).ConfigureAwait(false);

        var summary = await response.Content.ReadAsStringAsync().ConfigureAwait(false);
        return summary;
    }

    public class WeatherForecast
    {
        public DateOnly Date { get; set; }
        public int TemperatureC { get; set; }
        public string? Summary { get; set; }
        public int TemperatureF => 32 + (int)(TemperatureC / 0.5556);
    }
}