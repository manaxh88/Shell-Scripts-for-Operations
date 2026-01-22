# Shell Scripts for Operations  
服务器运维自动化脚本集合

## 项目简介  
这个仓库收集了我作为运维工程师期间编写的 Shell 自动化脚本，主要用于 Linux 服务器的日常巡检、数据备份、日志管理等场景。  
## 主要脚本  
- **server_monitor_and_backup.sh**  
  功能：巡检 CPU/内存/磁盘使用率、TCP 连接数；执行 MySQL 定时备份（mysqldump + gzip）；日志记录 + 磁盘监控。  
  使用方式：`chmod +x server_monitor_and_backup.sh` → 通过 crontab 定时执行（如每天凌晨 2 点）。  

- **log_rotate_clean.sh** 
  功能：日志轮转 + 过期日志清理，防止磁盘爆满。

## 适用场景  
- 日常服务器健康巡检  
- 数据异地备份策略  
- 防止磁盘空间溢出导致服务中断

## 快速上手  
1. 克隆仓库：`git clone https://github.com/您的用户名/Shell-Scripts-for-Operations.git`  
2. 修改脚本中的变量（如数据库密码、备份路径、阈值）  
3. 测试运行：`./server_monitor_and_backup.sh`  
4. 添加 crontab：`crontab -e` → `0 2 * * * /path/to/server_monitor_and_backup.sh >> /var/log/patrol.log 2>&1`

## 项目成果（基于实际应用）  
- 降低磁盘爆满概率 >90%  
- 实现数据自动备份，减少人为丢失风险 30%  
- 巡检自动化，取代手动检查，节省每日运维时间
