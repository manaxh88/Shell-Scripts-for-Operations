#!/bin/bash

# =====================================================================
# 脚本名称：log_rotate_clean.sh
# 功能描述：日志轮转 + 过期日志清理 + 磁盘空间监控
# 使用方式：./log_rotate_clean.sh 或 crontab 定时执行
# 示例 crontab：0 3 * * * /path/to/log_rotate_clean.sh >> /var/log/log_clean.log 2>&1
# =====================================================================

# ----------------------- 配置区（可根据实际修改） -----------------------
LOG_DIR="/var/log/myapp"               # 要清理的日志目录（可改为 /var/log/nginx 等）
LOG_PATTERN="*.log *.log.*"            # 日志文件匹配模式（支持通配符）
RETENTION_DAYS=30                      # 保留天数，超过此天数的日志将被删除
MAX_DISK_USAGE=85                      # 磁盘使用率告警阈值（%）
COMPRESS=yes                           # 是否压缩旧日志（yes/no）
SCRIPT_LOG="/var/log/log_rotate_clean.log"  # 本脚本执行日志

# ----------------------- 函数定义 -----------------------

# 日志记录函数
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$1] $2" >> "$SCRIPT_LOG"
    # 可选：echo 到 stdout 方便调试
    # echo "$(date '+%Y-%m-%d %H:%M:%S') [$1] $2"
}

# 检查磁盘使用率并告警
check_disk_usage() {
    local disk_usage
    disk_usage=$(df -h / | tail -1 | awk '{print $5}' | tr -d '%')
    
    log "INFO" "当前根分区使用率：${disk_usage}%"
    
    if [ "$disk_usage" -gt "$MAX_DISK_USAGE" ]; then
        log "WARNING" "磁盘使用率超过阈值 ${MAX_DISK_USAGE}%！当前：${disk_usage}%"
        curl -X POST "钉钉URL" -d '{"msgtype":"text","text":{"content":"磁盘告警：使用率 ${disk_usage}% !"}}'
    fi
}

# 日志轮转函数
rotate_logs() {
    local file="$1"
    local basename=$(basename "$file")
    
    # 如果当天已轮转过（存在 .1.gz），则跳过
    if [ -f "${file}.1.gz" ] || [ -f "${file}.1" ]; then
        log "INFO" "文件 $basename 已轮转，跳过"
        return
    fi
    
    # 轮转：当前日志 -> .1，旧的 .1 -> .2，以此类推（手动模拟 rotate）
    local i=10  # 最多保留 10 个历史版本，避免无限累积
    while [ $i -ge 1 ]; do
        local old="${file}.$i"
        local new="${file}.$((i+1))"
        if [ -f "$old" ]; then
            if [ "$COMPRESS" = "yes" ] && [[ ! "$old" =~ \.gz$ ]]; then
                mv "$old" "${old}.gz" 2>/dev/null || true
            else
                mv "$old" "$new" 2>/dev/null || true
            fi
        fi
        i=$((i-1))
    done
    
    # 当前日志重命名为 .1
    mv "$file" "${file}.1"
    
    # 如果需要压缩 .1
    if [ "$COMPRESS" = "yes" ]; then
        gzip -f "${file}.1" 2>/dev/null
    fi
    
    log "INFO" "完成轮转：$basename → ${basename}.1${COMPRESS:+.gz}"
}

# 清理过期日志函数
clean_old_logs() {
    local count=0
    # 查找超过 RETENTION_DAYS 天的日志文件（包括 .gz）
    find "$LOG_DIR" -type f \( -name "*.log" -o -name "*.log.*" -o -name "*.gz" \) -mtime +"$RETENTION_DAYS" | while read -r oldfile; do
        rm -f "$oldfile"
        log "INFO" "删除过期日志：$(basename "$oldfile")"
        count=$((count+1))
    done
    
    if [ $count -gt 0 ]; then
        log "INFO" "本次共删除 $count 个过期日志文件"
    else
        log "INFO" "无过期日志需要清理"
    fi
}

# ----------------------- 主逻辑 -----------------------
log "START" "===== 日志轮转与清理任务开始 ====="

# 1. 检查磁盘使用率
check_disk_usage

# 2. 轮转当前活跃日志（只处理未压缩的 .log 文件）
find "$LOG_DIR" -type f -name "*.log" ! -name "*.gz" | while read -r logfile; do
    rotate_logs "$logfile"
done

# 3. 清理过期日志
clean_old_logs

log "END" "===== 日志轮转与清理任务完成 ====="
echo "----------------------------------------" >> "$SCRIPT_LOG"

exit 0
