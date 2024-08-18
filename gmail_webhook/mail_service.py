import base64
from email.mime.text import MIMEText

from flask import Flask, jsonify, request
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build
from prometheus_flask_exporter import PrometheusMetrics

app = Flask(__name__)
metrics = PrometheusMetrics(app)
# 用您的 Access Token 和 Refresh Token 創建憑證對象
creds = Credentials(
    token="",
    refresh_token="",
    token_uri="https://oauth2.googleapis.com/token",
    client_id="",
    client_secret="",
)

# 構建 Gmail API 客戶端
service = build("gmail", "v1", credentials=creds)


def create_message(to, subject, message_text, sender_name="ALERT", sender_email="example@mail.com"):
    message = MIMEText(message_text)
    message["to"] = to
    message["subject"] = subject
    message["from"] = f"{sender_name} <{sender_email}>"
    raw = base64.urlsafe_b64encode(message.as_bytes())
    raw = raw.decode()
    return {"raw": raw}


def send_message(service, user_id, message):
    try:
        message = (
            service.users().messages().send(userId=user_id, body=message).execute()
        )
        return message
    except Exception as error:
        return str(error)


@app.route("/send_email", methods=["POST"])
def send_email():
    data = request.json
    to = data["to"]
    subject = data["subject"]
    message_text = data["message_text"]
    message = create_message(to, subject, message_text)
    result = send_message(service, "me", message)
    return jsonify(result)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
