# Replace this with your actual API key from the .env file
$apiKey = "AIzaSyBr9-dGTyS1Q_SAGgd2SuSVt5JoSly7Tlc"

# API endpoint for Gemini Pro
$url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$apiKey"

# Create a simple request body
$body = @{
  contents = @(
    @{
      parts = @(
        @{
          text = "Write a short story about a weaver learning to code."
        }
      )
    }
  )
} | ConvertTo-Json -Depth 10

# Make the API request
Write-Host "Testing Gemini API with your key..."
try {
    $response = Invoke-RestMethod -Uri $url -Method Post -Body $body -ContentType "application/json"
    Write-Host "Success! API key is working." -ForegroundColor Green
    Write-Host "Response preview:"
    $responseText = $response.candidates[0].content.parts[0].text
    Write-Host ($responseText.Substring(0, [Math]::Min(200, $responseText.Length)) + "...")
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
