##################### Telegram 通知功能 - 暫時關閉 #####################
# Telegram Bot Token 和 Chat ID
# telegramBotToken=""
# telegramChatIds=(" ")

# 發送Telegram通知函數
# send_telegram_notification() {
#     local message="$1"
#     local chat_id="$2"
#     curl -s -X POST "https://api.telegram.org/bot$telegramBotToken/sendMessage" -d chat_id="$chat_id" -d text="$message"
# }
##################### Telegram 通知功能 - 暫時關閉 #####################


# 定義GitLab容器名稱
gitlabContainer="gitlab"

# 設定日誌文件路徑
logFile="./monitering_logs/gitlab_backup.log"

# 電子郵件通知管理員列表
adminEmails=("admin@gmail.com")
gmailWebhookPort='5000'

# 日誌記錄函數
log_message() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" >> $logFile
}

# 錯誤處理函數
handle_error() {
    local errorMessage="$1"
    log_message "$errorMessage"
    ##################### Telegram 通知功能 - 暫時關閉 #####################
    # for chatId in "${telegramChatIds[@]}"; do
    #     send_telegram_notification "[ERROR][$dateTime] $errorMessage" "$chatId"
    # done
    ##################### Telegram 通知功能 - 暫時關閉 #####################
    send_email_notification "[ Notify]Backup Error" "$errorMessage"
}


# 發送電子郵件通知函數
send_email_notification() {
    local subject="$1"
    local message_text="$2"
    for email in "${adminEmails[@]}"; do
        curl -X POST http://localhost:$gmailWebhookPort/send_email \
             -H "Content-Type: application/json" \
             -d "{
                   \"to\": \"$email\",
                   \"subject\": \"$subject\",
                   \"message_text\": \"$message_text\"
                 }"
    done
}

# 開始備份過程
log_message "Starting GitLab backup process."

# 複製gitlab-secrets.json到備份目錄
backupDir="./gitlab-backup"
secretCpCommand="docker cp ${gitlabContainer}:/etc/gitlab/gitlab-secrets.json $backupDir/gitlab-secrets.json"
log_message "Copying gitlab-secrets.json: $secretCpCommand"
eval $secretCpCommand
if [ $? -eq 0 ]; then
    log_message "gitlab-secrets.json copied."
    ##################### Telegram 通知功能 - 暫時關閉 #####################
    # dateTime="$(date '+%Y-%m-%d %H:%M:%S')"
    # for chatId in "${telegramChatIds[@]}"; do
    #     send_telegram_notification "[SUCCESS][$dateTime] Successfully backup gitlab-secrets.json." "$chatId"
    # done
    ##################### Telegram 通知功能 - 暫時關閉 #####################
else
    handle_error "Failed to backup gitlab-secrets.json. Please check and manually execute: $secretCpCommand"
fi

# 執行GitLab備份
dockerbackupCommand="docker exec -t $gitlabContainer gitlab-backup create"
log_message "Running backup command: $dockerbackupCommand"
eval $dockerbackupCommand
gitlabBackupCPcommand="docker cp ${gitlabContainer}:/var/opt/gitlab/backups $backupDir"
log_message "Copying GitLab backup file: $gitlabBackupCPcommand"
eval $gitlabBackupCPcommand
if [ $? -eq 0 ]; then
    log_message "GitLab backup completed."
    ##################### Telegram 通知功能 - 暫時關閉 #####################
    # dateTime="$(date '+%Y-%m-%d %H:%M:%S')"
    # for chatId in "${telegramChatIds[@]}"; do
    #     send_telegram_notification "[SUCCESS][$dateTime] Successfully backup GitLab backup file." "$chatId"
    # done
    ##################### Telegram 通知功能 - 暫時關閉 #####################
else
    handle_error "Failed to backup GitLab. Please check and manually execute: $dockerbackupCommand"
fi

dateTime="$(date '+%Y-%m-%d %H:%M:%S')"
send_email_notification "[Notify]Backup Successed" "[$dateTime]Successfully backup GitLab. Please check the backup file in $backupDir"



# 刪除本地超過 7 天的備份文件
find $backupDir -type f -mtime +7 -exec rm {} \;
log_message "Old backup files older than 7 days deleted."



