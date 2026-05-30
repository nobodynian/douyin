#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <dlfcn.h>

static NSMutableDictionary *mysteryUserInfoCache;
static IMP originalHandleMessage;

@interface MysteryUserHelper : NSObject
@end

@implementation MysteryUserHelper

+ (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *copyAction = [UIAlertAction actionWithTitle:@"复制链接" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            UIPasteboard.generalPasteboard.string = message;
        }];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:copyAction];
        [alert addAction:okAction];
        
        UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
        [rootVC presentViewController:alert animated:YES completion:nil];
    });
}

@end

static void hooked_handleMessage(id self, SEL _cmd, id message) {
    @try {
        if (message) {
            NSString *messageType = [NSString stringWithFormat:@"%@", [message valueForKey:@"type"]];
            if ([messageType containsString:@"mystery"] || [messageType containsString:@"user"]) {
                id userInfo = [message valueForKey:@"user"];
                if (userInfo) {
                    NSString *userId = [userInfo valueForKey:@"uid"];
                    NSString *secUserId = [userInfo valueForKey:@"sec_uid"];
                    NSString *nickname = [userInfo valueForKey:@"nickname"];
                    
                    if (userId && secUserId) {
                        if (!mysteryUserInfoCache) {
                            mysteryUserInfoCache = [NSMutableDictionary dictionary];
                        }
                        
                        if (!mysteryUserInfoCache[userId]) {
                            mysteryUserInfoCache[userId] = @{@"sec_uid": secUserId, @"nickname": nickname ?: @"神秘人"};
                            
                            NSString *homePageURL = [NSString stringWithFormat:@"https://www.douyin.com/user/%@", secUserId];
                            NSLog(@"[DouyinMysteryUser] 发现神秘人: %@ (UID: %@)", nickname ?: @"未知", userId);
                            NSLog(@"[DouyinMysteryUser] 主页地址: %@", homePageURL);
                            
                            [MysteryUserHelper showAlertWithTitle:@"发现神秘人" message:homePageURL];
                        }
                    }
                }
            }
        }
    } @catch (NSException *exception) {
        NSLog(@"[DouyinMysteryUser] 错误: %@", exception.reason);
    }
    
    ((void (*)(id, SEL, id))originalHandleMessage)(self, _cmd, message);
}

__attribute__((constructor))
static void initialize() {
    NSLog(@"[DouyinMysteryUser] dylib已加载");
    
    mysteryUserInfoCache = [NSMutableDictionary dictionary];
    
    @autoreleasepool {
        Class roomManagerClass = NSClassFromString(@"AwemeRoomMessageManager");
        if (roomManagerClass) {
            SEL handleMessageSel = NSSelectorFromString(@"handleMessage:");
            Method originalMethod = class_getInstanceMethod(roomManagerClass, handleMessageSel);
            
            if (originalMethod) {
                originalHandleMessage = method_getImplementation(originalMethod);
                method_setImplementation(originalMethod, (IMP)hooked_handleMessage);
                NSLog(@"[DouyinMysteryUser] Hook成功: AwemeRoomMessageManager handleMessage:");
            } else {
                NSLog(@"[DouyinMysteryUser] 未找到 handleMessage: 方法");
            }
        } else {
            NSLog(@"[DouyinMysteryUser] 未找到 AwemeRoomMessageManager 类");
        }
    }
}
