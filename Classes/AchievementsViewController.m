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

#import "Themes.h"
#import "Challenges.h"
#import "Scores.h"
#import "DrawUtils.h"
#import "MainViewController.h"
#import "AchievementsViewController.h"


@interface AchievementsViewController ()

@property (nonatomic, retain) ScoreListViewController *scoreListViewController;

@end


#pragma mark -


@implementation AchievementsViewController

@synthesize tableView;
@synthesize badge0;
@synthesize badge1;
@synthesize badge2;
@synthesize badge3;
@synthesize badge4;
@synthesize gameCenterButton;
@synthesize barChartView;
@synthesize achievementsLabel;
@synthesize noAchievementsLabel;
@synthesize numberOfChallengesLabel;
@synthesize challengesLabel;
@synthesize rankingLabel;
@synthesize chartsLabel;
@synthesize worldwideLabel;
@synthesize worldwideChallengesLabel;
@synthesize scoreListViewController;


- (IBAction)showGameCenter:(id)sender {
    GKAchievementViewController *achievementsViewController = [[GKAchievementViewController alloc] init];
    achievementsViewController.achievementDelegate = self;
    [[MainViewController sharedInstance] presentModalViewController:achievementsViewController animated:YES];
    [achievementsViewController release];
}


#pragma mark -
#pragma mark GKAchievementViewControllerDelegate


- (void)achievementViewControllerDidFinish:(GKAchievementViewController *)viewController {
    [[MainViewController sharedInstance] dismissModalViewControllerAnimated:YES];
}


#pragma mark -
#pragma mark UITableView data source


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self.scoreListViewController cellForRowAtIndexPath:indexPath];
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.scoreListViewController numberOfRowsInSection];
}


#pragma mark -
#pragma mark UITableView delegate


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self.scoreListViewController heightForRowAtIndexPath:indexPath];
}


#pragma mark -
#pragma mark UIScrollView delegate


- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    [self.scoreListViewController scrollViewDidEndDragging:decelerate];
}


- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self.scoreListViewController scrollViewDidEndDecelerating];
}


#pragma mark -
#pragma mark UIViewController


