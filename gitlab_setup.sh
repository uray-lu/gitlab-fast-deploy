logFile="./gitlab_setup.log"

# 日誌記錄函數
log_message() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" >> $logFile
}

# Create necessary directories
mkdir -p config data logs gitlab-backup monitoring_logs
log_message "Successfully created necessary directories."

# Create gmail webhook
cd ./gmail_webhook
docker build -t gmail-api-service .
docker run -d -p 5000:80 --name gitlab-gmail-api-service gmail-api-service
cd ..

# GitLab container start up
docker compose up -d
log_message "GitLab container started."
