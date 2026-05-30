#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static IMP originalHandleMessage;
static UIWindow *floatingWindow = nil;
static UIButton *floatingButton = nil;
static UIViewController *listViewController = nil;
static BOOL isListVisible = NO;
static NSMutableArray *discoveredUsers = nil;

@interface MysteryUser : NSObject
@property (nonatomic, copy) NSString *uid;
@property (nonatomic, copy) NSString *secUid;
@property (nonatomic, copy) NSString *nickname;
@end

@implementation MysteryUser
@end

@interface MysteryUserListVC : UIViewController <UITableViewDelegate, UITableViewDataSource>
@end

@implementation MysteryUserListVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.95];
    self.view.layer.cornerRadius = 20;
    self.view.layer.masksToBounds = YES;
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, 280, 40)];
    titleLabel.text = @"发现的神秘人";
    titleLabel.font = [UIFont boldSystemFontOfSize:22];
    titleLabel.textColor = [UIColor whiteColor];
    [self.view addSubview:titleLabel];
    
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    closeBtn.frame = CGRectMake(300, 20, 40, 40);
    [closeBtn setTitle:@"✕" forState:UIControlStateNormal];
    closeBtn.titleLabel.font = [UIFont systemFontOfSize:28];
    [closeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [closeBtn addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:closeBtn];
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(10, 70, 320, 470)];
    tableView.backgroundColor = [UIColor clearColor];
    tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    tableView.separatorColor = [[UIColor grayColor] colorWithAlphaComponent:0.3];
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.rowHeight = 70;
    [self.view addSubview:tableView];
    
    objc_setAssociatedObject(self, "tableView", tableView, OBJC_ASSOCIATION_RETAIN);
}

- (void)close {
    [self dismissViewControllerAnimated:YES completion:nil];
    isListVisible = NO;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return discoveredUsers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellId = @"MysteryUserCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellId];
        cell.backgroundColor = [UIColor clearColor];
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.detailTextLabel.textColor = [UIColor lightGrayColor];
    }
    
    MysteryUser *user = [discoveredUsers objectAtIndex:indexPath.row];
    cell.textLabel.text = user.nickname ?: @"神秘人";
    cell.textLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightMedium];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"UID: %@", user.uid];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    MysteryUser *user = [discoveredUsers objectAtIndex:indexPath.row];
    NSString *url = [NSString stringWithFormat:@"https://www.douyin.com/user/%@", user.secUid];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:user.nickname message:url preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"复制链接" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UIPasteboard.generalPasteboard.string = url;
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"打开" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url] options:@{} completionHandler:nil];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

@end

@interface MysteryUserHelper : NSObject
@end

@implementation MysteryUserHelper

+ (void)setupFloatingWindow {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (floatingWindow) return;
        
        floatingWindow = [[UIWindow alloc] initWithFrame:CGRectMake(20, 200, 60, 60)];
        floatingWindow.windowLevel = UIWindowLevelAlert + 1000;
        floatingWindow.backgroundColor = [UIColor colorWithRed:0.0 green:0.48 blue:1.0 alpha:0.9];
        floatingWindow.layer.cornerRadius = 30;
        floatingWindow.layer.shadowColor = [UIColor blackColor].CGColor;
        floatingWindow.layer.shadowOpacity = 0.3;
        floatingWindow.layer.shadowOffset = CGSizeMake(0, 4);
        floatingWindow.layer.shadowRadius = 8;
        
        floatingButton = [UIButton buttonWithType:UIButtonTypeCustom];
        floatingButton.frame = floatingWindow.bounds;
        [floatingButton setTitle:@"👤" forState:UIControlStateNormal];
        floatingButton.titleLabel.font = [UIFont systemFontOfSize:28];
        [floatingButton addTarget:self action:@selector(toggleList) forControlEvents:UIControlEventTouchUpInside];
        
        [floatingWindow addSubview:floatingButton];
        [floatingWindow makeKeyAndVisible];
        
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [floatingButton addGestureRecognizer:pan];
        
        NSLog(@"[DouyinMysteryUser] 浮动按钮已创建");
    });
}

+ (void)handlePan:(UIPanGestureRecognizer *)gesture {
    UIView *view = gesture.view;
    UIWindow *window = view.window;
    if (!window) return;
    
    CGPoint translation = [gesture translationInView:window];
    CGPoint center = view.center;
    center.x += translation.x;
    center.y += translation.y;
    
    CGFloat margin = 40;
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    center.x = MAX(margin, MIN(center.x, screenSize.width - margin));
    center.y = MAX(margin, MIN(center.y, screenSize.height - margin));
    
    view.center = center;
    [gesture setTranslation:CGPointMake(0, 0) inView:window];
}

