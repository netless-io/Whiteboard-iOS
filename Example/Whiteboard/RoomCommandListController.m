//
//  WhiteCommandTableViewController.m
//  WhiteSDKPrivate_Example
//
//  Created by yleaf on 2018/12/24.
//  Copyright © 2018 leavesster. All rights reserved.
//

#import "RoomCommandListController.h"
#import <Whiteboard/Whiteboard.h>
#import <YYModel.h>

typedef NS_ENUM(NSInteger, CommandType) {
    CommandTypeResize,
    CommandTypeBroadcast,
    CommandTypeFollower,
    CommandTypeScalePptToFit,
    CommandTypeOperation,
    CommandTypeDeleteOperation,
    CommandTypeMoveRectange,
    CommandTypeCurrentViewMode,
    CommandTypeCustomEvent,
    CommandTypeCleanScene,
    CommandTypeInsertNewScene,
    CommandTypeInsertPpt,
    CommandTypeInsertStatic,
    CommandTypeInsertDynamic,
    CommandTypeInsertDynamicZip,
    CommandTypeInsertImage,
    CommandTypeGetPreviewImage,
    CommandTypeGetSnapshot,
    CommandTypeGetPpt,
    CommandTypeGetScene,
    CommandTypeNextScene,
    CommandTypeGetRoomPhase,
    CommandTypeDisconnect,
    CommandTypeDisableCamera,
    CommandTypeReadonly,
    CommandTypeEnable,
    CommandTypeText,
    CommandTypeSelector,
    CommandTypePencil,
    CommandTypeArrow,
    CommandTypeEraser,
    CommandTypeRectangle,
    CommandTypeColor,
    CommandTypeConvertP,
    CommandTypeScale,
};

@interface RoomCommandListController ()

@property (nonatomic, strong) NSArray<NSString *> *commands;
@property (nonatomic, weak) WhiteRoom *room;
@property (nonatomic, assign, getter=isReadonly) BOOL readonly;

@end

@implementation RoomCommandListController

static NSString *kReuseCell = @"reuseCell";

- (instancetype)initWithRoom:(WhiteRoom *)room
{
    if (self = [super init]) {
        _room = room;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.commands = @[NSLocalizedString(@"改变布局", nil), NSLocalizedString(@"主播", nil), NSLocalizedString(@"观众", nil),
                      NSLocalizedString(@"ppt 铺满屏幕", nil),  NSLocalizedString(@"操作", nil), NSLocalizedString(@"删除", nil),
                      NSLocalizedString(@"移动整体视角", nil), NSLocalizedString(@"当前视角状态", nil), NSLocalizedString(@"发送自定义事件", nil),
                      NSLocalizedString(@"清屏", nil), NSLocalizedString(@"插入新页面", nil), NSLocalizedString(@"插入 PPT", nil),
                      NSLocalizedString(@"插入静态 PPT", nil),NSLocalizedString(@"插入动态 PPT", nil), NSLocalizedString(@"插入动态 PPT(有zip)", nil),
                      NSLocalizedString(@"插入图片", nil), NSLocalizedString(@"获取预览截图", nil), NSLocalizedString(@"获取场景完整封面", nil),
                      NSLocalizedString(@"获取PPT", nil), NSLocalizedString(@"获取页面数据", nil),  NSLocalizedString(@"下一页", nil),
                      NSLocalizedString(@"获取连接状态", nil),NSLocalizedString(@"主动断连", nil), NSLocalizedString(@"视野锁定", nil),
                      NSLocalizedString(@"禁止操作", nil), NSLocalizedString(@"恢复操作", nil), NSLocalizedString(@"文本", nil),
                      NSLocalizedString(@"选择", nil), NSLocalizedString(@"画笔", nil),NSLocalizedString(@"箭头", nil),
                      NSLocalizedString(@"橡皮擦", nil),NSLocalizedString(@"矩形", nil), NSLocalizedString(@"颜色", nil),
                      NSLocalizedString(@"坐标转换", nil), NSLocalizedString(@"缩放", nil)];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kReuseCell];
}

