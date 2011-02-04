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

#import "MainViewController.h"
#import "ScoreReporter.h"
#import "DrawUtils.h"
#import "ChallengeListViewCell.h"
#import "ChallengeListViewController.h"


/* The UITableView consists of five different sections:
 *
 *   0 = acceptCell
 *   1 = ChallengeListViewCells
 *   2 = middleCell
 *   3 = ScoreListViewCells
 *   4 = bottomCell
 *
 * The ScoreListViewCells are fully handled in the ScoreListViewController.
 */


@interface ChallengeListViewController ()

@property (nonatomic, retain) Challenges *challenges;
@property (nonatomic, copy) NSArray *privateChallenges;
@property (nonatomic, retain) ScoreListViewController *scoreListViewController;

- (void)setupCell:(ChallengeListViewCell *)cell withChallenge:(Challenge *)challenge;

@end


#pragma mark -


@implementation ChallengeListViewController

@synthesize tableView;
@synthesize acceptCell;
@synthesize middleCell;
@synthesize bottomCell;
@synthesize middleCellBackgroundView;
@synthesize bottomCellBackgroundView;
@synthesize facebookLabel;
@synthesize challenges;
@synthesize privateChallenges;
@synthesize scoreListViewController;



// Designated initializer.
- (id)initWithTheme:(Theme *)theme {
    if ((self = [super initWithNibName:@"ChallengeListView" bundle:nil])) {
        self.challenges = [[[Challenges alloc] initWithTheme:theme] autorelease];

        // Force loading of view.
        [self view];

        // Create Score view controller.
        self.scoreListViewController = [[[ScoreListViewController alloc] init:ScoreListViewControllerTypeChallengeList theme:theme challenge:nil tableView:self.tableView section:3] autorelease];
        self.scoreListViewController.backgroundTexture = [UIImage imageNamed:@"gray-fill.png"];
        self.scoreListViewController.backgroundFill = [UIColor colorWithWhite:0.165 alpha:1];
    }
    return self;
}


- (void)setupCell:(ChallengeListViewCell *)cell withChallenge:(Challenge *)challenge {
    cell.individualDateRange = challenge.individualDateRange;
    cell.globalDateRange = challenge.globalDateRange;
    cell.title = challenge.title;
    cell.gradient = challenge.themeGradient;
    cell.color = challenge.themeColor;
    cell.activeIcon = challenge.activeIcon;
    cell.doneIcon = challenge.doneIcon;
    cell.challengeState = challenge.state;
    cell.challengeNum = challenge.challengeNum;
}


#pragma mark -
#pragma mark UITableView data source


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *const CellIdentifier = @"ChallengeListViewCell";

    switch (indexPath.section) {
        case 0:
            return self.acceptCell;
        case 1: {

            // Try to re-use ChallengeListViewCell object.
            ChallengeListViewCell *cell = (ChallengeListViewCell *)[self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil) {
                cell = [[[ChallengeListViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
            }

            // Initialize cell.
            Challenge *challenge = [self.privateChallenges objectAtIndex:indexPath.row];
            [self setupCell:cell withChallenge:challenge];

            return cell;
        }
        case 2:
            return middleCell;
        case 3:
            return [self.scoreListViewController cellForRowAtIndexPath:indexPath];
        case 4:
            return self.bottomCell;
        default:
            NSAssert(NO, @"Unexpected switch case.");
            return nil;
    }
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 5;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
        case 2:
        case 4:
            return 1;
        case 1:
            return self.privateChallenges.count;
        case 3:
            return [self.scoreListViewController numberOfRowsInSection];
        default:
            NSAssert(NO, @"Unexpected switch case.");
            return 0;
    }
}


#pragma mark -
#pragma mark UITableView delegate


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1) {
        Challenge *challenge = [self.privateChallenges objectAtIndex:indexPath.row];
        if (challenge.state != ChallengeStateTeaser) {
            [[MainViewController sharedInstance] slideInChallengeView:self.challenges challenge:challenge];
        }
    }
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0:
            return self.acceptCell.bounds.size.height;
        case 1:
            return [ChallengeListViewCell cellHeight];
        case 2:
            return self.middleCell.bounds.size.height;
        case 3:
            return [self.scoreListViewController heightForRowAtIndexPath:indexPath];
        case 4:
            return self.bottomCell.bounds.size.height;
        default:
            NSAssert(NO, @"Unexpected switch case.");
            return 0;
    }
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
#pragma mark Challenges protocol


- (void)refreshChallengeList:(NSArray *)challengeList {
    // Store private copy of theme list.
    self.privateChallenges = challengeList;

    NSMutableArray *challengeIdents = [NSMutableArray arrayWithCapacity:self.privateChallenges.count];

    // Refresh all challenge cells.
    for (NSUInteger i = 0; i < self.privateChallenges.count; i++) {
        Challenge *challenge = [self.privateChallenges objectAtIndex:i];
        ChallengeListViewCell *cell = (ChallengeListViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:1]];
        [self setupCell:cell withChallenge:challenge];

        [challengeIdents addObject:challenge.ident];
    }

    // Refresh checkmarks in Facebook friends list.
    self.scoreListViewController.challengeIdents = challengeIdents;

    // Refresh text nearby accept challenges switch.
    acceptCell.challenges = self.challenges;
}


#pragma mark -
#pragma mark UIViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Background fill pattern.
    self.middleCellBackgroundView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"gray-fill.png"]];
    self.bottomCellBackgroundView.backgroundColor = self.middleCellBackgroundView.backgroundColor;
    // Use fancy fonts.
    self.facebookLabel.font = selectFont(Camingo_14);
    // Localize.
    self.facebookLabel.text = NSLocalizedString(@"Facebook.FriendsProgress", @"Progress of friends.");
    // Hide challenge accepted switch if the challenges have already been accepted.
    self.acceptCell.writeProtection = (self.challenges.accepted > 0);
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.challenges.delegate = self;
    [self.scoreListViewController viewWillAppear:animated];
}


- (void)viewWillDisappear:(BOOL)animated {
    [self.scoreListViewController viewWillDisappear:animated];
    self.challenges.delegate = nil;
    [super viewWillDisappear:animated];
}


- (void)viewDidUnload {
    // Finally report to server that the user accepted the challenges.
    [self.acceptCell mayReportAcceptedChallengesToServer];
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
    self.tableView = nil;
    self.acceptCell = nil;
    self.middleCell = nil;
    self.bottomCell = nil;
    self.middleCellBackgroundView = nil;
    self.bottomCellBackgroundView = nil;
    self.facebookLabel = nil;
    [super viewDidUnload];
}


#pragma mark -
#pragma mark NSObject


- (void)dealloc {
    [self viewDidUnload];
    self.challenges = nil;
    self.privateChallenges = nil;
    self.scoreListViewController = nil;
    [super dealloc];
}


@end
