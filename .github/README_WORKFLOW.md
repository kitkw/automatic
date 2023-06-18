# 可复用脚本工作流配置说明

## 概述
这是一个可复用的工作流模板，用于自动运行各种脚本并管理 cookie 文件。为了安全起见，脚本和 cookie 文件存储在私库中。

## 工作流功能
1. 设置代理并验证连接
2. 从私库拉取指定脚本和 cookie 文件
3. 运行脚本处理账户
4. 将更新后的 cookie 文件提交回私库

## 环境变量配置

### 核心变量
- `SCRIPT_FILE`: 脚本文件名（如 `katabump.py`）

### 必需的环境变量
- `ACCESS_TOKEN`: GitHub Personal Access Token，用于访问私库
- `PRIVATE_REPO_OWNER`: 私库所有者的用户名
- `PRIVATE_REPO_NAME`: 私库的仓库名
- `PROXY_MDB`: MDB 代理设置脚本的下载链接
- `TG_USER_ID`: Telegram 用户 ID
- `TG_BOT_TOKEN`: Telegram 机器人 token

### 脚本特定的环境变量
- `KATABUMP_ACCOUNTS`: katabump 脚本的账户配置信息
- `HOST2PLAY_ACCOUNTS`: host2play 脚本的账户配置信息

## 私库结构要求
私库应该包含以下文件结构：
```
private-repo/
├── katabump.py          # katabump 脚本文件
├── host2play.py         # host2play 脚本文件
└── tmp/                 # cookie 文件目录
    ├── katabump_*.json  # katabump 相关 cookie 文件
    ├── host2play_*.json # host2play 相关 cookie 文件
    └── ...
```

## 工作流步骤说明

1. **Checkout public repo**: 检出当前公开仓库
2. **Setup proxy and verify connection**: 设置代理并验证连接
3. **Set up Python**: 设置 Python 环境
4. **Install requirements**: 安装依赖包
5. **Download script and cookies**: 从私库下载脚本和 cookie 文件
6. **Run python script**: 运行指定的脚本
7. **Upload updated cookies**: 将更新后的 cookie 上传回私库

## 代理设置说明

### PROXY_MDB
- MDB 代理设置脚本的下载链接
- 脚本应该设置 SOCKS5 代理到 `127.0.0.1:8081`
- 工作流会自动检测代理连接是否正常

### 代理检测
- 使用 `curl --socks5 127.0.0.1:8081 https://ifconfig.co/json` 检测代理
- 如果代理连接失败，工作流会自动退出
- 确保代理脚本正确设置代理服务

## 工作流独立性

### 多工作流并行执行
- 每个工作流都是完全独立的
- 可以同时运行多个工作流
- 互不干扰，故障隔离

### 示例配置
```yaml
# katabump 工作流
name: katabump
schedule: "0 */8 * * *"  # 每8小时执行
env:
  SCRIPT_FILE: katabump.py

# host2play 工作流  
name: host2play
schedule: "0 */3 * * *"  # 每3小时执行
env:
  SCRIPT_FILE: host2play.py
```

## 如何复用于其他脚本

### 方法1：创建新的工作流文件
1. 复制现有工作流文件（如 `katabump.yml`）
2. 重命名为新的脚本名（如 `myscript.yml`）
3. 修改以下内容：
   ```yaml
   name: myscript
   env:
     SCRIPT_FILE: myscript.py
   matrix:
     account: [MYSCRIPT_ACCOUNTS]
   ```

### 方法2：修改现有工作流
在现有工作流中修改：
```yaml
env:
  SCRIPT_FILE: your_script_name.py
```

## 文件匹配规则

### Cookie 文件命名
- 文件名必须包含脚本名（不区分大小写）
- 必须以 `.json` 结尾
- 示例：`katabump_account1.json`, `HOST2PLAY_user2.json`

### 匹配示例
- `katabump.*json` 会匹配：
  - ✅ `katabump1.json`
  - ✅ `KATABUMP2.json`
  - ✅ `katabump_account.json`
  - ❌ `otherfile.json`

## 注意事项
- 确保 `ACCESS_TOKEN` 有访问私库的权限
- `ACCESS_TOKEN` 需要 `repo` 权限来读写私库内容
- `PROXY_MDB` 应该指向有效的 MDB 代理设置脚本
- 代理脚本应该正确配置 SOCKS5 代理服务
- 私库中的 cookie 文件名必须包含脚本名并以 .json 结尾
- 工作流会自动处理文件复制和提交操作
- 脚本名不区分大小写，但建议保持一致性
- 每个工作流使用独立的环境变量，避免冲突 