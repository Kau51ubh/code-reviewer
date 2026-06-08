# Security Breach: Hardcoded passwords and tokens
import requests

def fetch_external_data():
    api_token = "ghp_xxXYYzz12345SecretToken" # SECURITY ALERT
    db_password = "admin_password_123" # SECURITY ALERT
    
    response = requests.get("https://api.external.com/data", headers={"Authorization": f"Bearer {api_token}"})
    return response.json()