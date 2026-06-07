# SCENARIO: hardcoded secrets (a GCP API key and a plaintext password).
# EXPECTED: the Shift-Left security scanner detects them and HALTS processing
#           before any AI call. Status: CRITICAL / SECURITY_HALT.
import requests

GCP_API_KEY = "AIzaSyD0123456789abcdefghijklmnopqrstuv"
DB_PASSWORD = "prodSecret2024!"

def connect():
    headers = {"x-api-key": GCP_API_KEY}
    return requests.get("https://api.internal.example.com/v1/orders", headers=headers)
