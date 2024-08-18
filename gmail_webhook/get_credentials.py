import threading

from flask import Flask, redirect, request
from google_auth_oauthlib.flow import InstalledAppFlow

# 初始化 Flask 應用
app = Flask(__name__)

# 在這裡存儲授權碼
auth_code = None


@app.route("/")
def auth_return():
    global auth_code
    auth_code = request.args.get("code")
    return "Authorization code received. You can close this window."


def run_server():
    app.run(port=8080)


def get_credentials():
    global auth_code
    SCOPES = ["https://www.googleapis.com/auth/gmail.send"]
    redirect_uri = "http://localhost:8080"

    flow = InstalledAppFlow.from_client_secrets_file(
        "client_secret.json",  # 確保這是您的 JSON 檔案的正確路徑
        scopes=SCOPES,
        redirect_uri=redirect_uri,
    )

    # 在新執行緒中啟動本地服務器
    threading.Thread(target=run_server).start()

    # 手動處理授權 URL
    auth_url, _ = flow.authorization_url(prompt="consent")

    print(f"Please go to this URL and authorize access: {auth_url}")

    # 等待授權碼
    while auth_code is None:
        pass

    flow.fetch_token(code=auth_code)

    creds = flow.credentials

    print("Access Token:", creds.token)
    print("Refresh Token:", creds.refresh_token)

    return creds

# 執行後會拿到一個網址，開啟該網址進行認證，就可以拿到Access Token和Refresh Token
# 之後就可以輸入到mail_service.py，就可以正常啟用了 
if __name__ == "__main__":
    get_credentials()
