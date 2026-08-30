using System.Net;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;

namespace SampleApp.FunctionApp;

public class WeatherFunction
{
    private readonly ILogger _logger;
    private static readonly string[] Summaries = new[] { "Freezing", "Bracing", "Chilly", "Cool", "Mild", "Warm", "Balmy", "Hot", "Sweltering", "Scorching" };

    public WeatherFunction(ILoggerFactory loggerFactory) => _logger = loggerFactory.CreateLogger<WeatherFunction>();

    [Function("GetWeatherForecast")]
    public HttpResponseData Run([HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "weatherforecast")] HttpRequestData req)
    {
        var forecasts = Enumerable.Range(1, 5).Select(index => new
        {
            Date = DateOnly.FromDateTime(DateTime.Now.AddDays(index)).ToString("yyyy-MM-dd"),
            TemperatureC = Random.Shared.Next(-20, 55),
            Summary = Summaries[Random.Shared.Next(Summaries.Length)]
        }).ToArray();

        var response = req.CreateResponse(HttpStatusCode.OK);
        response.Headers.Add("Content-Type", "application/json; charset=utf-8");
        response.WriteString(System.Text.Json.JsonSerializer.Serialize(forecasts));
        return response;
    }
}
