# 系统保护机制配置指南

## 1. 配置 Swap 交换空间（推荐）

Swap 可以在内存不足时提供缓冲，避免 OOM Killer 杀死进程。

### 检查当前 Swap
```bash
free -h
swapon --show
```

### 创建 Swap 文件（2GB，可根据需要调整）
```bash
# 创建 2GB swap 文件
sudo fallocate -l 2G /swapfile
# 或者使用 dd（如果 fallocate 不支持）
# sudo dd if=/dev/zero of=/swapfile bs=1024 count=2097152

# 设置权限
sudo chmod 600 /swapfile

# 格式化为 swap
sudo mkswap /swapfile

# 启用 swap
sudo swapon /swapfile

# 永久启用（重启后仍然有效）
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

### 优化 Swap 使用策略
```bash
# 编辑 /etc/sysctl.conf
sudo vim /etc/sysctl.conf

# 添加以下配置（降低 swap 使用倾向，优先使用内存）
vm.swappiness=10        # 0-100，值越小越倾向于使用内存（推荐 10）
vm.vfs_cache_pressure=50  # 降低 vfs 缓存压力
```

### 应用配置
```bash
sudo sysctl -p
```

## 2. 配置 OOM Killer 策略

### 查看当前 OOM Killer 配置
```bash
cat /proc/sys/vm/overcommit_memory
cat /proc/sys/vm/overcommit_ratio
```

### 优化 OOM Killer（推荐配置）
```bash
# 编辑 /etc/sysctl.conf
sudo vim /etc/sysctl.conf

# 添加以下配置
vm.overcommit_memory=1        # 允许内存过度分配（Redis 需要）
vm.overcommit_ratio=50         # 过度分配比例
vm.panic_on_oom=0             # OOM 时不 panic（保持系统运行）
vm.oom_kill_allocating_task=0 # 不杀死正在分配内存的任务
```

### 应用配置
```bash
sudo sysctl -p
```

## 3. 配置系统资源监控

### 安装监控工具
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y htop iotop nethogs

# CentOS/RHEL
sudo yum install -y htop iotop nethogs
```

### 设置资源告警脚本
创建 `/usr/local/bin/check-resources.sh`:
```bash
#!/bin/bash
# 资源监控脚本

MEM_USAGE=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100}')
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)

if [ "$MEM_USAGE" -gt 90 ]; then
    echo "警告: 内存使用率 ${MEM_USAGE}%"
    # 可以发送告警通知
fi

if [ "$CPU_USAGE" -gt 90 ]; then
    echo "警告: CPU 使用率 ${CPU_USAGE}%"
    # 可以发送告警通知
fi
```

### 设置定时任务
```bash
# 编辑 crontab
crontab -e

# 每 5 分钟检查一次
*/5 * * * * /usr/local/bin/check-resources.sh >> /var/log/resource-check.log 2>&1
```

## 4. Docker 守护进程配置

### 配置 Docker daemon 资源限制
编辑 `/etc/docker/daemon.json`:
```json
{
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 65536,
      "Soft": 65536
    }
  },
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
```

### 重启 Docker
```bash
sudo systemctl restart docker
```

## 5. 系统服务优先级配置

### 设置系统服务优先级
```bash
# 降低非关键服务的优先级
sudo systemctl set-property docker.service CPUQuota=80%
sudo systemctl set-property docker.service MemoryLimit=3G
```

## 6. 应急处理脚本

创建 `/usr/local/bin/docker-emergency.sh`:
```bash
#!/bin/bash
# Docker 应急处理脚本

# 1. 检查容器状态
echo "=== 容器状态 ==="
docker ps -a

# 2. 检查资源使用
echo "=== 资源使用 ==="
docker stats --no-stream

# 3. 如果内存不足，重启非关键容器
if [ $(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100}') -gt 95 ]; then
    echo "内存严重不足，重启非关键服务..."
    docker restart jeepay-activemq
fi

# 4. 清理未使用的资源
echo "=== 清理资源 ==="
docker system prune -f
```

## 7. 监控和告警

### 使用 Docker 内置监控
```bash
# 实时监控
docker stats

# 查看容器日志
docker-compose logs -f [服务名]

# 查看容器资源使用历史
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"
```

## 8. 最佳实践建议

1. **定期清理**：
   ```bash
   # 清理未使用的镜像、容器、网络
   docker system prune -a --volumes
   ```

2. **日志管理**：
   - 限制日志大小（已在 daemon.json 配置）
   - 定期清理旧日志

3. **备份重要数据**：
   - MySQL 数据卷
   - Redis 数据卷
   - 应用日志

4. **监控磁盘空间**：
   ```bash
   df -h
   du -sh /var/lib/docker/*
   ```

## 总结

通过以上配置，系统将具备：
- ✅ Swap 缓冲保护
- ✅ OOM Killer 智能策略
- ✅ Docker 资源限制
- ✅ 自动重启机制
- ✅ 健康检查
- ✅ 资源监控和告警

这些机制可以最大程度避免系统崩溃，即使在高负载情况下也能保持稳定运行。
