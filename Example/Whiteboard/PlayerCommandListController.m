//
//  PlayerCommandListController.m
//  WhiteSDKPrivate_Example
//
//  Created by yleaf on 2019/3/15.
//  Copyright © 2019 leavesster. All rights reserved.
//

#import "PlayerCommandListController.h"

@interface PlayerCommandListController ()

@property (nonatomic, strong) NSArray<NSString *> *commands;
@property (nonatomic, weak) WhiteCombinePlayer *combinePlayer;

@end

typedef NS_ENUM(NSInteger, CommandType) {
    CommandTypePlay,
    CommandTypePause,
    CommondTypeSpeed,
    CommandTypeSeek,
    CommandTypeObserver,
    CommandTypeInfo,
};

@implementation PlayerCommandListController

- (instancetype)initWithPlayer:(WhiteCombinePlayer *)player
{
    if (self = [self init]) {
        _combinePlayer = player;
    }
    return self;
}
static NSString *kReuseCell = @"reuseCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    self.commands = @[NSLocalizedString(@"播放", nil), NSLocalizedString(@"暂停", nil), NSLocalizedString(@"加速", nil),  NSLocalizedString(@"快进", nil), NSLocalizedString(@"观察模式", nil), NSLocalizedString(@"获取信息", nil)];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kReuseCell];
}


- (CGSize)preferredContentSize
{
    return CGSizeMake(150, MIN(self.commands.count, 6) * 44);
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
        case CommandTypePlay:
            [self.combinePlayer play];
            break;
        case CommandTypePause:
            [self.combinePlayer pause];
            break;
        case CommondTypeSpeed:
            self.combinePlayer.playbackSpeed = 1.25;
            break;
        case CommandTypeSeek:
        {
            //快进至5s位置，参数分别为 对应秒数，1秒内频率，Apple推荐为600，此处为演示随意填写。
            CMTime time = CMTimeMakeWithSeconds(5, 100);
            [self.combinePlayer seekToTime:time completionHandler:^(BOOL finished) {
                [self.combinePlayer play];
            }];
            break;
        }
        case CommandTypeObserver:
        {
            [self.combinePlayer.whitePlayer setObserverMode:WhiteObserverModeFreedom];
            break;
        }
        case CommandTypeInfo:
        {
            [self getAPI];
            break;
        }
        default:
            break;
    }
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}


- (void)getAPI
{
    [self getPlayerState];
    [self getPlayerTimeInfo];
}

- (void)getPlayerTimeInfo
{
    [self.combinePlayer.whitePlayer getPlayerTimeInfoWithResult:^(WhitePlayerTimeInfo * _Nonnull info) {
        NSLog(@"%@", info);
    }];
    [self.combinePlayer.whitePlayer getPlaybackSpeed:^(CGFloat speed) {
        NSLog(@"%f", speed);
    }];
}

- (void)getPlayerState
{
    [self.combinePlayer.whitePlayer getPlayerStateWithResult:^(WhitePlayerState * _Nonnull state) {
        NSLog(@"%@", state);
    }];
}


@end
