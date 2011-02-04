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
#import "Challenges.h"
#import "ChallengeAcceptCell.h"
#import "ScoreListViewController.h"


@interface ChallengeListViewController: UIViewController <UITableViewDataSource, UITableViewDelegate, ChallengesProtocol> {
    UITableView *tableView;
    ChallengeAcceptCell *acceptCell;
    UITableViewCell *middleCell;
    UITableViewCell *bottomCell;
    UIView *middleCellBackgroundView;
    UIView *bottomCellBackgroundView;
    UILabel *facebookLabel;
    Challenges *challenges;
    NSArray *privateChallenges;
    ScoreListViewController *scoreListViewController;
}

@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) IBOutlet ChallengeAcceptCell *acceptCell;
@property (nonatomic, retain) IBOutlet UITableViewCell *middleCell;
@property (nonatomic, retain) IBOutlet UITableViewCell *bottomCell;
@property (nonatomic, retain) IBOutlet UIView *middleCellBackgroundView;
@property (nonatomic, retain) IBOutlet UIView *bottomCellBackgroundView;
@property (nonatomic, retain) IBOutlet UILabel *facebookLabel;

- (id)initWithTheme:(Theme *)theme;

@end
