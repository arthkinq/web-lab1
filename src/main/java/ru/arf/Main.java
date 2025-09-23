package ru.arf;

import com.fastcgi.FCGIInterface;

import java.io.InputStreamReader;
import java.io.Reader;
import java.io.UnsupportedEncodingException;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;

public class Main {

    public static void main(String[] args) {
        var fcgi = new FCGIInterface();
        System.err.println("FastCGI Server started");

        while (fcgi.FCGIaccept() >= 0) {
            long startTime = System.nanoTime();

            try {
                int contentLength = Integer.parseInt(System.getProperties().getProperty("CONTENT_LENGTH", "0"));

                if (contentLength <= 0) {
                    throw new IllegalArgumentException("No POST data received.");
                }

                Reader in = new InputStreamReader(System.in, StandardCharsets.UTF_8);
                char[] buffer = new char[contentLength];
                in.read(buffer);
                String postData = new String(buffer);

                Map<String, String> params = parseQueryString(postData);

                double x = Double.parseDouble(params.get("x"));
                double y = Double.parseDouble(params.get("y"));
                double r = Double.parseDouble(params.get("r"));

                boolean hit = checkHit(x, y, r);
                String currentTime = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
                double executionTimeMs = (double)(System.nanoTime() - startTime) / 1_000_000.0;

                String jsonBody = String.format(Locale.US,
                        "{\"x\":%.2f, \"y\":%.2f, \"r\":%.2f, \"hit\":%b, \"currentTime\":\"%s\", \"executionTime\":%.4f}",
                        x, y, r, hit, currentTime, executionTimeMs
                );

                String cgiResponse = "Content-Type: application/json\r\n" +
                        "\r\n" +
                        jsonBody;

                System.out.print(cgiResponse);

            } catch (Exception e) {
                double executionTimeMs = (double)(System.nanoTime() - startTime) / 1_000_000.0;
                String reason = e.getMessage() != null ? e.getMessage() : "Invalid or missing parameters.";
                String jsonBody = String.format(Locale.US, "{\"error\":\"%s\", \"executionTime\":%.4f}", reason, executionTimeMs);

                String cgiErrorResponse = "Status: 400 Bad Request\r\n" +
                        "Content-Type: application/json\r\n" +
                        "\r\n" +
                        jsonBody;

                System.out.print(cgiErrorResponse);
            } finally {
                System.out.flush();
            }
        }
    }

    private static boolean checkHit(double x, double y, double r) {
        if (x >= 0 && y >= 0) {
            return (x * x + y * y) <= (r / 2) * (r / 2);
        }
        if (x <= 0 && y <= 0) {
            return (x >= -r) && (y >= -r);
        }
        if (x >= 0 && y <= 0) {
            return y >= (x - r / 2);
        }
        return false;
    }

    private static Map<String, String> parseQueryString(String qs) throws UnsupportedEncodingException {
        Map<String, String> result = new HashMap<>();
        if (qs == null || qs.isEmpty()) {
            return result;
        }
        for (String param : qs.split("&")) {
            String[] pair = param.split("=", 2);
            if (pair.length > 1 && !pair[1].isEmpty()) {
                result.put(URLDecoder.decode(pair[0], "UTF-8"), URLDecoder.decode(pair[1], "UTF-8"));
            }
        }
        return result;
    }
}