- (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)nibBundle {
    if ((self = [super initWithNibName:nibName bundle:nibBundle])) {
        // Force loading of view.
        [self view];

        // Create Score view controller.
        self.scoreListViewController = [[[ScoreListViewController alloc] init:ScoreListViewControllerTypeAchievements theme:nil challenge:nil tableView:self.tableView section:0] autorelease];
        self.scoreListViewController.backgroundFill = [UIColor colorWithWhite:0.165 alpha:1];
        self.scoreListViewController.chartsLabel = self.chartsLabel;
        self.scoreListViewController.worldwideChallengesLabel = self.worldwideChallengesLabel;
    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];

    // Use fancy fonts.
    self.achievementsLabel.font = selectFont(Camingo_Bold_20);
    self.noAchievementsLabel.font = selectFont(Camingo_Italic_14);
    self.challengesLabel.font = selectFont(Camingo_14);
    self.rankingLabel.font = selectFont(Camingo_Bold_20);
    self.chartsLabel.font = selectFont(Camingo_Italic_14);
    self.worldwideLabel.font = selectFont(Camingo_Italic_14);
    self.worldwideChallengesLabel.font = selectFont(Camingo_Bold_17);
    if ([UIFont fontWithName:@"RooneyEco-Bold" size:24]) {
        // Do not use Georgia as a fallback font here because numbers are not aligned.
        self.numberOfChallengesLabel.font = [UIFont fontWithName:@"RooneyEco-Bold" size:24];
    }

    // Localize.
    self.achievementsLabel.text = NSLocalizedString(@"AchievementsView.Achievements", @"Achievements.");
    self.noAchievementsLabel.text = NSLocalizedString(@"AchievementsView.NoAchievements", @"There are no achievements.");
    self.challengesLabel.text = NSLocalizedString(@"AchievementsView.Challenges", @"Challenges.");
    self.rankingLabel.text = NSLocalizedString(@"AchievementsView.Ranking", @"Ranking.");
    self.worldwideLabel.text = NSLocalizedString(@"AchievementsView.WorldwideChallenges", @"Worldwide accomplished challenges.");

    // Get number of challenges and achievement badges.
    NSMutableArray *achievements = [NSMutableArray arrayWithCapacity:5];
    for (Theme *theme in [Themes sharedInstance].themes) {
        if ([[Scores sharedInstance] isThemeAccomplished:theme]) {
            UIImage *badge = [[[[Challenges alloc] initWithTheme:theme] autorelease] badge];
            if (badge) {
                [achievements addObject:badge];
            }
        }
    }

    // Show achievement badges.
    NSArray *badges = [NSArray arrayWithObjects:self.badge0, self.badge1, self.badge2, self.badge3, self.badge4, nil];
    for (NSUInteger i = 0; i < MIN([badges count], [achievements count]); i++) {
        [[badges objectAtIndex:(MIN([badges count], [achievements count]) - 1 - i)] setImage:[achievements objectAtIndex:i]];
    }
    if ([achievements count] > 0) {
        self.noAchievementsLabel.hidden = YES;
    }

    // Show number of challenges.
    NSUInteger accomplishedChallengeCount = [[Scores sharedInstance] accomplishedChallengeCount];
    NSUInteger acceptedChallengeCount = [[Scores sharedInstance] acceptedChallengeCount];
    self.numberOfChallengesLabel.text = [NSString stringWithFormat:@"%u/%u", accomplishedChallengeCount, acceptedChallengeCount];

    // Create bar chart.
    CGRect rect = self.barChartView.bounds;
    if (UIGraphicsBeginImageContextWithOptions != NULL) {
        UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    } else {
        UIGraphicsBeginImageContext(rect.size);
    }
    addRoundedRectToPath(UIGraphicsGetCurrentContext(), rect, 3, 3);
    CGContextClip(UIGraphicsGetCurrentContext());
    rect.size.width *= (CGFloat)accomplishedChallengeCount / (CGFloat)acceptedChallengeCount;
    rect.size.height = 8;
    [[UIColor colorWithWhite:0.9 alpha:1] set];
    CGContextFillRect(UIGraphicsGetCurrentContext(), rect);
    rect.origin.y = rect.size.height;
    rect.size.height = 7;
    [[UIColor colorWithWhite:0.7 alpha:1] set];
    CGContextFillRect(UIGraphicsGetCurrentContext(), rect);
    self.barChartView.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    // Test if Game Center is available, as documented by Apple.
    self.gameCenterButton.hidden = !(NSClassFromString(@"GKLocalPlayer") && [[[UIDevice currentDevice] systemVersion] compare:@"4.1" options:NSNumericSearch] != NSOrderedAscending);
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.scoreListViewController viewWillAppear:animated];
}


- (void)viewWillDisappear:(BOOL)animated {
    [self.scoreListViewController viewWillDisappear:animated];
    [super viewWillDisappear:animated];
}


- (void)viewDidUnload {
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
    self.tableView = nil;
    self.badge0 = nil;
    self.badge1 = nil;
    self.badge2 = nil;
    self.badge3 = nil;
    self.badge4 = nil;
    self.gameCenterButton = nil;
    self.barChartView = nil;
    self.achievementsLabel = nil;
    self.noAchievementsLabel = nil;
    self.numberOfChallengesLabel = nil;
    self.challengesLabel = nil;
    self.rankingLabel = nil;
    self.chartsLabel = nil;
    self.worldwideLabel = nil;
    self.worldwideChallengesLabel = nil;
    [super viewDidUnload];
}


#pragma mark -
#pragma mark NSObject


- (void)dealloc {
    [self viewDidUnload];
    self.scoreListViewController.chartsLabel = nil;
    self.scoreListViewController.worldwideChallengesLabel = nil;
    self.scoreListViewController = nil;
    [super dealloc];
}


@end
