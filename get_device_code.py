import urllib.request
import urllib.parse
import json

CLIENT_ID = "178c6fc778ccc68e1d6a"
url = "https://github.com/login/device/code"
data = urllib.parse.urlencode({
    "client_id": CLIENT_ID,
    "scope": "repo"
}).encode("utf-8")

req = urllib.request.Request(url, data=data, headers={"Accept": "application/json"})
with urllib.request.urlopen(req) as response:
    res = json.loads(response.read().decode())
    print("USER_CODE:", res.get("user_code"))
    print("DEVICE_CODE:", res.get("device_code"))
    print("VERIFICATION_URI:", res.get("verification_uri"))
    print("INTERVAL:", res.get("interval"))