- (CGSize)preferredContentSize
{
    return CGSizeMake(150, MIN(self.commands.count, 10) * 44);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.commands count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kReuseCell forIndexPath:indexPath];
    
    cell.textLabel.text = self.commands[indexPath.row];
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row) {
        case CommandTypeResize:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"changeframe" object:nil];
            break;
        case CommandTypeBroadcast:
            [self.room setViewMode:WhiteViewModeBroadcaster];
            break;
        case CommandTypeFollower:
            [self.room setViewMode:WhiteViewModeFollower];
            break;
        case CommandTypeScalePptToFit:
        {
            [self.room scalePptToFit:WhiteAnimationModeContinuous];
            break;
        }
        case CommandTypeOperation:
        {
            // 开启 本地序列化后，才能使用 redo undo
            [self.room disableSerialization:NO];
            // 在这 10 秒中画点东西
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.room undo];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self.room redo];
                });
            });
            break;
        }
        case CommandTypeDeleteOperation:
        {
            [self.room duplicate];
            [self.room copy];
            [self.room paste];
            [self.room deleteOpertion];
            break;
        }
        case CommandTypeMoveRectange:
        {
            WhiteRectangleConfig *config = [[WhiteRectangleConfig alloc] initWithInitialPosition:200 height:400];
            [self.room moveCameraToContainer:config];
            break;
        }
        case CommandTypeCurrentViewMode:
        {
            [self.room getBroadcastStateWithResult:^(WhiteBroadcastState *state) {
                NSLog(@"broadcastState:%@", [state jsonString]);
            }];
            break;
        }
        case CommandTypeCustomEvent:
            [self.room dispatchMagixEvent:WhiteCommandCustomEvent payload:@{WhiteCommandCustomEvent: @"test"}];
            break;
        case CommandTypeCleanScene:
            [self.room cleanScene:YES];
            break;
        case CommandTypeInsertNewScene:
        case CommandTypeInsertPpt:
        {
            //v2.0 新 API
            WhitePptPage *pptPage = [[WhitePptPage alloc] init];
            pptPage.src = @"https://white-pan.oss-cn-shanghai.aliyuncs.com/101/image/alin-rusu-1239275-unsplash_opt.jpg";
            pptPage.width = 400;
            pptPage.height = 600;
            WhiteScene *scene = [[WhiteScene alloc] initWithName:@"ppt2" ppt:pptPage];
            
            //插入新页面的 API，现在支持传入 ppt 参数（可选），所以插入PPT和插入新页面的 API，合并成了一个。
            [self.room putScenes:@"/" scenes:@[scene] index:0];
            [self.room setScenePath:@"/ppt2"];
            break;
        }
        case CommandTypeInsertStatic:
        {
            WhiteConverter *converter = [[WhiteConverter alloc] initWithRoomToken:self.roomToken];
            [converter startConvertTask:@"https://white-cn-edge-doc-convert.oss-cn-hangzhou.aliyuncs.com/LightWaves.pdf" type:ConvertTypeStatic progress:^(CGFloat progress, WhiteConversionInfo * _Nullable info) {
                NSLog(@"progress:%f", progress);
            } completionHandler:^(BOOL success, ConvertedFiles * _Nullable ppt, WhiteConversionInfo * _Nullable info, NSError * _Nullable error) {
                NSLog(@"success:%d ppt: %@ error:%@", success, [ppt yy_modelDescription], error);
                
                if (ppt) {
                    [self.room putScenes:@"/static" scenes:ppt.scenes index:0];
                    [self.room setScenePath:@"/static/1"];
                }
            }];
            break;
        }
        case CommandTypeInsertDynamic:
        {
            WhiteConverter *converter = [[WhiteConverter alloc] initWithRoomToken:self.roomToken];
            [converter startConvertTask:@"https://white-cn-edge-doc-convert.oss-cn-hangzhou.aliyuncs.com/-1/1.pptx" type:ConvertTypeDynamic progress:^(CGFloat progress, WhiteConversionInfo * _Nullable info) {
                NSLog(@"progress:%f", progress);
            } completionHandler:^(BOOL success, ConvertedFiles * _Nullable ppt, WhiteConversionInfo * _Nullable info, NSError * _Nullable error) {
                NSLog(@"success:%d ppt: %@ error:%@", success, [ppt yy_modelDescription], error);
                
                if (ppt) {
                    [self.room putScenes:@"/dynamic" scenes:ppt.scenes index:0];
                    [self.room setScenePath:@"/dynamic/1"];
                }
            }];
            break;
        }
        case CommandTypeInsertDynamicZip:
        {
            WhiteScene *scene1 = [[WhiteScene alloc] initWithName:@"1" ppt:[[WhitePptPage alloc] initWithSrc:@"pptx://white-cover.oss-cn-hangzhou.aliyuncs.com/dynamicConvert/e1ee27fdb0fc4b7c8f649291010c4882/1.slide" size:CGSizeMake(1280, 720)]];
            WhiteScene *scene2 = [[WhiteScene alloc] initWithName:@"1" ppt:[[WhitePptPage alloc] initWithSrc:@"pptx://white-cover.oss-cn-hangzhou.aliyuncs.com/dynamicConvert/e1ee27fdb0fc4b7c8f649291010c4882/2.slide" size:CGSizeMake(1280, 720)]];

            [self.room putScenes:@"/dynamiczip" scenes:@[scene1, scene2] index:0];
            [self.room setScenePath:@"/dynamiczip/1"];
            break;
        }
        case CommandTypeGetPreviewImage:
        {
            NSString *path = self.room.state.sceneState.scenePath;
            [self.room getScenePreviewImage:path completion:^(UIImage * _Nullable image) {
                __unused UIImageView *imgV = [[UIImageView alloc] initWithImage:image];
                [UIPasteboard generalPasteboard].image = image;
            }];
            break;
        }
        case CommandTypeGetSnapshot:
        {
            NSString *path = self.room.state.sceneState.scenePath;
            [self.room getSceneSnapshotImage:path completion:^(UIImage * _Nullable image) {
                __unused UIImageView *imgV = [[UIImageView alloc] initWithImage:image];
                [UIPasteboard generalPasteboard].image = image;
            }];
            break;
        }
        case CommandTypeInsertImage:
        {
            WhiteImageInformation *info = [[WhiteImageInformation alloc] initWithSize:CGSizeMake(200, 300)];
            //这一行与注释的两行代码等效
            [self.room insertImage:info src:@"https://white-pan.oss-cn-shanghai.aliyuncs.com/101/image/Rectangle.png"];
//            [self.room insertImage:info];
//            [self.room completeImageUploadWithUuid:info.uuid src:@"https://white-pan.oss-cn-shanghai.aliyuncs.com/101/image/Rectangle.png"];
            break;
        }
        case CommandTypeGetPpt:
        {
            //v2.0 新API，通过获取每个 scene，再去查询 ppt 属性，如果没有 ppt，则 ppt 属性会为空
            [self.room getScenesWithResult:^(NSArray<WhiteScene *> * _Nonnull scenes) {
                for (WhiteScene *s in scenes) {
                    NSLog(@"ppt:%@", s.ppt.src);
                }
            }];
            break;
        }
        case CommandTypeGetScene:
        {
            [self.room getScenesWithResult:^(NSArray<WhiteScene *> *scenes) {
                NSLog(@"scenes:%@", scenes);
            }];
            break;
        }
        case CommandTypeNextScene:
        {
            [self.room getSceneStateWithResult:^(WhiteSceneState * _Nonnull state) {
                NSLog(@"state:%@", [state jsonString]);
                [self.room setSceneIndex:state.index + 1 completionHandler:^(BOOL success, NSError * _Nullable error) {
                    NSLog(@"success:%d error:%@", success, error.userInfo);
                }];
            }];
            break;
        }
        case CommandTypeGetRoomPhase:
        {
            [self.room getRoomPhaseWithResult:^(WhiteRoomPhase phase) {
                NSLog(@"WhiteRoomPhase:%ld", (long)phase);
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"当前连接状态", nil) message:[NSString stringWithFormat:NSLocalizedString(@"WhiteRoomPhase:%ld", nil), (long)phase] preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *action = [UIAlertAction actionWithTitle:NSLocalizedString(@"确定", nil) style:UIAlertActionStyleCancel handler:nil];
                [alertController addAction:action];
                [self.presentingViewController presentViewController:alertController animated:YES completion:nil];
            }];
            break;
        }
        case CommandTypeDisconnect:
        {
            [self.room disconnect:^{
                NSLog(@"房间已断连，如需加入房间，请使用 SDK API，新建 WhiteRoom 实例加入");
            }];
            break;
        }
        case CommandTypeDisableCamera:
            [self.room disableCameraTransform:YES];
            break;
        case CommandTypeReadonly:
            [self.room disableOperations:YES];
            break;
        case CommandTypeEnable:
            [self.room disableOperations:NO];
            break;
        case CommandTypeSelector:
        {
            WhiteMemberState *mState = [[WhiteMemberState alloc] init];
            mState.currentApplianceName = ApplianceSelector;
            [self.room setMemberState:mState];
            break;
        }
        case CommandTypeText:
        {
            WhiteMemberState *mState = [[WhiteMemberState alloc] init];
            mState.currentApplianceName = ApplianceText;
            [self.room setMemberState:mState];
            break;
        }
        case CommandTypePencil:
        {
            WhiteMemberState *mState = [[WhiteMemberState alloc] init];
            mState.currentApplianceName = AppliancePencil;
            [self.room setMemberState:mState];
            break;
        }
        case CommandTypeArrow:
        {
            WhiteMemberState *mState = [[WhiteMemberState alloc] init];
            mState.currentApplianceName = ApplianceArrow;
            [self.room setMemberState:mState];
            break;
        }
        case CommandTypeEraser:
        {
            WhiteMemberState *mState = [[WhiteMemberState alloc] init];
            mState.currentApplianceName = ApplianceEraser;
            [self.room setMemberState:mState];
            break;
        }
        case CommandTypeRectangle:
        {
            WhiteMemberState *mState = [[WhiteMemberState alloc] init];
            mState.currentApplianceName = ApplianceRectangle;
            [self.room setMemberState:mState];
            break;
        }
        case CommandTypeColor:
        {
            WhiteMemberState *mState = [[WhiteMemberState alloc] init];
            mState.currentApplianceName = AppliancePencil;
            mState.strokeColor = @[@200, @200, @200];
            mState.strokeWidth = @10;
            [self.room setMemberState:mState];
            break;
        }
        case CommandTypeConvertP:
        {
            for (int i = 0; i < 5; i ++) {
                WhitePanEvent *point = [[WhitePanEvent alloc] init];
                point.x = [UIScreen mainScreen].bounds.size.width / 2;
                point.y = i * 100;
                [self.room convertToPointInWorld:point result:^(WhitePanEvent * _Nonnull convertPoint) {
                    NSLog(@"covert:%@", [convertPoint jsonDict]);
                }];
            }
            break;
        }
        case CommandTypeScale:
        {
            [self.room getZoomScaleWithResult:^(CGFloat scale) {
                WhiteCameraConfig *camerConfgi = [[WhiteCameraConfig alloc] init];
                camerConfgi.scale = scale == 1 ? @5 : @1;
                [self.room moveCamera:camerConfgi];
            }];
            break;
        }
        default:
            break;
    }
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
