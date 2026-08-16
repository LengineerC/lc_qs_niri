pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.common

Singleton {
    id: root

    readonly property int refreshInterval: 30 * 60 * 1000

    property bool ready: false
    property bool loading: true
    property string error: ""
    property var current: ({})
    property var hourlyForecast: []
    property var dailyForecast: []
    property date lastUpdated: new Date(0)
    property string dataLocationKey: ""

    property string locationSearchStatus: ""
    property string locationSearchError: ""
    property bool refreshAgain: false

    readonly property string locationName:
        ShellSettings.weatherLocationName
    readonly property string currentIcon: icon(
        current.weatherCode ?? -1, current.isDay ?? 1)
    readonly property string currentTemperature:
        current.temperature === undefined
            ? "--°C" : Math.round(current.temperature) + "°C"

    function load() {
        // Forces singleton construction from shell.qml.
    }

    function valueAt(values, index, fallback = 0) {
        if (!Array.isArray(values) || index < 0
                || index >= values.length)
            return fallback;
        const value = Number(values[index]);
        return Number.isFinite(value) ? value : fallback;
    }

    function textAt(values, index, fallback = "") {
        if (!Array.isArray(values) || index < 0
                || index >= values.length)
            return fallback;
        return String(values[index] ?? fallback);
    }

    function icon(code, isDay = 1) {
        const value = Number(code);
        if (value === 0)
            return Number(isDay) === 0 ? "󰖔" : "󰖙";
        if (value === 1 || value === 2)
            return Number(isDay) === 0 ? "󰼱" : "󰖕";
        if (value === 3)
            return "󰖐";
        if (value === 45 || value === 48)
            return "󰖑";
        if (value >= 51 && value <= 57)
            return "󰖗";
        if ((value >= 61 && value <= 67)
                || (value >= 80 && value <= 82))
            return "󰖖";
        if ((value >= 71 && value <= 77)
                || value === 85 || value === 86)
            return "󰖘";
        if (value >= 95)
            return "󰖓";
        return "󰖐";
    }

    function description(code) {
        const value = Number(code);
        const english = I18n.language === "en_US";
        if (value === 0)
            return english ? "Clear sky" : "晴朗";
        if (value === 1)
            return english ? "Mainly clear" : "大部晴朗";
        if (value === 2)
            return english ? "Partly cloudy" : "局部多云";
        if (value === 3)
            return english ? "Overcast" : "阴天";
        if (value === 45 || value === 48)
            return english ? "Fog" : "有雾";
        if (value >= 51 && value <= 57)
            return english ? "Drizzle" : "毛毛雨";
        if (value >= 61 && value <= 67)
            return english ? "Rain" : "降雨";
        if (value >= 71 && value <= 77)
            return english ? "Snow" : "降雪";
        if (value >= 80 && value <= 82)
            return english ? "Rain showers" : "阵雨";
        if (value === 85 || value === 86)
            return english ? "Snow showers" : "阵雪";
        if (value === 95)
            return english ? "Thunderstorm" : "雷暴";
        if (value === 96 || value === 99)
            return english ? "Thunderstorm with hail" : "雷暴伴冰雹";
        return english ? "Unknown weather" : "未知天气";
    }

    function formatTemperature(value) {
        const number = Number(value);
        return Number.isFinite(number)
            ? Math.round(number) + "°C" : "--°C";
    }

    function formatPercent(value) {
        const number = Number(value);
        return Number.isFinite(number)
            ? Math.round(number) + "%" : "--%";
    }

    function formatWind(value) {
        const number = Number(value);
        return Number.isFinite(number)
            ? Math.round(number) + " km/h" : "-- km/h";
    }

    function formatPressure(value) {
        const number = Number(value);
        return Number.isFinite(number)
            ? Math.round(number) + " hPa" : "-- hPa";
    }

    function formatVisibility(value) {
        const number = Number(value);
        return Number.isFinite(number)
            ? (number / 1000).toFixed(1) + " km" : "-- km";
    }

    function timeFromIso(value) {
        const text = String(value || "");
        return text.length >= 16 ? text.slice(11, 16) : "--:--";
    }

    function dayName(value) {
        const date = new Date(String(value) + "T12:00:00");
        if (Number.isNaN(date.getTime()))
            return "--";
        return I18n.locale.toString(date, "ddd");
    }

    function shortDate(value) {
        const date = new Date(String(value) + "T12:00:00");
        if (Number.isNaN(date.getTime()))
            return "--";
        return I18n.locale.toString(date, "MM/dd");
    }

    function coordinateKey(latitude, longitude) {
        const lat = Number(latitude);
        const lon = Number(longitude);
        if (!Number.isFinite(lat) || !Number.isFinite(lon))
            return "";
        return lat.toFixed(5) + "," + lon.toFixed(5);
    }

    function configuredLocationKey() {
        return coordinateKey(
            ShellSettings.weatherLatitude,
            ShellSettings.weatherLongitude
        );
    }

    function invalidateForecast() {
        ready = false;
        loading = true;
        current = ({});
        hourlyForecast = [];
        dailyForecast = [];
        dataLocationKey = "";
        lastUpdated = new Date(0);
        error = "";
    }

    function parseForecast(text, requestLocationKey) {
        /*
         * 设置加载或用户切换地点后，旧 curl 进程仍可能晚一步返回。
         * 只有响应坐标仍与当前设置一致时才允许写入界面。
         */
        if (!requestLocationKey
                || requestLocationKey !== configuredLocationKey()) {
            return;
        }

        try {
            const data = JSON.parse(String(text));
            if (!data.current || !data.hourly || !data.daily)
                throw new Error("Incomplete Open-Meteo response");

            const hourly = data.hourly;
            const daily = data.daily;
            const currentTime = String(data.current.time || "");
            const currentHour = currentTime.slice(0, 13) + ":00";
            let currentIndex = Array.isArray(hourly.time)
                ? hourly.time.indexOf(currentHour) : -1;
            if (currentIndex < 0 && Array.isArray(hourly.time)) {
                currentIndex = hourly.time.findIndex(
                    value => String(value) >= currentHour);
            }
            const firstFutureIndex = Math.max(0, currentIndex + 1);

            current = {
                time: currentTime,
                temperature: Number(data.current.temperature_2m),
                apparentTemperature:
                    Number(data.current.apparent_temperature),
                humidity: Number(data.current.relative_humidity_2m),
                precipitation: Number(data.current.precipitation),
                precipitationProbability: valueAt(
                    hourly.precipitation_probability,
                    Math.max(0, currentIndex), 0),
                pressure: Number(data.current.pressure_msl),
                windSpeed: Number(data.current.wind_speed_10m),
                weatherCode: Number(data.current.weather_code),
                isDay: Number(data.current.is_day),
                sunrise: textAt(daily.sunrise, 0),
                sunset: textAt(daily.sunset, 0)
            };

            const nextHours = [];
            for (let offset = 0; offset < 5; offset++) {
                const index = firstFutureIndex + offset;
                if (!Array.isArray(hourly.time)
                        || index >= hourly.time.length)
                    break;
                nextHours.push({
                    time: textAt(hourly.time, index),
                    temperature: valueAt(
                        hourly.temperature_2m, index),
                    apparentTemperature: valueAt(
                        hourly.apparent_temperature, index),
                    humidity: valueAt(
                        hourly.relative_humidity_2m, index),
                    precipitationProbability: valueAt(
                        hourly.precipitation_probability, index),
                    pressure: valueAt(hourly.pressure_msl, index),
                    windSpeed: valueAt(
                        hourly.wind_speed_10m, index),
                    visibility: valueAt(hourly.visibility, index),
                    weatherCode: valueAt(
                        hourly.weather_code, index),
                    isDay: valueAt(hourly.is_day, index, 1)
                });
            }

            const nextDays = [];
            const dayCount = Math.min(7,
                Array.isArray(daily.time) ? daily.time.length : 0);
            for (let index = 0; index < dayCount; index++) {
                nextDays.push({
                    date: textAt(daily.time, index),
                    weatherCode: valueAt(
                        daily.weather_code, index),
                    temperatureMax: valueAt(
                        daily.temperature_2m_max, index),
                    temperatureMin: valueAt(
                        daily.temperature_2m_min, index),
                    precipitationProbability: valueAt(
                        daily.precipitation_probability_max, index)
                });
            }

            hourlyForecast = nextHours;
            dailyForecast = nextDays;
            dataLocationKey = requestLocationKey;
            ready = true;
            error = "";
            lastUpdated = new Date();
        } catch (exception) {
            error = String(exception);
            console.warn("WeatherService: cannot parse forecast:",
                exception);
        }
    }

    function forecastUrl(latitude, longitude) {
        const currentFields = [
            "temperature_2m", "relative_humidity_2m",
            "apparent_temperature", "is_day", "precipitation",
            "weather_code", "pressure_msl", "wind_speed_10m"
        ].join(",");
        const hourlyFields = [
            "temperature_2m", "relative_humidity_2m",
            "apparent_temperature", "precipitation_probability",
            "weather_code", "pressure_msl", "wind_speed_10m",
            "visibility", "is_day"
        ].join(",");
        const dailyFields = [
            "weather_code", "temperature_2m_max",
            "temperature_2m_min", "precipitation_probability_max",
            "sunrise", "sunset"
        ].join(",");
        return "https://api.open-meteo.com/v1/forecast"
            + "?latitude=" + latitude.toFixed(5)
            + "&longitude=" + longitude.toFixed(5)
            + "&current=" + currentFields
            + "&hourly=" + hourlyFields
            + "&daily=" + dailyFields
            + "&timezone=auto&forecast_days=7";
    }

    function refresh() {
        /*
         * ShellSettings 使用 FileView 异步恢复。它就绪前的坐标只是
         * 默认值，不能据此发起启动请求。
         */
        if (!ShellSettings.ready) {
            refreshAgain = true;
            return;
        }

        if (forecastProcess.running) {
            refreshAgain = true;
            return;
        }

        const latitude = Number(ShellSettings.weatherLatitude);
        const longitude = Number(ShellSettings.weatherLongitude);
        const requestLocationKey = coordinateKey(latitude, longitude);
        if (!requestLocationKey)
            return;

        loading = true;
        error = "";
        forecastProcess.locationKey = requestLocationKey;
        forecastProcess.command = [
            "curl", "-fsSL", "--max-time", "20",
            forecastUrl(latitude, longitude)
        ];
        forecastProcess.running = true;
    }

    function searchLocation(query) {
        const value = String(query || "").trim();
        if (value.length < 2 || locationProcess.running)
            return;
        locationSearchStatus = "searching";
        locationSearchError = "";
        const language = I18n.language === "en_US" ? "en" : "zh";
        const url = "https://geocoding-api.open-meteo.com/v1/search"
            + "?name=" + encodeURIComponent(value)
            + "&count=1&language=" + language + "&format=json";
        locationProcess.command = [
            "curl", "-fsSL", "--max-time", "20", url
        ];
        locationProcess.running = true;
    }

    function setCoordinates(latitude, longitude) {
        const lat = Number(latitude);
        const lon = Number(longitude);
        if (!Number.isFinite(lat) || !Number.isFinite(lon)
                || lat < -90 || lat > 90
                || lon < -180 || lon > 180)
            return false;

        const latitudeText = lat.toFixed(5);
        const longitudeText = lon.toFixed(5);
        locationSearchStatus = "";
        locationSearchError = "";
        ShellSettings.weatherLocationName =
            latitudeText + ", " + longitudeText;
        ShellSettings.weatherLatitude = lat;
        ShellSettings.weatherLongitude = lon;
        locationRefreshDelay.restart();
        return true;
    }

    function parseLocation(text) {
        try {
            const data = JSON.parse(String(text));
            if (!Array.isArray(data.results)
                    || data.results.length === 0) {
                locationSearchStatus = "notFound";
                return;
            }
            const result = data.results[0];
            const parts = [
                result.name, result.admin1, result.country
            ].filter(value => String(value || "").trim());
            ShellSettings.weatherLocationName = parts.join(", ");
            ShellSettings.weatherLatitude = Number(result.latitude);
            ShellSettings.weatherLongitude = Number(result.longitude);
            locationSearchStatus = "success";
            locationRefreshDelay.restart();
        } catch (exception) {
            locationSearchStatus = "failed";
            locationSearchError = String(exception);
        }
    }

    Component.onCompleted: {
        if (ShellSettings.ready)
            refresh();
    }

    Connections {
        target: ShellSettings

        function onReadyChanged() {
            if (!ShellSettings.ready)
                return;

            locationRefreshDelay.stop();
            root.refreshAgain = false;
            root.refresh();
        }

        function onWeatherLatitudeChanged() {
            root.invalidateForecast();
            if (ShellSettings.ready)
                locationRefreshDelay.restart();
        }
        function onWeatherLongitudeChanged() {
            root.invalidateForecast();
            if (ShellSettings.ready)
                locationRefreshDelay.restart();
        }
    }

    Timer {
        interval: root.refreshInterval
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Timer {
        id: locationRefreshDelay
        interval: 250
        onTriggered: root.refresh()
    }

    Process {
        id: forecastProcess

        property string locationKey: ""

        stdout: StdioCollector {
            onStreamFinished:
                root.parseForecast(text, forecastProcess.locationKey)
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim()
                        && forecastProcess.locationKey
                            === root.configuredLocationKey()) {
                    root.error = text.trim();
                }
            }
        }
        onExited: exitCode => {
            const responseMatchesLocation =
                forecastProcess.locationKey
                    === root.configuredLocationKey();

            /*
             * 旧地点响应退出或已有下一次刷新排队时维持加载态，
             * 避免两次请求之间闪出“天气不可用”。
             */
            root.loading = !responseMatchesLocation || root.refreshAgain;
            if (exitCode !== 0 && !root.error
                    && responseMatchesLocation) {
                root.error = "Open-Meteo request failed";
            }
            if (root.refreshAgain) {
                root.refreshAgain = false;
                Qt.callLater(() => root.refresh());
            }
        }
    }

    Process {
        id: locationProcess

        stdout: StdioCollector {
            onStreamFinished: root.parseLocation(text)
        }
        stderr: StdioCollector {
            onStreamFinished: root.locationSearchError = text.trim()
        }
        onExited: exitCode => {
            if (exitCode !== 0)
                root.locationSearchStatus = "failed";
        }
    }
}
