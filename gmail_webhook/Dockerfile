# 使用官方的 Python 基礎映像
FROM python:3.9-slim

# 設置工作目錄
WORKDIR /app

# 複製當前目錄下的所有文件到工作目錄
COPY . /app

# 安裝所需的 Python 包
RUN pip install --no-cache-dir Flask google-auth google-api-python-client gunicorn prometheus_flask_exporter

# 暴露應用運行的端口
EXPOSE 80

# 使用 Gunicorn 啟動 Flask 應用
CMD ["gunicorn", "--bind", "0.0.0.0:80", "mail_service:app"]
