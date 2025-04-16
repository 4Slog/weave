# Get the API key from the .env file
$envContent = Get-Content -Path ".env" -Raw
$apiKey = $envContent -replace ".*GEMINI_API_KEY=([^\r\n]*).*", '$1'
$apiKey = $apiKey.Trim()

Write-Host "Using API key: $apiKey"

# Try different API endpoints
$endpoints = @(
    "https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey",
    "https://generativelanguage.googleapis.com/v1/models?key=$apiKey",
    "https://generativelanguage.googleapis.com/v1beta3/models?key=$apiKey"
)

foreach ($url in $endpoints) {
    Write-Host "`nTesting endpoint: $url"
    try {
        $response = Invoke-RestMethod -Uri $url -Method Get
        Write-Host "Success! API key is working with this endpoint." -ForegroundColor Green
        Write-Host "Response: $($response | ConvertTo-Json -Depth 1)"
        exit 0
    } catch {
        Write-Host "Error with this endpoint:" -ForegroundColor Red
        Write-Host $_.Exception.Message
        if ($_.Exception.Response) {
            $statusCode = $_.Exception.Response.StatusCode.value__
            Write-Host "Status code: $statusCode"
        }
    }
}

Write-Host "`nAll endpoints failed. Please check your API key and try again." -ForegroundColor Red
