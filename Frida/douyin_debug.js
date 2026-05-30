console.log("[*] ========== 抖音神秘人调试版 ==========");

let mysteryUserCache = new Map();

// 1. 先枚举所有相关的类
function scanClasses() {
    console.log("\n[*] 正在扫描相关类...");
    
    const allClasses = ObjC.classes;
    const keywords = ["Room", "Message", "Aweme"];
    
    for (let className in allClasses) {
        for (let kw of keywords) {
            if (className.includes(kw)) {
                console.log(`  [+] 发现类: ${className}`);
                break;
            }
        }
    }
}

// 2. Hook 所有可能的消息处理方法
function hookAllMessageHandlers() {
    console.log("\n[*] 正在hook消息处理类...");
    
    // 尝试多种可能的类名
    const possibleClasses = [
        "AwemeRoomMessageManager",
        "AwemeLiveRoomManager", 
        "AwemeRoomMessage",
        "RoomMessageManager",
        "LiveRoomManager"
    ];
    
    for (let className of possibleClasses) {
        try {
            const cls = ObjC.classes[className];
            if (!cls) continue;
            
            console.log(`\n[+] 找到类: ${className}`);
            
            // 枚举所有方法
            const methods = ObjC.classes[className].$ownMethods;
            for (let method of methods) {
                if (method.includes("handle") || method.includes("message")) {
                    console.log(`    [+] 方法: ${method}`);
                }
            }
            
            // Hook 可能的方法
            if (cls["- handleMessage:"]) {
                Interceptor.attach(cls["- handleMessage:"].implementation, {
                    onEnter: function(args) {
                        try {
                            const msg = ObjC.Object(args[2]);
                            console.log(`\n[!] ========== 收到消息 ==========`);
                            console.log(`[!] 原始对象: ${msg}`);
                            console.log(`[!] 描述: ${msg.description()}`);
                            processMessage(msg);
                        } catch (e) {
                            console.log(`[-] 解析消息错误: ${e}`);
                        }
                    }
                });
                console.log(`    [+] Hooked handleMessage:`);
            }
            
            if (cls["- onMessage:"]) {
                Interceptor.attach(cls["- onMessage:"].implementation, {
                    onEnter: function(args) {
                        try {
                            const msg = ObjC.Object(args[2]);
                            console.log(`\n[!] ========== 收到onMessage ==========`);
                            console.log(`[!] ${msg}`);
                        } catch (e) {}
                    }
                });
                console.log(`    [+] Hooked onMessage:`);
            }
            
        } catch (e) {
            console.log(`[-] 处理 ${className} 失败: ${e}`);
        }
    }
}

function processMessage(msg) {
    try {
        // 尝试多种方式获取信息
        console.log(`\n[*] 尝试解析消息...`);
        
        // 尝试获取所有属性
        try {
            console.log(`[*] message类型: ${typeof msg}`);
            const keys = msg.$ownIvars;
            console.log(`[*] Ivars: ${keys}`);
        } catch(e) {}
        
        // 遍历可能的key
        const possibleKeys = ["type", "user", "uid", "sec_uid", "secUid", "nickname", "content"];
        
        for (let key of possibleKeys) {
            try {
                const val = msg[key];
                if (val) {
                    console.log(`[+] ${key}: ${val}`);
                }
            } catch(e) {}
        }
        
        // 尝试 valueForKey
        try {
            const type = msg.valueForKey_("type");
            const user = msg.valueForKey_("user");
            if (type) console.log(`[+] type (KVC): ${type}`);
            if (user) console.log(`[+] user (KVC): ${user}`);
            
            if (user) {
                const uid = user.valueForKey_("uid");
                const secUid = user.valueForKey_("sec_uid");
                const nickname = user.valueForKey_("nickname");
                
                console.log(`[+] uid: ${uid}`);
                console.log(`[+] sec_uid: ${secUid}`);
                console.log(`[+] nickname: ${nickname}`);
                
                if (uid && secUid && !mysteryUserCache.has(uid.toString())) {
                    mysteryUserCache.set(uid.toString(), { secUid, nickname });
                    const url = `https://www.douyin.com/user/${secUid}`;
                    console.log(`\n[!] !!!!!!!!!! 发现用户主页 !!!!!!!!!!`);
                    console.log(`[!] ${nickname || '未知'}: ${url}`);
                    console.log(`[!] !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n`);
                    
                    showNotification(nickname || "用户", url);
                }
            }
        } catch(e) {
            console.log(`[-] KVC错误: ${e}`);
        }
        
    } catch (e) {
        console.log(`[-] 处理消息错误: ${e}`);
    }
}

function showNotification(title, url) {
    try {
        const UIAlertController = ObjC.classes.UIAlertController;
        const UIAlertAction = ObjC.classes.UIAlertAction;
        const UIApplication = ObjC.classes.UIApplication;
        
        const alert = UIAlertController.alertControllerWithTitle_message_preferredStyle_(
            `发现: ${title}`, url, 0
        );
        
        const copy = UIAlertAction.actionWithTitle_style_handler_(
            "复制", 0, new ObjC.Block({
                retType: 'void', argTypes: ['object'],
                implementation: function() {
                    ObjC.classes.UIPasteboard.generalPasteboard().setString_(url);
                    console.log("[+] 已复制");
                }
            })
        );
        
        const ok = UIAlertAction.actionWithTitle_style_handler_(
            "确定", 1, new ObjC.Block({
                retType: 'void', argTypes: ['object'],
                implementation: function() {}
            })
        );
        
        alert.addAction_(copy);
        alert.addAction_(ok);
        
        const app = UIApplication.sharedApplication();
        const window = app.keyWindow();
        const rootVC = window.rootViewController();
        
        if (rootVC) {
            rootVC.presentViewController_animated_completion_(alert, true, NULL);
        }
    } catch(e) {
        console.log(`[-] 显示通知失败: ${e}`);
    }
}

if (ObjC.available) {
    console.log("[*] Objective-C 可用");
    
    setTimeout(() => {
        console.log("[*] 开始扫描...");
        scanClasses();
        hookAllMessageHandlers();
        console.log("\n[*] ========== 准备就绪，等待消息 ==========");
    }, 1000);
} else {
    console.log("[-] Objective-C 不可用");
}

rpc.exports = {
    getCache: function() {
        let res = [];
        mysteryUserCache.forEach((v, k) => res.push({ uid: k, ...v }));
        return res;
    }
};
