#!/bin/bash

# 定義GitLab容器名稱
gitlabContainer="gitlab"

# 設定日誌文件路徑
logFile="./monitering_logs/gitlab_restore.log"

# 日誌記錄函數
log_message() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" >> $logFile
}

# 電子郵件通知管理員列表
adminEmails=("admin@gmail.com")
gmailWebhookPort = 5000

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
# 錯誤處理函數
handle_error() {
    local errorMessage="$1"
    log_message "$errorMessage"
    send_email_notification "[ERROR][$(date '+%Y-%m-%d %H:%M:%S')]" "$errorMessage"
    exit 1
}

# 恢復GitLab數據函數
restore_gitlab() {
    local backupTimestamp="$1"
    local backupFile=""

    # 停止需要的GitLab服務
    log_message "Stopping GitLab services (puma, sidekiq)..."
    docker exec -t $gitlabContainer gitlab-ctl stop puma
    docker exec -t $gitlabContainer gitlab-ctl stop sidekiq
    if [ $? -ne 0 ]; then
        handle_error "Failed to stop GitLab services."
    fi
    log_message "GitLab services (puma, sidekiq) stopped."

    # 恢復 gitlab-secrets.json
    secretsFile="./gitlab-backup/gitlab-secrets.json"
    if [ -f $secretsFile ]; then
        log_message "Restoring gitlab-secrets.json..."
        docker cp $secretsFile ${gitlabContainer}:/etc/gitlab/gitlab-secrets.json
        if [ $? -ne 0 ]; then
            handle_error "Failed to restore gitlab-secrets.json."
        fi
        log_message "gitlab-secrets.json restored."
    else
        handle_error "gitlab-secrets.json not found."
    fi

    # 找到指定時間戳的備份文件，如果沒有指定時間戳則使用最新的備份文件
    if [ -z "$backupTimestamp" ]; then
        backupFile=$(ls -t ./gitlab-backup/backups/*.tar | head -n 1)
        if [ -z "$backupFile" ]; then
            handle_error "No backup file found in ./gitlab-backup/backups/."
        fi
        # 提取備份文件名中的時間戳
        backupTimestamp=$(basename $backupFile | sed 's/_gitlab_backup.tar$//')
        log_message "Latest backup file: $backupFile"
    else
        backupFile="./gitlab-backup/backups/${backupTimestamp}_gitlab_backup.tar"
        if [ ! -f "$backupFile" ]; then
            handle_error "Backup file not found: ${backupFile}"
        fi
        log_message "Specified backup file: $backupFile"
    fi

    # 將備份文件複製到容器中
    log_message "Copying backup file to GitLab container..."
    docker cp $backupFile ${gitlabContainer}:/var/opt/gitlab/backups/
    if [ $? -ne 0 ]; then
        handle_error "Failed to copy backup file to GitLab container."
    fi
    log_message "Backup file copied to GitLab container."

    # 設置備份文件權限和所有權
    log_message "Setting permissions and ownership for backup file in GitLab container..."
    docker exec -t $gitlabContainer chown git:git /var/opt/gitlab/backups/$(basename $backupFile)
    docker exec -t $gitlabContainer chmod 600 /var/opt/gitlab/backups/$(basename $backupFile)
    if [ $? -ne 0 ]; then
        handle_error "Failed to set permissions and ownership for backup file in GitLab container."
    fi
    log_message "Permissions and ownership set for backup file in GitLab container."

    # 恢復GitLab備份
    log_message "Restoring GitLab backup..."
    docker exec -t $gitlabContainer gitlab-backup restore BACKUP=$backupTimestamp force=yes
    if [ $? -ne 0 ]; then
        handle_error "Failed to restore GitLab backup."
    fi
    log_message "GitLab backup restored."

    # 執行reconfigure和啟動需要的GitLab服務
    log_message "Reconfiguring GitLab services..."
    docker exec -t $gitlabContainer gitlab-ctl reconfigure
    if [ $? -ne 0 ]; then
        handle_error "Failed to reconfigure GitLab services."
    fi
    log_message "GitLab services reconfigured."

    log_message "Starting GitLab services (puma, sidekiq)..."
    docker exec -t $gitlabContainer gitlab-ctl restart
    if [ $? -ne 0 ]; then
        handle_error "Failed to start GitLab services."
    fi
    log_message "GitLab services started."

    log_message "GitLab restoration process completed successfully."
    send_email_notification "[Notify][$(date '+%Y-%m-%d %H:%M:%S')]" "GitLab restoration process completed successfully."
}

# 開始GitLab數據恢復過程
log_message "Starting GitLab data restoration process..."
restore_gitlab "$1"
