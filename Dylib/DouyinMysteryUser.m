#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// ==== 全局变量 ====
static UIWindow *floatingWindow = nil;
static UIButton *floatingButton = nil;
static UIViewController *listVC = nil;
static BOOL listVisible = NO;
static NSMutableArray *users = nil;
static NSMutableSet *seenSecUids = nil;

// ==== 用户模型 ====
@interface MYUser : NSObject
@property (nonatomic, copy) NSString *nickname;
@property (nonatomic, copy) NSString *secUid;
@property (nonatomic, copy) NSString *source;
@end
@implementation MYUser @end

// ==== 列表视图控制器 ====
@interface MYListVC : UIViewController <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;
@end

@implementation MYListVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.frame = CGRectMake(20, 100, 340, 550);
    self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.95];
    self.view.layer.cornerRadius = 20;
    self.view.layer.masksToBounds = YES;
    
    UILabel *titleLbl = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, 280, 30)];
    titleLbl.text = @"发现的神秘人";
    titleLbl.font = [UIFont boldSystemFontOfSize:20];
    titleLbl.textColor = [UIColor whiteColor];
    [self.view addSubview:titleLbl];
    
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    closeBtn.frame = CGRectMake(300, 20, 30, 30);
    [closeBtn setTitle:@"✕" forState:UIControlStateNormal];
    closeBtn.titleLabel.font = [UIFont systemFontOfSize:24];
    [closeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [closeBtn addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:closeBtn];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(10, 60, 320, 480)];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorColor = [[UIColor grayColor] colorWithAlphaComponent:0.3];
    self.tableView.rowHeight = 80;
    [self.view addSubview:self.tableView];
    
    UILabel *infoLbl = [[UILabel alloc] initWithFrame:CGRectMake(20, 100, 300, 60)];
    infoLbl.text = @"请先用Frida测试\n找到正确的Hook点！";
    infoLbl.font = [UIFont systemFontOfSize:15];
    infoLbl.textColor = [UIColor orangeColor];
    infoLbl.numberOfLines = 2;
    [self.view addSubview:infoLbl];
}

- (void)close {
    [self dismissViewControllerAnimated:YES completion:^{
        listVisible = NO;
    }];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return users.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellId = @"MYUserCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellId];
        cell.backgroundColor = [UIColor clearColor];
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.detailTextLabel.textColor = [UIColor lightGrayColor];
    }
    
    MYUser *user = users[indexPath.row];
    cell.textLabel.text = user.nickname;
    cell.textLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"来源: %@", user.source];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    MYUser *user = users[indexPath.row];
    NSString *urlStr = [NSString stringWithFormat:@"https://www.douyin.com/user/%@", user.secUid];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:user.nickname message:urlStr preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"复制" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UIPasteboard.generalPasteboard.string = urlStr;
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"打开" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlStr] options:@{} completionHandler:nil];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end

// ==== 辅助类 ====
@interface MYHelper : NSObject
@end

@implementation MYHelper

+ (void)showFloatingButton {
    if (floatingWindow) return;
    
    floatingWindow = [[UIWindow alloc] initWithFrame:CGRectMake(20, 300, 56, 56)];
    floatingWindow.windowLevel = UIWindowLevelAlert + 1000;
    floatingWindow.backgroundColor = [UIColor colorWithRed:0.0 green:0.48 blue:1.0 alpha:0.9];
    floatingWindow.layer.cornerRadius = 28;
    floatingWindow.layer.shadowColor = [UIColor blackColor].CGColor;
    floatingWindow.layer.shadowOpacity = 0.4;
    floatingWindow.layer.shadowOffset = CGSizeMake(0, 3);
    floatingWindow.layer.shadowRadius = 10;
    
    floatingButton = [UIButton buttonWithType:UIButtonTypeCustom];
    floatingButton.frame = floatingWindow.bounds;
    [floatingButton setTitle:@"👤" forState:UIControlStateNormal];
    floatingButton.titleLabel.font = [UIFont systemFontOfSize:26];
    [floatingButton addTarget:self action:@selector(toggleList) forControlEvents:UIControlEventTouchUpInside];
    
    [floatingWindow addSubview:floatingButton];
    [floatingWindow makeKeyAndVisible];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [floatingButton addGestureRecognizer:pan];
    
    NSLog(@"[MY] 浮动按钮已显示！");
}

