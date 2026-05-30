# 抖音直播间神秘人主页地址获取 dylib 插件

本 dylib 插件可以直接用巨魔（TrollStore）或类似工具注入到抖音应用中。

## 编译方法

### 方案一：GitHub Actions 在线编译（推荐，无需本地环境）

1. 将此项目推送到你的 GitHub 仓库
2. 进入仓库的 Actions 页面
3. 点击 "Build dylib" 工作流
4. 点击 "Run workflow" 按钮，手动触发编译
5. 等待编译完成，在 Artifacts 中下载编译好的 `libDouyinMysteryUser.dylib`

### 方案二：Windows 使用 Docker 编译

1. 确保已安装 Docker Desktop
2. 进入 Dylib 目录：
```cmd
cd Dylib
```
3. 执行 Windows 编译脚本：
```cmd
build_docker.bat
```

或者使用 WSL2 或 Git Bash：
```bash
chmod +x build_docker.sh
./build_docker.sh
```

### 方案三：macOS 本地编译

#### 环境要求
- macOS 系统
- Xcode 命令行工具
- ldid（可选，用于签名）

#### 编译步骤

1. 进入 Dylib 目录：
```bash
cd Dylib
```

2. 执行编译脚本：
```bash
# 编译 arm64 版本（推荐）
./build_arm64.sh

# 或编译通用版本（arm64 + arm64e）
./build.sh
```

编译成功后会生成 `libDouyinMysteryUser.dylib` 文件。

## 注入方法

### 方法一：使用巨魔 (TrollStore)
1. 确保你的设备已安装 TrollStore
2. 将编译好的 `libDouyinMysteryUser.dylib` 传输到设备
3. 使用 TrollStore 或相关的注入工具（如 Crane、TrollStore 插件等）将 dylib 注入到抖音应用中
4. 重启抖音应用

### 方法二：使用 Dobby/Substitute 或类似框架
1. 将 dylib 放置到 `/usr/lib/` 或应用的 Frameworks 目录
2. 修改应用的二进制文件，添加对 dylib 的加载引用
3. 重新签名并安装应用

### 方法三：使用动态注入工具
1. 使用 frida 或类似工具在运行时注入
2. 示例：
```bash
frida -U -f com.ss.iphone.aweme --load-library libDouyinMysteryUser.dylib
```

## 使用说明

1. 成功注入后，打开抖音应用
2. 进入任意直播间
3. 当有神秘人进入或发言时，会弹出提示框显示其主页地址
4. 点击"复制链接"可直接复制到剪贴板

## 文件说明

- **[DouyinMysteryUser.m](file:///workspace/DouyinMysteryUser/Dylib/DouyinMysteryUser.m)** - 源代码
- **[build.sh](file:///workspace/DouyinMysteryUser/Dylib/build.sh)** - macOS 通用版本编译脚本
- **[build_arm64.sh](file:///workspace/DouyinMysteryUser/Dylib/build_arm64.sh)** - macOS arm64 版本编译脚本
- **[build_docker.bat](file:///workspace/DouyinMysteryUser/Dylib/build_docker.bat)** - Windows Docker 编译脚本
- **[build_docker.sh](file:///workspace/DouyinMysteryUser/Dylib/build_docker.sh)** - Linux/Mac Docker 编译脚本
- **[Dockerfile](file:///workspace/DouyinMysteryUser/Dylib/Dockerfile)** - Docker 构建配置
- **[.github/workflows/build.yml](file:///workspace/DouyinMysteryUser/.github/workflows/build.yml)** - GitHub Actions 在线编译配置

## 注意事项

1. 本工具仅供学习和研究使用
2. 请遵守抖音的用户协议和相关法律法规
3. 注入 dylib 可能会被应用检测到，请谨慎使用
4. 建议使用测试账号进行测试
