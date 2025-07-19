# CodeReview CLI 部署指南

## 📋 概述

本指南详细介绍了 CodeReview CLI 在不同环境下的部署方案，包括开发环境、生产环境、CI/CD 集成等场景的最佳实践。

## 🎯 部署架构

### 部署模式对比

| 部署模式 | 适用场景 | 优势 | 劣势 |
|----------|----------|------|------|
| **全局安装** | 个人开发环境 | 一次安装，全局可用 | 版本管理复杂 |
| **项目安装** | 团队协作项目 | 版本隔离，精确控制 | 每个项目需单独安装 |
| **容器化部署** | CI/CD环境 | 环境一致性，易扩展 | 资源开销较大 |
| **云端部署** | 企业级应用 | 高可用，集中管理 | 网络依赖，成本较高 |

## 🚀 快速部署

### 1. 全局安装部署

**适用场景**: 个人开发环境，多项目使用

```bash
# 一键安装
curl -fsSL https://raw.githubusercontent.com/im47cn/codereview-cli/main/install.sh | bash

# 验证安装
codereview-cli --version
codereview-cli status
```

**配置步骤**:
```bash
# 1. 配置全局环境变量
echo 'export GITLAB_PERSONAL_ACCESS_TOKEN="your-token"' >> ~/.bashrc
echo 'export AI_SERVICE="gemini"' >> ~/.bashrc
source ~/.bashrc

# 2. 配置AI服务
gemini config

# 3. 为现有项目启用
cd your-project
codereview-cli setup
```

### 2. 项目级部署

**适用场景**: 团队协作，版本控制严格的项目

```bash
# 1. 克隆项目
git clone https://github.com/im47cn/codereview-cli.git
cd codereview-cli

# 2. 项目级安装
./install.sh
# 选择 "项目安装" 模式

# 3. 配置环境变量
cp .env.example .env
# 编辑 .env 文件设置必要的环境变量

# 4. 安装Git hooks
./install-hooks.sh
```

## 🐳 容器化部署

### Docker 部署

**Dockerfile 示例**:
```dockerfile
FROM node:18-alpine

# 安装系统依赖
RUN apk add --no-cache git bash curl

# 安装AI服务CLI
RUN npm install -g @google/gemini-cli

# 创建工作目录
WORKDIR /app

# 复制项目文件
COPY . .

# 设置权限
RUN chmod +x install.sh install-hooks.sh
RUN chmod +x lib/*.sh
RUN chmod +x githooks/*

# 安装CodeReview CLI
RUN ./install.sh --non-interactive --mode=project

# 设置入口点
ENTRYPOINT ["./docker-entrypoint.sh"]
```

**docker-compose.yml 示例**:
```yaml
version: '3.8'

services:
  codereview-cli:
    build: .
    environment:
      - GITLAB_PERSONAL_ACCESS_TOKEN=${GITLAB_TOKEN}
      - GITLAB_API_URL=${GITLAB_API_URL}
      - AI_SERVICE=gemini
      - GEMINI_API_KEY=${GEMINI_API_KEY}
    volumes:
      - ./projects:/workspace
      - ./review_logs:/app/review_logs
    working_dir: /workspace
```

**部署命令**:
```bash
# 构建镜像
docker build -t codereview-cli:latest .

# 运行容器
docker run -d \
  --name codereview-cli \
  -e GITLAB_PERSONAL_ACCESS_TOKEN="your-token" \
  -e GEMINI_API_KEY="your-key" \
  -v $(pwd):/workspace \
  codereview-cli:latest
```

## ☁️ 云端部署

### AWS 部署

**使用 AWS Lambda**:
```yaml
# serverless.yml
service: codereview-cli

provider:
  name: aws
  runtime: nodejs18.x
  region: us-east-1
  environment:
    GITLAB_PERSONAL_ACCESS_TOKEN: ${env:GITLAB_TOKEN}
    GEMINI_API_KEY: ${env:GEMINI_API_KEY}

functions:
  codeReview:
    handler: handler.codeReview
    events:
      - http:
          path: review
          method: post
    timeout: 300
```

