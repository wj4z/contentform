#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>

// Cho phép hiện banner cả khi app đang mở
@interface CFNotifDelegate : NSObject <UNUserNotificationCenterDelegate>
@end
@implementation CFNotifDelegate
- (void)userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification
         withCompletionHandler:(void (^)(UNNotificationPresentationOptions))handler {
    handler(UNNotificationPresentationOptionBanner |
            UNNotificationPresentationOptionList |
            UNNotificationPresentationOptionSound);
}
@end

static CFNotifDelegate *gNotifDelegate;

static void setupNotifications(void) {
    UNUserNotificationCenter *center = UNUserNotificationCenter.currentNotificationCenter;
    if (!center.delegate) {
        gNotifDelegate = [CFNotifDelegate new];
        center.delegate = gNotifDelegate;
    }
    [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert |
                                             UNAuthorizationOptionSound |
                                             UNAuthorizationOptionBadge)
                          completionHandler:^(BOOL granted, NSError *error) {}];
}

static void showNotification(NSString *body) {
    UNMutableNotificationContent *c = [UNMutableNotificationContent new];
    c.title = @"Đã thực hiện";
    c.body = body;
    c.sound = UNNotificationSound.defaultSound;
    UNTimeIntervalNotificationTrigger *t =
        [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:1 repeats:NO];
    UNNotificationRequest *r =
        [UNNotificationRequest requestWithIdentifier:NSUUID.UUID.UUIDString
                                             content:c trigger:t];
    [UNUserNotificationCenter.currentNotificationCenter addNotificationRequest:r
                                                         withCompletionHandler:nil];
}

@interface ContentFormView : UIView
@property (nonatomic, strong) UIView *card;
@property (nonatomic, strong) UITextField *noteField;
@property (nonatomic, strong) UILabel *msgLabel;
@end

@implementation ContentFormView

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];

        CGFloat w = MIN(320, frame.size.width - 40), h = 260;
        _card = [[UIView alloc] initWithFrame:CGRectMake((frame.size.width - w) / 2,
                                                         frame.size.height * 0.25, w, h)];
        _card.backgroundColor = UIColor.systemBackgroundColor;
        _card.layer.cornerRadius = 20;
        [self addSubview:_card];

        UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
        close.frame = CGRectMake(w - 44, 8, 36, 36);
        [close setTitle:@"✕" forState:UIControlStateNormal];
        [close addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
        [_card addSubview:close];

        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 24, w - 70, 28)];
        label.text = @"Nội dung";
        label.font = [UIFont boldSystemFontOfSize:20];
        [_card addSubview:label];

        _noteField = [[UITextField alloc] initWithFrame:CGRectMake(20, 62, w - 40, 48)];
        _noteField.placeholder = @"Nội dung";
        _noteField.borderStyle = UITextBorderStyleRoundedRect;
        _noteField.returnKeyType = UIReturnKeyDone;
        [_noteField addTarget:_noteField action:@selector(resignFirstResponder)
             forControlEvents:UIControlEventEditingDidEndOnExit];
        [_card addSubview:_noteField];

        UIButton *go = [UIButton buttonWithType:UIButtonTypeSystem];
        go.frame = CGRectMake(20, 128, w - 40, 52);
        [go setTitle:@"Thực hiện" forState:UIControlStateNormal];
        [go setTitleColor:UIColor.systemBackgroundColor forState:UIControlStateNormal];
        go.titleLabel.font = [UIFont boldSystemFontOfSize:19];
        go.backgroundColor = UIColor.labelColor;
        go.layer.cornerRadius = 14;
        [go addTarget:self action:@selector(onGo) forControlEvents:UIControlEventTouchUpInside];
        [_card addSubview:go];

        _msgLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 192, w - 40, 50)];
        _msgLabel.numberOfLines = 2;
        _msgLabel.font = [UIFont systemFontOfSize:15];
        [_card addSubview:_msgLabel];
    }
    return self;
}

- (void)onGo {
    NSString *text = [_noteField.text stringByTrimmingCharactersInSet:
                      NSCharacterSet.whitespaceAndNewlineCharacterSet];
    [_noteField resignFirstResponder];
    if (text.length == 0) {
        _msgLabel.textColor = UIColor.systemRedColor;
        _msgLabel.text = @"Vui lòng nhập nội dung.";
        return;
    }
    // TODO: gắn logic thật của bạn tại đây
    NSLog(@"[ContentForm] Thực hiện: %@", text);
    showNotification(text);
    _msgLabel.textColor = UIColor.systemGreenColor;
    _msgLabel.text = [NSString stringWithFormat:@"Đã thực hiện: %@", text];
    _noteField.text = @"";
}

- (void)dismiss {
    [_noteField resignFirstResponder];
    [UIView animateWithDuration:0.2 animations:^{ self.alpha = 0; }
                     completion:^(BOOL f) { [self removeFromSuperview]; }];
}

@end

__attribute__((constructor))
static void on_load(void) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC),
                   dispatch_get_main_queue(), ^{
        setupNotifications();
        UIWindow *window = nil;
        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
            if ([scene isKindOfClass:UIWindowScene.class]) {
                window = ((UIWindowScene *)scene).windows.firstObject;
                break;
            }
        }
        if (!window) return;
        [window addSubview:[[ContentFormView alloc] initWithFrame:window.bounds]];
    });
}