+ (void)handlePan:(UIPanGestureRecognizer *)gesture {
    UIView *btn = gesture.view;
    UIWindow *win = btn.window;
    if (!win) return;
    
    CGPoint trans = [gesture translationInView:win];
    CGPoint center = btn.center;
    center.x += trans.x;
    center.y += trans.y;
    
    CGFloat margin = 40;
    CGSize screen = [UIScreen mainScreen].bounds.size;
    center.x = MAX(margin, MIN(center.x, screen.width - margin));
    center.y = MAX(margin, MIN(center.y, screen.height - margin));
    
    btn.center = center;
    [gesture setTranslation:CGPointMake(0, 0) inView:win];
}

+ (void)toggleList {
    if (listVisible) {
        [listVC dismissViewControllerAnimated:YES completion:^{
            listVisible = NO;
        }];
    } else {
        if (!listVC) {
            listVC = [[MYListVC alloc] init];
        }
        listVC.modalPresentationStyle = UIModalPresentationOverFullScreen;
        
        UIWindow *keyWin = nil;
        for (UIWindow *w in [UIApplication sharedApplication].windows) {
            if (w.isKeyWindow) {
                keyWin = w;
                break;
            }
        }
        if (!keyWin) keyWin = [UIApplication sharedApplication].windows.firstObject;
        
        [keyWin.rootViewController presentViewController:listVC animated:YES completion:^{
            listVisible = YES;
            [listVC.tableView reloadData];
        }];
    }
}

+ (void)addUser:(NSString *)nickname secUid:(NSString *)secUid source:(NSString *)source {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!nickname || !secUid) return;
        if (!seenSecUids) seenSecUids = [NSMutableSet set];
        if ([seenSecUids containsObject:secUid]) return;
        if (!users) users = [NSMutableArray array];
        
        [seenSecUids addObject:secUid];
        
        MYUser *user = [[MYUser alloc] init];
        user.nickname = nickname;
        user.secUid = secUid;
        user.source = source;
        [users insertObject:user atIndex:0];
        
        NSString *title = users.count > 0 ? [NSString stringWithFormat:@"👤%lu", (unsigned long)users.count] : @"👤";
        [floatingButton setTitle:title forState:UIControlStateNormal];
        
        if (listVisible) [listVC.tableView reloadData];
        
        NSLog(@"[MY] 🎉 发现用户: %@ (%@)", nickname, secUid);
    });
}

@end

// ==== 初始化 ====
__attribute__((constructor))
static void initMY() {
    NSLog(@"[MY] =====================================");
    NSLog(@"[MY] 抖音神秘人插件已加载！");
    NSLog(@"[MY] =====================================");
    
    users = [NSMutableArray array];
    seenSecUids = [NSMutableSet set];
    
    // 测试：添加一个假用户
    [MYHelper addUser:@"神秘人001" secUid:@"MS4wLj476263212" source:@"测试"];
    
    // 延迟显示UI
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"插件已加载" message:@"抖音神秘人捕获工具已启动！" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:nil]];
        
        UIWindow *keyWin = nil;
        for (UIWindow *w in [UIApplication sharedApplication].windows) {
            if (w.isKeyWindow) {
                keyWin = w;
                break;
            }
        }
        if (!keyWin) keyWin = [UIApplication sharedApplication].windows.firstObject;
        
        [keyWin.rootViewController presentViewController:alert animated:YES completion:nil];
        
        [MYHelper showFloatingButton];
    });
    
    NSLog(@"[MY] 初始化完成！");
}
