//
// EcoChallenge.
// Copyright (c) 2010-2011 Raureif GmbH. All rights reserved.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

#import "Theme.h"
#import "Challenge.h"
#import "Scores.h"
#import "FacebookImageDownloader.h"


typedef enum {
    ScoreListViewControllerTypeChallengeList,
    ScoreListViewControllerTypeChallenge,
    ScoreListViewControllerTypeAchievements,
    ScoreListViewControllerTypeCalculator
} ScoreListViewControllerType;


typedef enum {
    ScoreListViewControllerStateLogin,
    ScoreListViewControllerStateWaiting,
    ScoreListViewControllerStateError,
    ScoreListViewControllerStateNoFriends,
    ScoreListViewControllerStateNormal
} ScoreListViewControllerState;


#pragma mark -


@interface ScoreListViewController: NSObject <ScoresProtocol, FacebookImageDownloaderProtocol, UIWebViewDelegate> {
    ScoreListViewControllerType type;
    ScoreListViewControllerState state;
    UITableView *tableView;
    NSUInteger section;
    NSArray *privateFriends;
    NSArray *challengeIdents;
    UIImage *backgroundTexture;
    UIColor *backgroundFill;
    NSString *unitText;
    UILabel *chartsLabel;
    UILabel *worldwideChallengesLabel;
    UIWebView *webView;
    NSString *themeIdent;
    NSString *challengeIdent;
    NSString *statsText;
}

@property (nonatomic, copy) NSArray *challengeIdents;
@property (nonatomic, retain) UIImage *backgroundTexture;
@property (nonatomic, retain) UIColor *backgroundFill;
@property (nonatomic, copy) NSString *unitText;
@property (nonatomic, retain) UILabel *chartsLabel;
@property (nonatomic, retain) UILabel *worldwideChallengesLabel;

- (id)init:(ScoreListViewControllerType)aScoreViewControllerType theme:(Theme *)theme challenge:(Challenge *)challenge tableView:(UITableView *)aTableView section:(NSUInteger)aSection;
- (UITableViewCell *)cellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (NSInteger)numberOfRowsInSection;
- (CGFloat)heightForRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)scrollViewDidEndDragging:(BOOL)decelerate;
- (void)scrollViewDidEndDecelerating;
- (void)viewWillAppear:(BOOL)animated;
- (void)viewWillDisappear:(BOOL)animated;

@end
