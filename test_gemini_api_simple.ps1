# Get the API key from the .env file
$envContent = Get-Content -Path ".env" -Raw
$apiKey = $envContent -replace ".*GEMINI_API_KEY=([^\r\n]*).*", '$1'
$apiKey = $apiKey.Trim()

Write-Host "Using API key: $apiKey"

# Simple test URL
$url = "https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey"

# Make a simple GET request to list available models
Write-Host "Testing API key by listing available models..."
try {
    $response = Invoke-RestMethod -Uri $url -Method Get
    Write-Host "Success! API key is working." -ForegroundColor Green
    Write-Host "Available models:"
    foreach ($model in $response.models) {
        Write-Host "- $($model.name)"
    }
} catch {
    Write-Host "Error testing API key:" -ForegroundColor Red
    Write-Host $_.Exception.Message
    if ($_.Exception.Response) {
        $statusCode = $_.Exception.Response.StatusCode.value__
        Write-Host "Status code: $statusCode"
        
        if ($statusCode -eq 429) {
            Write-Host "You've hit a rate limit. Try again later or check your quota." -ForegroundColor Yellow
        } elseif ($statusCode -eq 403) {
            Write-Host "Authentication error. Your API key may be invalid or restricted." -ForegroundColor Yellow
        }
    }
}
