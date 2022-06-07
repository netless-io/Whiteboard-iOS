//
//  CommandHandler.m
//  Whiteboard_Example
//
//  Created by xuyunshi on 2022/4/13.
//  Copyright © 2022 leavesster. All rights reserved.
//

#import "CommandHandler.h"

static BOOL onlyApplePencil = NO;

@implementation CommandHandler

+ (NSDictionary<NSString *,void (^)(WhiteCombinePlayer * _Nonnull)> *)generateCommandsForCombineReplay:(WhiteCombinePlayer *)player {
    return @{
        NSLocalizedString(@"播放", nil): ^(WhiteCombinePlayer* player) {
            [player play];
        },
        NSLocalizedString(@"暂停", nil): ^(WhiteCombinePlayer* player) {
            [player pause];
        },
        NSLocalizedString(@"加速", nil): ^(WhiteCombinePlayer* player) {
            player.playbackSpeed = 1.25;
        },
        NSLocalizedString(@"快进", nil): ^(WhiteCombinePlayer* player) {
            [player seekToTime:CMTimeMake(3000, 600) completionHandler:^(BOOL finished) {
                [player play];
            }];
        },
        NSLocalizedString(@"观察模式", nil): ^(WhiteCombinePlayer* player) {
            [player.whitePlayer setObserverMode:WhiteObserverModeFreedom];
        },
        NSLocalizedString(@"获取信息", nil): ^(WhiteCombinePlayer* player) {
            [player.whitePlayer getPlayerStateWithResult:^(WhitePlayerState * _Nullable state) {
                NSLog(@"%@", state);
            }];
            [player.whitePlayer getPlayerTimeInfoWithResult:^(WhitePlayerTimeInfo * _Nonnull info) {
                NSLog(@"%@", info);
            }];
            [player.whitePlayer getPlaybackSpeed:^(CGFloat speed) {
                NSLog(@"%f", speed);
            }];
        }
    };
}

+ (NSDictionary<NSString *,void (^)(WhitePlayer * _Nonnull)> *)generateCommandsForReplay:(WhitePlayer *)player {
    return @{
        NSLocalizedString(@"播放", nil): ^(WhitePlayer* player) {
            [player play];
        },
        NSLocalizedString(@"暂停", nil): ^(WhitePlayer* player) {
            [player pause];
        },
        NSLocalizedString(@"加速", nil): ^(WhitePlayer* player) {
            player.playbackSpeed = 1.25;
        },
        NSLocalizedString(@"快进", nil): ^(WhitePlayer* player) {
            [player seekToScheduleTime:5];
        },
        NSLocalizedString(@"观察模式", nil): ^(WhitePlayer* player) {
            [player setObserverMode:WhiteObserverModeFreedom];
        },
        NSLocalizedString(@"获取信息", nil): ^(WhitePlayer* player) {
            [player getPlayerStateWithResult:^(WhitePlayerState * _Nullable state) {
                NSLog(@"%@", state);
            }];
            [player getPlayerTimeInfoWithResult:^(WhitePlayerTimeInfo * _Nonnull info) {
                NSLog(@"%@", info);
            }];
        }
    };
}

