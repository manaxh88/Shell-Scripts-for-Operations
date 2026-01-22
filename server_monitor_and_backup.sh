#!/bin/bash

# 脚本描述：服务器关键指标巡检和MySQL定时备份
# 日期：2024-02-22

# 配置变量
CPU_THRESHOLD=80  # CPU使用率阈值
MEM_THRESHOLD=80  # 内存使用率阈值
DISK_THRESHOLD=90 # 磁盘使用率阈值
DB_USER="****"    # MySQL用户
DB_PASS="******" # MySQL密码
DB_NAME="mydatabase" # 数据库名
BACKUP_DIR="/backup" # 备份目录
LOG_FILE="/var/log/server_monitor.log"

# 函数：检查CPU使用率
check_cpu() {
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
    if [ $(echo "$CPU_USAGE > $CPU_THRESHOLD" | bc) -eq 1 ]; then
        echo "$(date): CPU usage high: $CPU_USAGE%" >> $LOG_FILE
    fi
}

# 函数：检查内存使用率
check_mem() {
    MEM_USAGE=$(free | grep Mem | awk '{print $3/$2 * 100.0}')
    if [ $(echo "$MEM_USAGE > $MEM_THRESHOLD" | bc) -eq 1 ]; then
        echo "$(date): Memory usage high: $MEM_USAGE%" >> $LOG_FILE
    fi
}

# 函数：检查磁盘使用率
check_disk() {
    DISK_USAGE=$(df / | grep / | awk '{ print $5}' | sed 's/%//g')
    if [ $DISK_USAGE -gt $DISK_THRESHOLD ]; then
        echo "$(date): Disk usage high: $DISK_USAGE%" >> $LOG_FILE
    fi
}

# 函数：检查连接数（示例：netstat检查TCP连接）
check_connections() {
    CONN_COUNT=$(netstat -an | grep ESTABLISHED | wc -l)
    echo "$(date): Current connections: $CONN_COUNT" >> $LOG_FILE
}

# 函数：MySQL备份
backup_mysql() {
    mkdir -p $BACKUP_DIR
    BACKUP_FILE="$BACKUP_DIR/$DB_NAME-$(date +%Y%m%d).sql.gz"
    mysqldump -u$DB_USER -p$DB_PASS $DB_NAME | gzip > $BACKUP_FILE
    # 异地拷贝（示例：scp到远程服务器）
    # scp $BACKUP_FILE user@remote:/path/
    echo "$(date): Backup completed: $BACKUP_FILE" >> $LOG_FILE
}

# 主逻辑
echo "$(date): Starting patrol" >> $LOG_FILE
check_cpu
check_mem
check_disk
check_connections
backup_mysql
echo "$(date): Patrol finished" >> $LOG_FILE
