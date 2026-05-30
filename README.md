# 抖音直播间神秘人主页地址获取插件

本项目提供三种方案来获取抖音iOS直播间神秘人的主页地址：

## 方案一：dylib 插件 (推荐，巨魔注入)

### 环境要求
- **Windows/Linux/macOS**（均可编译）
- iOS 设备（支持 TrollStore 或类似注入工具）

### Windows 用户编译方法（推荐）

#### 方法一：GitHub Actions 在线编译（最简单）
1. 将此项目推送到你的 GitHub 仓库
2. 进入仓库的 Actions 页面
3. 点击 "Build dylib" 工作流 → "Run workflow" 手动触发编译
4. 下载编译好的 artifact

#### 方法二：Docker 编译
1. 安装 Docker Desktop
2. 进入 Dylib 目录，运行：
```cmd
build_docker.bat
```

### macOS 用户编译方法
1. 进入 Dylib 目录
2. 执行编译脚本：
```bash
cd Dylib
./build_arm64.sh
```
3. 编译成功后会生成 `libDouyinMysteryUser.dylib`

### 注入步骤
1. 将编译好的 dylib 传输到 iOS 设备
2. 使用 TrollStore 或相关注入工具将 dylib 注入到抖音应用
3. 重启抖音应用

详细说明请参考 [Dylib/README.md](file:///workspace/DouyinMysteryUser/Dylib/README.md)

## 方案二：Theos 越狱插件 (Tweak)

### 环境要求
- 已越狱的 iOS 设备
- Theos 开发环境
- Xcode 命令行工具

### 安装步骤
1. 安装 Theos: https://theos.dev/docs/installation
2. 克隆或下载此项目
3. 进入 Tweak 目录
4. 编译并安装:
```bash
cd Tweak
make clean
make package
make install
```

### 使用方法
1. 重启抖音应用或 SpringBoard
2. 进入任意直播间
3. 当有神秘人进入或发言时，会弹出提示框显示其主页地址
4. 点击"复制链接"可直接复制到剪贴板

## 方案三：Frida 动态分析脚本

### 环境要求
- iOS 设备（可越狱或不越狱，非越狱需要使用 FridaGadget）
- Frida 工具: `pip install frida-tools`

### 使用步骤
1. 将抖音应用注入 FridaGadget（非越狱设备）或确保设备已越狱并运行 frida-server
2. 启动抖音应用
3. 运行脚本:
```bash
cd Frida
frida -U -f com.ss.iphone.aweme -l douyin_mystery_user.js --no-pause
```

### RPC 接口
脚本提供了两个 RPC 接口供其他程序调用:
- `getMysteryUsers()` - 获取已发现的所有神秘人信息
- `exportList()` - 在控制台导出神秘人列表

## 注意事项
1. 本工具仅供学习和研究使用
2. 请遵守抖音的用户协议和相关法律法规
3. 插件会 hook 抖音的消息处理类，可能会被检测到
4. 建议使用测试账号进行测试

## 原理说明
插件通过 hook 抖音直播间的消息管理器 (`AwemeRoomMessageManager`)，拦截处理进入直播间的用户消息，从中提取神秘人的 `sec_uid`，然后拼接成主页地址格式 `https://www.douyin.com/user/{sec_uid}`
