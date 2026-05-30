console.log("[*] 抖音神秘人主页地址获取插件已加载");

let mysteryUserCache = new Map();

function interceptRoomMessages() {
    try {
        const AwemeRoomMessageManager = ObjC.classes.AwemeRoomMessageManager;
        if (AwemeRoomMessageManager) {
            console.log("[+] 找到 AwemeRoomMessageManager 类");
            
            const handleMessage = AwemeRoomMessageManager['- handleMessage:'];
            if (handleMessage) {
                Interceptor.attach(handleMessage.implementation, {
                    onEnter: function(args) {
                        try {
                            const message = ObjC.Object(args[2]);
                            processMessage(message);
                        } catch (e) {
                            console.log("[-] 处理消息错误:", e);
                        }
                    }
                });
                console.log("[+] 已 hook handleMessage: 方法");
            }
        }
    } catch (e) {
        console.log("[-] hook 房间消息管理器失败:", e);
    }
}

function processMessage(message) {
    try {
        if (!message) return;
        
        const messageType = message.type ? message.type.toString() : "";
        
        if (messageType.includes("mystery") || messageType.includes("user")) {
            const userInfo = message.user;
            if (userInfo) {
                const userId = userInfo.uid ? userInfo.uid.toString() : "";
                const secUserId = userInfo.sec_uid ? userInfo.sec_uid.toString() : "";
                const nickname = userInfo.nickname ? userInfo.nickname.toString() : "神秘人";
                
                if (userId && secUserId && !mysteryUserCache.has(userId)) {
                    mysteryUserCache.set(userId, { secUid: secUserId, nickname: nickname });
                    
                    const homePageURL = `https://www.douyin.com/user/${secUserId}`;
                    
                    console.log("\n[!] ========== 发现神秘人 ==========");
                    console.log(`[!] 昵称: ${nickname}`);
                    console.log(`[!] UID: ${userId}`);
                    console.log(`[!] 主页地址: ${homePageURL}`);
                    console.log("[!] =================================\n");
                    
                    showNotification(nickname, homePageURL);
                }
            }
        }
    } catch (e) {
        console.log("[-] 解析消息错误:", e);
    }
}

function showNotification(title, url) {
    try {
        const UIAlertController = ObjC.classes.UIAlertController;
        const UIAlertAction = ObjC.classes.UIAlertAction;
        const UIApplication = ObjC.classes.UIApplication;
        
        const alert = UIAlertController.alertControllerWithTitle_message_preferredStyle_(
            `发现神秘人: ${title}`,
            url,
            0 
        );
        
        const copyAction = UIAlertAction.actionWithTitle_style_handler_(
            "复制链接",
            0,
            new ObjC.Block({
                retType: 'void',
                argTypes: ['object'],
                implementation: function() {
                    const UIPasteboard = ObjC.classes.UIPasteboard;
                    const pasteboard = UIPasteboard.generalPasteboard();
                    pasteboard.setString_(url);
                    console.log("[+] 链接已复制到剪贴板");
                }
            })
        );
        
        const okAction = UIAlertAction.actionWithTitle_style_handler_(
            "确定",
            1,
            new ObjC.Block({
                retType: 'void',
                argTypes: ['object'],
                implementation: function() {}
            })
        );
        
        alert.addAction_(copyAction);
        alert.addAction_(okAction);
        
        const app = UIApplication.sharedApplication();
        const window = app.keyWindow();
        const rootVC = window.rootViewController();
        
        if (rootVC) {
            rootVC.presentViewController_animated_completion_(alert, true, NULL);
        }
    } catch (e) {
        console.log("[-] 显示通知失败:", e);
    }
}

function interceptNetworkRequests() {
    try {
        const NSURLSession = ObjC.classes.NSURLSession;
        const NSURL = ObjC.classes.NSURL;
        
        Interceptor.attach(ObjC.classes.NSURLSession['- dataTaskWithRequest:completionHandler:'].implementation, {
            onEnter: function(args) {
                try {
                    const request = ObjC.Object(args[2]);
                    const url = request.URL().absoluteString().toString();
                    
                    if (url.includes("webcast") || url.includes("room") || url.includes("user")) {
                        console.log("[*] 请求:", url);
                    }
                } catch (e) {
                }
            }
        });
    } catch (e) {
    }
}

function exportMysteryUsers() {
    console.log("\n[*] ========== 已发现的神秘人列表 ==========");
    mysteryUserCache.forEach((info, uid) => {
        console.log(`[*] ${info.nickname} (UID: ${uid})`);
        console.log(`    主页: https://www.douyin.com/user/${info.secUid}`);
    });
    console.log("[*] ========================================\n");
}

if (ObjC.available) {
    setTimeout(() => {
        interceptRoomMessages();
        interceptNetworkRequests();
        console.log("[*] 插件初始化完成，等待神秘人出现...\n");
    }, 1000);
    
    rpc.exports = {
        getMysteryUsers: function() {
            let result = [];
            mysteryUserCache.forEach((info, uid) => {
                result.push({
                    uid: uid,
                    secUid: info.secUid,
                    nickname: info.nickname,
                    homePage: `https://www.douyin.com/user/${info.secUid}`
                });
            });
            return result;
        },
        exportList: function() {
            exportMysteryUsers();
            return "导出完成";
        }
    };
} else {
    console.log("[-] Objective-C runtime not available");
}
