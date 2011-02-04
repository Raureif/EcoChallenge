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

#import "ScoreListViewController.h"


@interface AchievementsViewController: UIViewController <GKAchievementViewControllerDelegate, UITableViewDataSource, UITableViewDelegate> {
    UITableView *tableView;
    ScoreListViewController *scoreListViewController;
    UIImageView *badge0;
    UIImageView *badge1;
    UIImageView *badge2;
    UIImageView *badge3;
    UIImageView *badge4;
    UIButton *gameCenterButton;
    UIImageView *barChartView;
    UILabel *achievementsLabel;
    UILabel *noAchievementsLabel;
    UILabel *numberOfChallengesLabel;
    UILabel *challengesLabel;
    UILabel *rankingLabel;
    UILabel *chartsLabel;
    UILabel *worldwideLabel;
    UILabel *worldwideChallengesLabel;
}

@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) IBOutlet UIImageView *badge0;
@property (nonatomic, retain) IBOutlet UIImageView *badge1;
@property (nonatomic, retain) IBOutlet UIImageView *badge2;
@property (nonatomic, retain) IBOutlet UIImageView *badge3;
@property (nonatomic, retain) IBOutlet UIImageView *badge4;
@property (nonatomic, retain) IBOutlet UIButton *gameCenterButton;
@property (nonatomic, retain) IBOutlet UIImageView *barChartView;
@property (nonatomic, retain) IBOutlet UILabel *achievementsLabel;
@property (nonatomic, retain) IBOutlet UILabel *noAchievementsLabel;
@property (nonatomic, retain) IBOutlet UILabel *numberOfChallengesLabel;
@property (nonatomic, retain) IBOutlet UILabel *challengesLabel;
@property (nonatomic, retain) IBOutlet UILabel *rankingLabel;
@property (nonatomic, retain) IBOutlet UILabel *chartsLabel;
@property (nonatomic, retain) IBOutlet UILabel *worldwideLabel;
@property (nonatomic, retain) IBOutlet UILabel *worldwideChallengesLabel;

- (IBAction)showGameCenter:(id)sender;

@end