**部署命令**:
```bash
# 安装Serverless Framework
npm install -g serverless

# 部署到AWS
serverless deploy
```

### Azure 部署

**使用 Azure Container Instances**:
```bash
# 创建资源组
az group create --name codereview-rg --location eastus

# 部署容器
az container create \
  --resource-group codereview-rg \
  --name codereview-cli \
  --image codereview-cli:latest \
  --environment-variables \
    GITLAB_PERSONAL_ACCESS_TOKEN="your-token" \
    GEMINI_API_KEY="your-key"
```

### Google Cloud 部署

**使用 Cloud Run**:
```bash
# 构建并推送镜像
gcloud builds submit --tag gcr.io/PROJECT-ID/codereview-cli

# 部署到Cloud Run
gcloud run deploy codereview-cli \
  --image gcr.io/PROJECT-ID/codereview-cli \
  --platform managed \
  --region us-central1 \
  --set-env-vars GITLAB_PERSONAL_ACCESS_TOKEN="your-token",GEMINI_API_KEY="your-key"
```

## 🔄 CI/CD 集成

### GitHub Actions

**.github/workflows/codereview.yml**:
```yaml
name: Code Review

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  code-review:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup CodeReview CLI
      run: |
        curl -fsSL https://raw.githubusercontent.com/im47cn/codereview-cli/main/install.sh | bash
        
    - name: Configure AI Service
      env:
        GEMINI_API_KEY: ${{ secrets.GEMINI_API_KEY }}
        GITLAB_PERSONAL_ACCESS_TOKEN: ${{ secrets.GITLAB_TOKEN }}
      run: |
        echo "AI_SERVICE=gemini" > .ai-config
        echo "GEMINI_API_KEY=$GEMINI_API_KEY" >> .env
        echo "GITLAB_PERSONAL_ACCESS_TOKEN=$GITLAB_PERSONAL_ACCESS_TOKEN" >> .env
        
    - name: Run Code Review
      run: |
        ./githooks/post-commit
```

### GitLab CI

**.gitlab-ci.yml**:
```yaml
stages:
  - review

code_review:
  stage: review
  image: node:18-alpine
  before_script:
    - apk add --no-cache git bash curl
    - curl -fsSL https://raw.githubusercontent.com/im47cn/codereview-cli/main/install.sh | bash
  script:
    - echo "AI_SERVICE=gemini" > .ai-config
    - ./githooks/post-commit
  variables:
    GITLAB_PERSONAL_ACCESS_TOKEN: $GITLAB_TOKEN
    GEMINI_API_KEY: $GEMINI_KEY
  artifacts:
    paths:
      - review_logs/
    expire_in: 1 week
```

### Jenkins Pipeline

**Jenkinsfile**:
```groovy
pipeline {
    agent any
    
    environment {
        GITLAB_PERSONAL_ACCESS_TOKEN = credentials('gitlab-token')
        GEMINI_API_KEY = credentials('gemini-api-key')
    }
    
    stages {
        stage('Setup') {
            steps {
                sh 'curl -fsSL https://raw.githubusercontent.com/im47cn/codereview-cli/main/install.sh | bash'
            }
        }
        
        stage('Configure') {
            steps {
                sh '''
                    echo "AI_SERVICE=gemini" > .ai-config
                    echo "GEMINI_API_KEY=${GEMINI_API_KEY}" > .env
                    echo "GITLAB_PERSONAL_ACCESS_TOKEN=${GITLAB_PERSONAL_ACCESS_TOKEN}" >> .env
                '''
            }
        }
        
        stage('Code Review') {
            steps {
                sh './githooks/post-commit'
            }
            post {
                always {
                    archiveArtifacts artifacts: 'review_logs/**', fingerprint: true
                }
            }
        }
    }
}
```

## 🔧 环境配置

### 生产环境配置

