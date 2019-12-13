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
@property (nonatomic, weak) WhitePlayer *player;

@end

typedef NS_ENUM(NSInteger, CommandType) {
    CommandTypePlay,
    CommandTypePause,
    CommondTypeStop,
    CommandTypeSeek,
    CommandTypeInfo,
};

@implementation PlayerCommandListController

- (instancetype)initWithPlayer:(WhitePlayer *)player
{
    if (self = [self init]) {
        _player = player;
    }
    return self;
}
static NSString *kReuseCell = @"reuseCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    self.commands = @[NSLocalizedString(@"播放", nil), NSLocalizedString(@"暂停", nil), NSLocalizedString(@"停止", nil),  NSLocalizedString(@"快进", nil), NSLocalizedString(@"获取信息", nil)];
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
            [self.player play];
            break;
        case CommandTypePause:
            [self.player pause];
            break;
        case CommondTypeStop:
            [self.player stop];
            break;
        case CommandTypeSeek:
        {
            //seek后，保持原始状态
            [self.player seekToScheduleTime:0];
            [self.player play];
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
    [self.player getPlayerTimeInfoWithResult:^(WhitePlayerTimeInfo * _Nonnull info) {
        NSLog(@"%@", info);
    }];
}

- (void)getPlayerState
{
    [self.player getPlayerStateWithResult:^(WhitePlayerState * _Nonnull state) {
        NSLog(@"%@", state);
    }];
}


@end
