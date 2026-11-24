-- Weather forecast records returned by the sample API.
-- The shape is inferred from the frontend model and the backend JSON payload used by the weather sample.
-- Source: [WeatherForecast.cs](../../../../SampleApp/FrontEnd/Data/WeatherForecast.cs#L1-L15)
-- Source: [WeatherFunction.cs](../../../../SampleApp/FunctionApp/WeatherFunction.cs#L8-L30)
-- Source: [Program.cs](../../../../SampleApp/BackEnd/Program.cs#L19-L29)
-- TODO: verify columns/types — inferred from usage

CREATE TABLE WeatherForecast (
    ForecastDate DATE NOT NULL,
    TemperatureC INTEGER NOT NULL,
    Summary VARCHAR(64) NULL,
    CONSTRAINT PK_WeatherForecast PRIMARY KEY (ForecastDate),
    CONSTRAINT CK_WeatherForecast_TemperatureC CHECK (TemperatureC BETWEEN -100 AND 100)
);

CREATE INDEX IX_WeatherForecast_TemperatureC
    ON WeatherForecast (TemperatureC);

CREATE INDEX IX_WeatherForecast_Summary
    ON WeatherForecast (Summary);

-- Note: TemperatureF is a derived property in the .NET model and is not persisted by the API payload.
-- Source: [WeatherForecast.cs](../../../../SampleApp/FrontEnd/Data/WeatherForecast.cs#L5-L15)
