import urllib.request
import urllib.parse
import json
import time
import os
import sys

CLIENT_ID = "178c6fc778ccc68e1d6a"
DEVICE_CODE = "7d5feeae14d166f9bf3d888f1dc169c128a97341"
INTERVAL = 5

url = "https://github.com/login/oauth/access_token"
data = urllib.parse.urlencode({
    "client_id": CLIENT_ID,
    "device_code": DEVICE_CODE,
    "grant_type": "urn:ietf:params:oauth:grant-type:device_code"
}).encode("utf-8")

while True:
    req = urllib.request.Request(url, data=data, headers={"Accept": "application/json"})
    try:
        with urllib.request.urlopen(req) as response:
            res = json.loads(response.read().decode())
            if "access_token" in res:
                print("TOKEN_ACQUIRED")
                token = res["access_token"]
                
                # Push to github
                os.system(f"git remote set-url origin https://oauth2:{token}@github.com/HamzaSEBE/MafiaGame.git")
                ret = os.system("git push origin master:main")
                if ret == 0:
                    print("PUSH_SUCCESS")
                else:
                    print("PUSH_FAILED")
                sys.exit(0)
            elif res.get("error") == "authorization_pending":
                time.sleep(INTERVAL)
            elif res.get("error") == "slow_down":
                INTERVAL += 5
                time.sleep(INTERVAL)
            else:
                print("ERROR:", res)
                sys.exit(1)
    except Exception as e:
        print("EXCEPTION:", e)
        time.sleep(INTERVAL)