**环境变量清单**:
```bash
# 必需配置
export GITLAB_PERSONAL_ACCESS_TOKEN="glpat-xxxxxxxxxxxxxxxxxxxx"
export GITLAB_API_URL="https://gitlab.com/api/v4"

# AI服务配置
export AI_SERVICE="gemini"
export GEMINI_API_KEY="your-gemini-key"
export AI_TIMEOUT="60"
export AI_MAX_RETRIES="3"

# 可选配置
export REVIEW_LOGS_DIR="/var/log/codereview"
export DEBUG="false"
export LOG_LEVEL="info"
```

**系统要求**:
```bash
# 最低系统要求
- OS: Linux/macOS/Windows(WSL)
- Memory: 512MB
- Disk: 100MB
- Network: 稳定的互联网连接

# 推荐系统配置
- OS: Ubuntu 20.04+ / CentOS 8+
- Memory: 2GB
- Disk: 1GB
- CPU: 2 cores
```

### 安全配置

**API密钥管理**:
```bash
# 使用环境变量存储敏感信息
export GEMINI_API_KEY="$(cat /etc/secrets/gemini-key)"
export GITLAB_PERSONAL_ACCESS_TOKEN="$(cat /etc/secrets/gitlab-token)"

# 设置文件权限
chmod 600 /etc/secrets/*
chown root:root /etc/secrets/*
```

**网络安全**:
```bash
# 配置防火墙规则
ufw allow out 443/tcp  # HTTPS
ufw allow out 80/tcp   # HTTP

# 配置代理（如需要）
export HTTP_PROXY="http://proxy.company.com:8080"
export HTTPS_PROXY="http://proxy.company.com:8080"
```

## 📊 监控和日志

### 日志配置

**日志级别**:
```bash
export LOG_LEVEL="info"  # debug, info, warn, error
export LOG_FILE="/var/log/codereview/app.log"
```

**日志轮转**:
```bash
# /etc/logrotate.d/codereview
/var/log/codereview/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 644 codereview codereview
}
```

### 监控指标

**关键指标**:
- API调用成功率
- 平均响应时间
- 错误率
- 资源使用情况

**监控脚本示例**:
```bash
#!/bin/bash
# monitor.sh

# 检查服务状态
check_service_health() {
    if codereview-cli status > /dev/null 2>&1; then
        echo "Service: OK"
    else
        echo "Service: ERROR"
        # 发送告警
        curl -X POST "https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK" \
             -H 'Content-type: application/json' \
             --data '{"text":"CodeReview CLI service is down!"}'
    fi
}

# 检查API连通性
check_api_connectivity() {
    if timeout 10 gemini --version > /dev/null 2>&1; then
        echo "API: OK"
    else
        echo "API: ERROR"
    fi
}

check_service_health
check_api_connectivity
```

## 🔄 升级和维护

### 版本升级

**自动升级**:
```bash
# 设置定时任务
echo "0 2 * * 0 /usr/local/bin/codereview-cli update" | crontab -
```

**手动升级**:
```bash
# 备份当前配置
cp -r ~/.codereview-cli ~/.codereview-cli.backup

# 升级到最新版本
curl -fsSL https://raw.githubusercontent.com/im47cn/codereview-cli/main/install.sh | bash

# 验证升级
codereview-cli --version
```

### 故障恢复

**配置恢复**:
```bash
# 恢复配置
cp -r ~/.codereview-cli.backup ~/.codereview-cli

# 重新安装hooks
codereview-cli setup
```

**数据备份**:
```bash
# 备份审查日志
tar -czf review_logs_backup_$(date +%Y%m%d).tar.gz review_logs/

# 备份配置文件
tar -czf config_backup_$(date +%Y%m%d).tar.gz ~/.codereview-cli/
```

## 📞 技术支持

### 部署支持

如需部署支持，请：
1. 查看 [故障排除文档](../README.md#故障排除)
2. 提交 [GitHub Issue](https://github.com/im47cn/codereview-cli/issues)
3. 联系技术支持团队

### 企业级支持

提供以下企业级服务：
- 定制化部署方案
- 24/7 技术支持
- 性能优化咨询
- 安全审计服务

---

**部署成功后，您的团队将拥有一个强大的AI驱动代码审查系统！** 🚀✨
