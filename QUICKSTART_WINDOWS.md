# Windows 用户快速开始指南

## 最简单的方法：GitHub Actions 在线编译

### 步骤 1：准备 GitHub 仓库

1. 如果还没有 GitHub 账号，先注册一个
2. 点击右上角的 "New repository" 创建新仓库
3. 仓库名称可以叫 `douyin-mystery-user` 或其他你喜欢的名字
4. 选择 "Public" 或 "Private" 都可以
5. 点击 "Create repository"

### 步骤 2：上传代码

有两种方式：

#### 方式 A：使用 GitHub 网页界面上传（推荐新手）

1. 在新创建的仓库页面，点击 "uploading an existing file" 链接
2. 将你本地 `DouyinMysteryUser/` 目录下的所有文件拖拽上传
3. 提交更改

#### 方式 B：使用 Git 命令

```bash
# 进入项目目录
cd /workspace/DouyinMysteryUser

# 初始化 git
git init
git add .
git commit -m "Initial commit"

# 推送到你的 GitHub 仓库（替换为你的用户名和仓库名）
git remote add origin https://github.com/你的用户名/你的仓库名.git
git branch -M main
git push -u origin main
```

### 步骤 3：触发编译

1. 进入你的 GitHub 仓库页面
2. 点击顶部的 "Actions" 标签
3. 左侧选择 "Build dylib" 工作流
4. 点击右侧的 "Run workflow" 按钮
5. 保持默认设置，点击绿色的 "Run workflow"
6. 等待约 1-2 分钟，编译完成

### 步骤 4：下载编译好的文件

1. 在 Actions 页面，点击刚刚完成的工作流（有绿色 ✓ 的）
2. 向下滚动到 "Artifacts" 部分
3. 点击 "libDouyinMysteryUser" 下载
4. 解压下载的文件，得到 `libDouyinMysteryUser.dylib`

### 步骤 5：注入到抖音

1. 将 `libDouyinMysteryUser.dylib` 传输到 iOS 设备
2. 使用 TrollStore 或相关注入工具注入到抖音应用
3. 重启抖音即可使用！

---

## 备选方法：Docker 编译

如果你有 Docker Desktop 的话：

1. 安装 [Docker Desktop](https://www.docker.com/products/docker-desktop/)
2. 打开命令提示符或 PowerShell
3. 进入 Dylib 目录：
   ```cmd
   cd C:\path\to\DouyinMysteryUser\Dylib
   ```
4. 运行：
   ```cmd
   build_docker.bat
   ```
5. 等待编译完成
