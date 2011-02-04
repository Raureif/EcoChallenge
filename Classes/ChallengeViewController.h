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
#import "Challenges.h"
#import "CupView.h"
#import "SpinView.h"
#import "SwitchView.h"
#import "ChallengeAcceptCell.h"
#import "ChallengeRecommendationCell.h"
#import "ScoreListViewController.h"


@interface ChallengeViewController: UIViewController <UITableViewDataSource, UITableViewDelegate, ChallengesProtocol> {
    UITableView *tableView;
    ChallengeAcceptCell *acceptCell;
    UITableViewCell *topCell;
    UITableViewCell *questionCell;
    ChallengeRecommendationCell *recommendationCell;
    UITableViewCell *bottomCell;
    UIImageView *topCellBackgroundView;
    UIImageView *bottomCellBackgroundView;
    UIButton *backButton;
    UILabel *remainingDaysLabel;
    UIImageView *headerView;
    UIView *stripeView;
    UILabel *titleLabel;
    UILabel *descriptionLabel;
    UILabel *doneLabel;
    UILabel *questionLabel;
    UIView *multibuttonArea;
    UIView *switchArea;
    UIView *spinArea;
    CupView *cupView;
    UIButton *multibutton0;
    UIButton *multibutton1;
    UIButton *multibutton2;
    UIButton *multibutton3;
    UIButton *multibutton4;
    UIButton *multibutton5;
    SpinView *spinView;
    UIButton *spinUpButton;
    UIButton *spinDownButton;
    SwitchView *switchView;
    Challenge *challenge;
    Challenges *challenges;
    UIImage *patternImage;
    UIColor *pattern;
    ScoreListViewController *scoreListViewController;
    BOOL alwaysHideAcceptCell;
}

- (id)initWithTheme:(Theme *)theme challenges:(Challenges *)aChallenges challenge:(Challenge *)aChallenge;

@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) IBOutlet ChallengeAcceptCell *acceptCell;
@property (nonatomic, retain) IBOutlet UITableViewCell *topCell;
@property (nonatomic, retain) IBOutlet UITableViewCell *questionCell;
@property (nonatomic, retain) IBOutlet ChallengeRecommendationCell *recommendationCell;
@property (nonatomic, retain) IBOutlet UITableViewCell *bottomCell;
@property (nonatomic, retain) IBOutlet UIImageView *topCellBackgroundView;
@property (nonatomic, retain) IBOutlet UIImageView *bottomCellBackgroundView;
@property (nonatomic, retain) IBOutlet UIButton *backButton;
@property (nonatomic, retain) IBOutlet UILabel *remainingDaysLabel;
@property (nonatomic, retain) IBOutlet UIImageView *headerView;
@property (nonatomic, retain) IBOutlet UIView *stripeView;
@property (nonatomic, retain) IBOutlet UILabel *titleLabel;
@property (nonatomic, retain) IBOutlet UILabel *descriptionLabel;
@property (nonatomic, retain) IBOutlet UILabel *doneLabel;
@property (nonatomic, retain) IBOutlet UILabel *questionLabel;
@property (nonatomic, retain) IBOutlet UIView *multibuttonArea;
@property (nonatomic, retain) IBOutlet UIView *switchArea;
@property (nonatomic, retain) IBOutlet UIView *spinArea;
@property (nonatomic, retain) IBOutlet CupView *cupView;
@property (nonatomic, retain) IBOutlet UIButton *multibutton0;
@property (nonatomic, retain) IBOutlet UIButton *multibutton1;
@property (nonatomic, retain) IBOutlet UIButton *multibutton2;
@property (nonatomic, retain) IBOutlet UIButton *multibutton3;
@property (nonatomic, retain) IBOutlet UIButton *multibutton4;
@property (nonatomic, retain) IBOutlet UIButton *multibutton5;
@property (nonatomic, retain) IBOutlet SpinView *spinView;
@property (nonatomic, retain) IBOutlet UIButton *spinUpButton;
@property (nonatomic, retain) IBOutlet UIButton *spinDownButton;
@property (nonatomic, retain) IBOutlet SwitchView *switchView;

- (IBAction)slideOutChallengeView:(id)sender;
- (IBAction)changeMultibutton:(id)sender;
- (IBAction)changeSwitch:(id)sender;
- (IBAction)spinUp:(id)sender;
- (IBAction)spinDown:(id)sender;

@end