+ (void)toggleList {
    if (isListVisible) {
        [listViewController dismissViewControllerAnimated:YES completion:^{
            isListVisible = NO;
        }];
    } else {
        if (!listViewController) {
            listViewController = [[MysteryUserListVC alloc] init];
        }
        
        listViewController.modalPresentationStyle = UIModalPresentationOverFullScreen;
        listViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        listViewController.view.frame = CGRectMake(20, 80, 340, 550);
        
        // 获取当前的 key window
        UIWindow *keyWindow = nil;
        for (UIWindow *window in [UIApplication sharedApplication].windows) {
            if (window.isKeyWindow) {
                keyWindow = window;
                break;
            }
        }
        if (!keyWindow) {
            keyWindow = [UIApplication sharedApplication].windows.firstObject;
        }
        
        [keyWindow.rootViewController presentViewController:listViewController animated:YES completion:^{
            isListVisible = YES;
            UITableView *tableView = objc_getAssociatedObject(listViewController, "tableView");
            [tableView reloadData];
        }];
    }
}

+ (void)addUser:(MysteryUser *)user {
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL exists = NO;
        for (MysteryUser *u in discoveredUsers) {
            if ([u.uid isEqualToString:user.uid]) {
                exists = YES;
                break;
            }
        }
        
        if (!exists) {
            if (!discoveredUsers) discoveredUsers = [NSMutableArray array];
            [discoveredUsers insertObject:user atIndex:0];
            
            NSString *title = discoveredUsers.count > 0 ?
                [NSString stringWithFormat:@"👤%lu", (unsigned long)discoveredUsers.count] : @"👤";
            [floatingButton setTitle:title forState:UIControlStateNormal];
            
            if (isListVisible) {
                UITableView *tableView = objc_getAssociatedObject(listViewController, "tableView");
                [tableView reloadData];
            }
        }
    });
}

@end

static void hooked_handleMessage(id self, SEL _cmd, id message) {
    @try {
        if (message) {
            id userInfo = nil;
            NSArray *possibleUserKeys = @[@"user", @"sender", @"fromUser", @"userInfo"];
            for (NSString *key in possibleUserKeys) {
                @try {
                    userInfo = [message valueForKey:key];
                    if (userInfo) break;
                } @catch (NSException *e) {}
            }
            
            if (userInfo) {
                NSString *userId = nil;
                NSArray *uidKeys = @[@"uid", @"userId", @"id", @"user_id"];
                for (NSString *key in uidKeys) {
                    @try { userId = [userInfo valueForKey:key]; if (userId) break; } @catch (NSException *e) {}
                }
                
                NSString *secUserId = nil;
                NSArray *secUidKeys = @[@"sec_uid", @"secUid", @"sec_user_id", @"secUserId"];
                for (NSString *key in secUidKeys) {
                    @try { secUserId = [userInfo valueForKey:key]; if (secUserId) break; } @catch (NSException *e) {}
                }
                
                NSString *nickname = nil;
                NSArray *nicknameKeys = @[@"nickname", @"nick_name", @"userName", @"name"];
                for (NSString *key in nicknameKeys) {
                    @try { nickname = [userInfo valueForKey:key]; if (nickname) break; } @catch (NSException *e) {}
                }
                
                if (userId && secUserId) {
                    MysteryUser *user = [[MysteryUser alloc] init];
                    user.uid = userId;
                    user.secUid = secUserId;
                    user.nickname = nickname ?: @"神秘人";
                    
                    [MysteryUserHelper addUser:user];
                }
            }
        }
    } @catch (NSException *e) {
        NSLog(@"[DouyinMysteryUser] 处理消息错误: %@", e.reason);
    }
    
    ((void (*)(id, SEL, id))originalHandleMessage)(self, _cmd, message);
}

__attribute__((constructor))
static void initialize() {
    NSLog(@"[DouyinMysteryUser] =========================================");
    NSLog(@"[DouyinMysteryUser] ========== dylib 已加载！ ===========");
    NSLog(@"[DouyinMysteryUser] =========================================");
    
    discoveredUsers = [NSMutableArray array];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [MysteryUserHelper setupFloatingWindow];
    });
    
    @autoreleasepool {
        NSArray *classNames = @[
            @"AwemeRoomMessageManager",
            @"AwemeLiveRoomManager",
            @"RoomMessageManager",
            @"LiveRoomManager",
            @"AwemeRoomIMManager"
        ];
        
        Class targetClass = nil;
        SEL targetSel = nil;
        
        for (NSString *className in classNames) {
            Class cls = NSClassFromString(className);
            if (cls) {
                NSLog(@"[DouyinMysteryUser] 找到类: %@", className);
                
                NSArray *selNames = @[
                    @"handleMessage:",
                    @"onMessage:",
                    @"handleRoomMessage:",
                    @"processMessage:",
                    @"receivedMessage:"
                ];
                
                for (NSString *selName in selNames) {
                    SEL sel = NSSelectorFromString(selName);
                    Method method = class_getInstanceMethod(cls, sel);
                    if (method) {
                        NSLog(@"[DouyinMysteryUser] 找到方法: %@", selName);
                        targetClass = cls;
                        targetSel = sel;
                        goto found;
                    }
                }
            }
        }
    found:
        if (targetClass && targetSel) {
            Method originalMethod = class_getInstanceMethod(targetClass, targetSel);
            originalHandleMessage = method_getImplementation(originalMethod);
            method_setImplementation(originalMethod, (IMP)hooked_handleMessage);
            NSLog(@"[DouyinMysteryUser] Hook成功！");
        } else {
            NSLog(@"[DouyinMysteryUser] 未找到目标类或方法");
        }
    }
}