+ (NSDictionary<NSString*, void(^)(WhiteRoom* room)> *)generateCommandsForRoom:(WhiteRoom *)room roomToken:(NSString *)roomToken {
    return @{
        NSLocalizedString(@"改变布局", nil): ^(WhiteRoom* room) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"changeframe" object:nil];
        }
        ,
        NSLocalizedString(@"主播", nil): ^(WhiteRoom* room) {
            [room setViewMode:WhiteViewModeBroadcaster];
        }
        ,
        NSLocalizedString(@"观众", nil): ^(WhiteRoom* room) {
            [room setViewMode:WhiteViewModeFollower];
        }
        ,
        NSLocalizedString(@"铺满屏幕", nil): ^(WhiteRoom* room) {
            [room scalePptToFit:WhiteAnimationModeContinuous];
        }
        ,
        NSLocalizedString(@"撤销重做", nil): ^(WhiteRoom* room) {
            // 开启 本地序列化后，才能使用 redo undo
            [room disableSerialization:NO];
            // 在这 10 秒中画点东西
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [room undo];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [room redo];
                });
            });
        }
        ,
        NSLocalizedString(@"删除", nil): ^(WhiteRoom* room) {
            [room duplicate];
            [room copy];
            [room paste];
            [room deleteOperation];
        }
        ,
        NSLocalizedString(@"移动整体视角", nil): ^(WhiteRoom* room) {
            WhiteRectangleConfig *config = [[WhiteRectangleConfig alloc] initWithInitialPosition:200 height:400];
            [room moveCameraToContainer:config];
        }
        ,
        NSLocalizedString(@"当前视角状态", nil): ^(WhiteRoom* room) {
            [room getBroadcastStateWithResult:^(WhiteBroadcastState *state) {
                NSLog(@"broadcastState:%@", [state jsonString]);
            }];
        }
        ,
        NSLocalizedString(@"自定义事件", nil): ^(WhiteRoom* room) {
            [room dispatchMagixEvent:WhiteCommandCustomEvent payload:@{WhiteCommandCustomEvent: @"test"}];
        }
        ,
        NSLocalizedString(@"清屏", nil): ^(WhiteRoom* room) {
            [room cleanScene:YES];
        }
        ,
        NSLocalizedString(@"插入新页面", nil): ^(WhiteRoom* room) {
            [room addPage];
            [room nextPage:nil];
        }
        ,
        NSLocalizedString(@"删除当前页面", nil): ^(WhiteRoom* room) {
            [room removePage:nil];
        }
        ,
        NSLocalizedString(@"插入已转换 PPT (已废弃)", nil): ^(WhiteRoom* room) {
            //v2.0 新 API
            WhitePptPage *pptPage = [[WhitePptPage alloc] init];
            pptPage.src = @"https://white-pan.oss-cn-shanghai.aliyuncs.com/101/image/alin-rusu-1239275-unsplash_opt.jpg";
            pptPage.width = 400;
            pptPage.height = 600;
            WhiteScene *scene = [[WhiteScene alloc] initWithName:@"ppt2" ppt:pptPage];
            
            //插入新页面的 API，现在支持传入 ppt 参数（可选），所以插入PPT和插入新页面的 API，合并成了一个。
            [room putScenes:@"/" scenes:@[scene] index:0];
            [room setScenePath:@"/ppt2"];
        }
        ,
        NSLocalizedString(@"发起静态转码 (已废弃)", nil): ^(WhiteRoom* room) {
            WhiteConverter *converter = [[WhiteConverter alloc] initWithRoomToken:roomToken];
            [converter startConvertTask:@"https://white-cn-edge-doc-convert.oss-cn-hangzhou.aliyuncs.com/LightWaves.pdf" type:ConvertTypeStatic progress:^(CGFloat progress, WhiteConversionInfo * _Nullable info) {
                NSLog(@"progress:%f", progress);
            } completionHandler:^(BOOL success, ConvertedFiles * _Nullable ppt, WhiteConversionInfo * _Nullable info, NSError * _Nullable error) {
                NSLog(@"success:%d ppt: %@ error:%@", success, [ppt yy_modelDescription], error);
                
                if (ppt) {
                    [room putScenes:@"/static" scenes:ppt.scenes index:0];
                    [room setScenePath:@"/static/1"];
                }
            }];
        }
        ,
        NSLocalizedString(@"发起动态转码 (已废弃)", nil): ^(WhiteRoom* room) {
            WhitePptPage *page = [[WhitePptPage alloc] initWithSrc:@"pptx://convertcdn.netless.link/dynamicConvert/17510b2000c411ecbfbbb9230f6dd80f/1.slide" size:CGSizeMake(960, 720)];
            WhiteScene *scene = [[WhiteScene alloc] initWithName:@"1" ppt:page];
            WhiteAppParam *app = [WhiteAppParam createDocsViewerApp:@"/www" scenes:@[scene] title:@"tt"];
            [room addApp:app completionHandler:^(NSString * _Nonnull appId) {
                NSLog(@"app id: %@", appId);
            }];
            
            [room safeSetAttributes:@{@"a": @"aaaa", @"b": @{@"ba": @"bababa"}}];
            
            [room getSyncedState:^(NSDictionary * _Nonnull state) {
                NSLog(@"state1: %@", state);
            }];
            
            [room safeUpdateAttributes:@[@"b", @"ba"] attributes:@"cccc"];
            [room getSyncedState:^(NSDictionary * _Nonnull state) {
                NSLog(@"state2: %@", state);
            }];
        }
        ,
        NSLocalizedString(@"插入动态ppt", nil): ^(WhiteRoom* room) {
            WhiteAppParam *app = [WhiteAppParam createSlideApp:@"/ppt" taskId:@"7f5d2864e82b4f0e9c868f348e922453" url:@"https://convertcdn.netless.link/dynamicConvert" title:@"example_ppt"];
            [room addApp:app completionHandler:^(NSString * _Nonnull appId) {
                NSLog(@"app id: %@", appId);
            }];
        }
        ,
        NSLocalizedString(@"插入动态 PPT(有zip)", nil): ^(WhiteRoom* room) {
            WhiteScene *scene1 = [[WhiteScene alloc] initWithName:@"1" ppt:[[WhitePptPage alloc] initWithSrc:@"pptx://white-cover.oss-cn-hangzhou.aliyuncs.com/dynamicConvert/e1ee27fdb0fc4b7c8f649291010c4882/1.slide" size:CGSizeMake(1280, 720)]];
            WhiteScene *scene2 = [[WhiteScene alloc] initWithName:@"1" ppt:[[WhitePptPage alloc] initWithSrc:@"pptx://white-cover.oss-cn-hangzhou.aliyuncs.com/dynamicConvert/e1ee27fdb0fc4b7c8f649291010c4882/2.slide" size:CGSizeMake(1280, 720)]];
            
            [room putScenes:@"/dynamiczip" scenes:@[scene1, scene2] index:0];
            [room setScenePath:@"/dynamiczip/1"];
        }
        ,
        NSLocalizedString(@"插入图片", nil): ^(WhiteRoom* room) {
            WhiteImageInformation *info = [[WhiteImageInformation alloc] initWithSize:CGSizeMake(200, 300)];
            //这一行与注释的两行代码等效
            [room insertImage:info src:@"https://white-pan.oss-cn-shanghai.aliyuncs.com/101/image/Rectangle.png"];
            //            [room insertImage:info];
            //            [room completeImageUploadWithUuid:info.uuid src:@"https://white-pan.oss-cn-shanghai.aliyuncs.com/101/image/Rectangle.png"];
        }
        ,
        NSLocalizedString(@"插入文字", nil): ^(WhiteRoom* room) {
            [room insertText:0 y:0 textContent:@"Hello text!" completionHandler:^(NSString * _Nonnull textId) {
                NSLog(@"insert with textId %@", textId);
            }];
        }
        ,
        NSLocalizedString(@"获取预览截图", nil): ^(WhiteRoom* room) {
            NSString *path = room.state.sceneState.scenePath;
            [room getScenePreviewImage:path completion:^(UIImage * _Nullable image) {
                __unused UIImageView *imgV = [[UIImageView alloc] initWithImage:image];
                [UIPasteboard generalPasteboard].image = image;
            }];
        }
        ,
        NSLocalizedString(@"获取场景完整封面", nil): ^(WhiteRoom* room) {
            NSString *path = room.state.sceneState.scenePath;
            [room getSceneSnapshotImage:path completion:^(UIImage * _Nullable image) {
                __unused UIImageView *imgV = [[UIImageView alloc] initWithImage:image];
                [UIPasteboard generalPasteboard].image = image;
            }];
        }
        ,
        NSLocalizedString(@"获取PPT", nil): ^(WhiteRoom* room) {
            //v2.0 新API，通过获取每个 scene，再去查询 ppt 属性，如果没有 ppt，则 ppt 属性会为空
            [room getScenesWithResult:^(NSArray<WhiteScene *> * _Nonnull scenes) {
                for (WhiteScene *s in scenes) {
                    NSLog(@"ppt:%@", s.ppt.src);
                }
            }];
        }
        ,
        NSLocalizedString(@"获取页面数据", nil): ^(WhiteRoom* room) {
            [room getScenesWithResult:^(NSArray<WhiteScene *> *scenes) {
                NSLog(@"scenes:%@", scenes);
            }];
        }
        ,
        NSLocalizedString(@"下一页", nil): ^(WhiteRoom* room) {
            [room getSceneStateWithResult:^(WhiteSceneState * _Nonnull state) {
                NSLog(@"state:%@", [state jsonString]);
                [room setSceneIndex:state.index + 1 completionHandler:^(BOOL success, NSError * _Nullable error) {
                    NSLog(@"success:%d error:%@", success, error.userInfo);
                }];
            }];
        }
        ,
        NSLocalizedString(@"获取连接状态", nil): ^(WhiteRoom* room) {
            [room getRoomPhaseWithResult:^(WhiteRoomPhase phase) {
                NSLog(@"WhiteRoomPhase:%ld", (long)phase);
//                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"当前连接状态", nil) message:[NSString stringWithFormat:NSLocalizedString(@"WhiteRoomPhase:%ld", nil), (long)phase] preferredStyle:UIAlertControllerStyleAlert];
//                UIAlertAction *action = [UIAlertAction actionWithTitle:NSLocalizedString(@"确定", nil) style:UIAlertActionStyleCancel handler:nil];
//                [alertController addAction:action];
//
//                [self.presentingViewController presentViewController:alertController animated:YES completion:nil];
            }];
        }
        ,
        NSLocalizedString(@"主动断连", nil): ^(WhiteRoom* room) {
            [room disconnect:^{
                NSLog(@"房间已断连，如需加入房间，请使用 SDK API，新建 WhiteRoom 实例加入");
            }];
        }
        ,
        NSLocalizedString(@"锁定视野", nil): ^(WhiteRoom* room) {
            [room disableCameraTransform:YES];
        }
        ,
        NSLocalizedString(@"禁止操作", nil): ^(WhiteRoom* room) {
            [room disableOperations:YES];
        }
        ,
        NSLocalizedString(@"恢复操作", nil): ^(WhiteRoom* room) {
            [room disableOperations:NO];
        }
        ,
        NSLocalizedString(@"文本教具", nil): ^(WhiteRoom* room) {
            WhiteMemberState *mState = [[WhiteMemberState alloc] init];
            mState.currentApplianceName = ApplianceText;
            [room setMemberState:mState];
        }
        ,
        NSLocalizedString(@"选择教具", nil): ^(WhiteRoom* room) {
            WhiteMemberState *mState = [[WhiteMemberState alloc] init];
            mState.currentApplianceName = ApplianceSelector;
            [room setMemberState:mState];
        }
        ,
        NSLocalizedString(@"画笔教具", nil): ^(WhiteRoom* room) {
            WhiteMemberState *mState = [[WhiteMemberState alloc] init];
            mState.currentApplianceName = AppliancePencil;
            [room setMemberState:mState];
        }
        ,
        NSLocalizedString(@"箭头教具", nil): ^(WhiteRoom* room) {
            WhiteMemberState *mState = [[WhiteMemberState alloc] init];
            mState.currentApplianceName = ApplianceArrow;
            [room setMemberState:mState];
        }
        ,
        NSLocalizedString(@"橡皮擦教具", nil): ^(WhiteRoom* room) {
            WhiteMemberState *mState = [[WhiteMemberState alloc] init];
            mState.currentApplianceName = ApplianceEraser;
            [room setMemberState:mState];
        }
        ,
        NSLocalizedString(@"矩形教具", nil): ^(WhiteRoom* room) {
            WhiteMemberState *mState = [[WhiteMemberState alloc] init];
            mState.currentApplianceName = ApplianceRectangle;
            [room setMemberState:mState];
        }
        ,
        NSLocalizedString(@"随机颜色", nil): ^(WhiteRoom* room) {
            WhiteMemberState *mState = [[WhiteMemberState alloc] init];
            mState.currentApplianceName = AppliancePencil;
            mState.strokeColor = @[@(arc4random_uniform(255) / 255), @(arc4random_uniform(255) / 255), @(arc4random_uniform(255) / 255)];
            mState.strokeWidth = @10;
            [room setMemberState:mState];
        }
        ,
        NSLocalizedString(@"坐标转换", nil): ^(WhiteRoom* room) {
            for (int i = 0; i < 5; i ++) {
                WhitePanEvent *point = [[WhitePanEvent alloc] init];
                point.x = [UIScreen mainScreen].bounds.size.width / 2;
                point.y = i * 100;
                [room convertToPointInWorld:point result:^(WhitePanEvent * _Nonnull convertPoint) {
                    NSLog(@"covert:%@", [convertPoint jsonDict]);
                }];
            }
        }
        ,
        NSLocalizedString(@"缩放", nil): ^(WhiteRoom* room) {
            [room getZoomScaleWithResult:^(CGFloat scale) {
                WhiteCameraConfig *camerConfig = [[WhiteCameraConfig alloc] init];
                camerConfig.scale = scale == 1 ? @5 : @1;
                [room moveCamera:camerConfig];
            }];
        }
        ,
        NSLocalizedString(@"修改比例", nil): ^(WhiteRoom* room) {
            static int rCount = 0;
            if (rCount % 2 == 0) {
                [room setContainerSizeRatio:@1];
            } else {
                [room setContainerSizeRatio:@(9.0/16)];
            }
            rCount += 1;
        },
        NSLocalizedString(@"多窗口颜色", nil): ^(WhiteRoom* room) {
            static int cCount = 0;
            if (cCount % 2 == 0) {
                [room setPrefersColorScheme:WhitePrefersColorSchemeDark];
            } else {
                [room setPrefersColorScheme:WhitePrefersColorSchemeLight];
            }
            cCount += 1;
        },
        @"Apple Pencil": ^(WhiteRoom* room) {
            onlyApplePencil = !onlyApplePencil;
            [room setDrawOnlyApplePencil:onlyApplePencil];
        }
    };
}

@end
