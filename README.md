# 若依框架 Docker 部署指南

## 目录结构

```
E:\docker\
├── docker-compose.yml     # 容器编排（4个服务）
├── dockerfile              # 后端镜像定义
├── app.jar                 # 后端jar包
├── sql\                    # MySQL初始化脚本
│   ├── ry_20260417.sql     # 主库表结构和数据
│   └── quartz.sql         # 定时任务表
└── nginx\
    ├── Dockerfile          # 前端镜像定义
    ├── nginx.conf          # Nginx配置（静态托管+反向代理）
    └── html\               # 前端dist文件
```

## 快速部署

目标电脑只需两步：

```
1. 安装 Docker Desktop
2. 在本目录执行：docker-compose up -d
```

首次启动约需1-2分钟（MySQL初始化较慢），之后访问 http://localhost 即可。

默认账号：admin / admin123

## 容器架构

```
浏览器 :80
  │
  ▼
Nginx（前端容器 ruoyi-ui）
  │  /prod-api/* ──转发──→ 若依后端:8080
  │  其他请求 ────返回──→ Vue静态页面
  │
  ▼
若依后端（ruoyi-server）
  │  连接 Redis（ruoyi-redis:6379）
  │  连接 MySQL（ruoyi-mysql:3306）
  │
  ▼
Redis + MySQL
```

| 容器 | 端口映射 | 说明 |
|------|---------|------|
| ruoyi-ui | 80→80 | Nginx前端，入口 |
| ruoyi-server | 8081→8080 | Spring Boot后端 |
| ruoyi-mysql | 3307→3306 | MySQL 5.7 |
| ruoyi-redis | 6379→6379 | Redis 6.2 |

## 常用命令

```bash
# 启动所有容器
docker-compose up -d

# 停止所有容器
docker-compose down

# 停止并清除数据（重新初始化数据库时用）
docker-compose down -v

# 查看后端日志
docker logs -f ruoyi-server

# 查看所有容器状态
docker ps
```

## 关键配置说明

### 1. 容器间通信

容器之间用 docker-compose.yml 中的 **service名** 互相访问，不是IP：

- application.yml 中 Redis地址：`redis`（不是172.29.x.x）
- application-druid.yml 中 MySQL地址：`mysql`（不是localhost）

### 2. 数据库初始化

sql/ 目录下的脚本只在 **MySQL容器首次创建** 时自动执行。如果容器已存在但数据库为空，需要清除数据卷重建：

```bash
docker-compose down -v
docker-compose up -d
```


## 故障排查

| 现象 | 可能原因 | 解决方式 |
|------|---------|---------|
| 若依启动失败，日志报Connection refused | MySQL还没就绪 | 等1分钟后重启后端：`docker restart ruoyi-server` |
| 日志报 Table 'xxx' doesn't exist | 数据库未初始化 | `docker-compose down -v && docker-compose up -d` |
| 日志报 Could not resolve placeholder | application.yml缺少属性 | 检查jar包里的配置是否完整 |
| 前端页面空白，接口500 | Nginx转发失败 | 检查nginx.conf中proxy_pass地址是否为service名 |
| 日志报Redis连接失败 | Redis地址或密码不对 | 确认application.yml中host为redis，密码为aaa@123123 |

