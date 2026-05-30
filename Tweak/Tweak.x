#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static NSMutableDictionary *mysteryUserInfoCache;

@interface MysteryUserInfo : NSObject
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, copy) NSString *secUserId;
@property (nonatomic, copy) NSString *nickname;
@end

@implementation MysteryUserInfo
@end

%hook NSObject

- (void)dealloc {
    %orig;
}

%end

%hook AwemeRoomMessageManager

- (void)handleMessage:(id)message {
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
                        mysteryUserInfoCache[userId] = @{@"sec_uid": secUserId, @"nickname": nickname ?: @"神秘人"};
                        
                        NSString *homePageURL = [NSString stringWithFormat:@"https://www.douyin.com/user/%@", secUserId];
                        NSLog(@"[DouyinMysteryUser] 发现神秘人: %@ (UID: %@)", nickname ?: @"未知", userId);
                        NSLog(@"[DouyinMysteryUser] 主页地址: %@", homePageURL);
                        
                        [self showAlertWithTitle:@"发现神秘人" message:homePageURL];
                    }
                }
            }
        }
    } @catch (NSException *exception) {
        NSLog(@"[DouyinMysteryUser] 错误: %@", exception.reason);
    }
    %orig;
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
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

%end

%ctor {
    NSLog(@"[DouyinMysteryUser] 插件已加载");
    mysteryUserInfoCache = [NSMutableDictionary dictionary];
}
