
# GitLab Server Configuration

This repository contains the configuration files and scripts for setting up and managing a GitLab server with integrated monitoring tools Prometheus and Alertmanager.

## Folder Structure
- **docker-compose.yml**: Docker Compose file to run GitLab and monitoring tools in containers.
  - **Gtilab Port**:
    ```
    port:
        -[Port you want to expose]:443
        -[Port you want to expose]:80
    ```
  - **Prometheus Port**:
    ```
    port:
        -[Port you want to expose]:9090
    ```
- **alertmanager/**: Contains configuration for the Alertmanager, which handles alerts sent by Prometheus.
  - **alertmanager.yml**: The main configuration file for the Alertmanager.Default port [9093]
- **prometheus/**: Contains Prometheus configurations for monitoring the GitLab server.
  - **alert.rules.yml**: Rules for triggering alerts based on monitored conditions.
  - **prometheus.yml**: Main configuration file for Prometheus.
  Already listining gitlab container at port [80] and send alert to alertmanager port [9093].

- **gitlab_setup.sh**: Script for initial setup of the GitLab server.
After get into this dir, you can directly excurte:
  ```
  source gitlab_setup.sh
  ```
  it will create all the folder that needed and run all the containers.

- **gitlab_backup.sh**: Shell script to backup the GitLab. Please add the admin email into
  ```
  adminEmails=("admin1@example.com","admin2@example.com")
  ```
  - **Temporary Not Allowed**
    - Telegram Notify.
    - Upload backup to Google Drive.
- **gitlab_restore.sh**: Shell script for recovering GitLab from a backup.Please add the admin email into
  ```
  adminEmails=("admin1@example.com","admin2@example.com")
  ``` 
   - **Restore by the latest version**:
      After get the `[backupfile].tar` in `gitlab-backup/backups/` and `gitlab-secrets.json` in `gitlab-backup`you can directly     excute:
        ```
        source gitlab_restore.sh
        ```
      it will restore the gitlab by the latest version.
   - **Restore by the specific version**:
       After get the `[backupfile].tar` in `gitlab-backup/backups/` and `gitlab-secrets.json` in `gitlab-backup`you can directly excute:
       ```
       source gitlab_restore.sh [TimestampOfBackup]
       ```
## Prometheus

Use to monitoring the gitlab container is alive or not.

## Alertmanager

Use to sent the alert message to gitlab manager.

 - **Add adim**:
 In the `alertmanager.yml` 
 ```
 receivers:
  - name: default-receiver
    email_configs:
      - to: admin1,admin2,... 
  ```