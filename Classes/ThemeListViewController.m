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
#import "Scores.h"
#import "ScoreReporter.h"
#import "DrawUtils.h"
#import "MainViewController.h"
#import "ThemeListViewCell.h"
#import "ThemeListViewController.h"


/* The UITableView consists of three different sections:
 *
 *   0 = topCell
 *   1 = ThemeListViewCells
 *   2 = creditsCell0
 *   3 = creditsCell1
 *   4 = creditsCell2
 *   5 = creditsCell3
 */


@interface ThemeListViewController ()

@property (nonatomic, copy) NSArray *privateThemes;

- (void)setupCell:(ThemeListViewCell *)cell withTheme:(Theme *)theme animated:(BOOL)animated;
- (void)setupCellWithTheme:(Theme *)theme;

@end


#pragma mark -


@implementation ThemeListViewController

@synthesize tableView;
@synthesize topCell;
@synthesize creditsCell0;
@synthesize creditsCell1;
@synthesize creditsCell2;
@synthesize creditsCell3;
@synthesize backgroundView;
@synthesize aboutLabel;
@synthesize fhpLabel;
@synthesize mwfkLabel;
@synthesize raureifLabel;
@synthesize managementLabel1;
@synthesize managementLabel2;
@synthesize thanksLabel1;
@synthesize thanksLabel2;
@synthesize fontsLabel1;
@synthesize fontsLabel2;
@synthesize thirdPartyLabel1;
@synthesize thirdPartyLabel2;
@synthesize licenseLabel;
@synthesize facebookLabel1;
@synthesize facebookLabel2;
@synthesize facebookLabel3;
@synthesize tutorialLabel1;
@synthesize tutorialLabel2;
@synthesize sendIdLabel1;
@synthesize sendIdLabel2;
@synthesize facebookButton;
@synthesize tutorialSwitch;
@synthesize debugView;
@synthesize privateThemes;


- (IBAction)checkForUpdatesNow:(id)sender {
    // For debugging only: Force update check.
    [[Themes sharedInstance] checkForUpdatesNow];
}


- (IBAction)showHomepage:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.eco-challenge.eu/"]];
}


- (IBAction)showLicence:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://eco-challenge.eu/gpl"]];
}


- (IBAction)showSourceCode:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/raureif/ecochallenge"]];
}


- (IBAction)facebookConnect:(id)sender {
    if ([FacebookController sharedInstance].isLoggedIn) {
        [[FacebookController sharedInstance] logout];
    } else {
        [[FacebookController sharedInstance] login];
    }
}


- (IBAction)changeTutorialSetting:(id)sender {
    // Save tutorial setting.
    [[NSUserDefaults standardUserDefaults] setBool:(!self.tutorialSwitch.on) forKey:@"didShowHelp"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


- (IBAction)sendId:(id)sender {
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mailComposeViewController = [[MFMailComposeViewController alloc] init];
        mailComposeViewController.mailComposeDelegate = self;
        [mailComposeViewController setToRecipients:[NSArray arrayWithObject:NSLocalizedString(@"Mail.ID.Receiver", @"Send ID receiver.")]];
        [mailComposeViewController setSubject:NSLocalizedString(@"Mail.ID.Subject", @"Send ID subject.")];
        [mailComposeViewController setMessageBody:[NSString stringWithFormat:NSLocalizedString(@"Mail.ID.Body", @"Send ID body."), [[ScoreReporter sharedInstance] deviceId]] isHTML:NO];
        [[MainViewController sharedInstance] presentModalViewController:mailComposeViewController animated:YES];
        [mailComposeViewController release];
    }   
}


- (void)setupCell:(ThemeListViewCell *)cell withTheme:(Theme *)theme animated:(BOOL)animated {
    // Get challenge success.

    if (theme.state == ThemeStateReady) {
        NSMutableArray *successfulChallenges = [NSMutableArray arrayWithCapacity:2];
        NSMutableArray *expiredChallenges = [NSMutableArray arrayWithCapacity:2];
        NSUInteger challengeCount = 0;
        Challenges *challenges = [[Challenges alloc] initWithTheme:theme];
        for (Challenge *challenge in challenges.challenges) {
            if (challenge.state == ChallengeStateExpired) {
                [expiredChallenges addObject:[NSNumber numberWithBool:NO]];
                [successfulChallenges addObject:[NSNumber numberWithBool:[[Scores sharedInstance] isChallengeAccomplished:challenge.ident]]];
            } else {
                [successfulChallenges addObject:[NSNumber numberWithBool:[[Scores sharedInstance] isChallengeAccomplished:challenge.ident]]];
            }
            challengeCount++;
        }
        [challenges release];
        if ([expiredChallenges count] == challengeCount) {
            cell.challenges = expiredChallenges;
            cell.isExpired = YES;
        } else {
            cell.challenges = successfulChallenges;
            cell.isExpired = NO;            
        }
    } else {
        cell.challenges = nil;
        cell.isExpired = NO;
    }

    cell.dateRange = theme.dateRange;
    cell.title = theme.title;
    cell.error = theme.error;
    cell.gradient = theme.gradient;
    cell.progress = theme.progress;
    [cell setThemeState:theme.state animated:animated];
}


- (void)setupCellWithTheme:(Theme *)theme {
    // Lookup index of theme object in array.
    NSUInteger index = [self.privateThemes indexOfObject:theme];
    NSAssert(index != NSNotFound, @"Theme not found.");
    if (index != NSNotFound) {

        // Lookup cell object for theme index.
        ThemeListViewCell *cell = (ThemeListViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:1]];
        if (cell) {
            // Propagate new state and (optionally) resize cell.
            [self.tableView beginUpdates];
            [self setupCell:cell withTheme:theme animated:YES];
            [self.tableView endUpdates];
        }
    }
}


#pragma mark -
#pragma mark UITableView data source


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *const CellIdentifier = @"ThemeListViewCell";

    switch (indexPath.section) {
        case 0:
            return topCell;
        case 1: {

            // Try to re-use ThemeListViewCell object.
            ThemeListViewCell *cell = (ThemeListViewCell *)[self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil) {
                cell = [[[ThemeListViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
            }

            // Initialize cell.
            Theme *theme = [self.privateThemes objectAtIndex:indexPath.row];
            [self setupCell:cell withTheme:theme animated:NO];

            return cell;
        }
        case 2:
            return self.creditsCell0;
        case 3:
            return self.creditsCell1;
        case 4:
            return self.creditsCell2;
        case 5:
            return self.creditsCell3;
        default:
            NSAssert(NO, @"Unexpected switch case.");
            return nil;
    }
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 6;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
        case 2:
        case 3:
        case 4:
        case 5:
            return 1;
        case 1:
            return self.privateThemes.count;
        default:
            NSAssert(NO, @"Unexpected switch case.");
            return 0;
    }
}


#pragma mark -
#pragma mark UITableView delegate


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1) {
        ThemeListViewCell *cell = (ThemeListViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
        if (cell) {
            Theme *theme = [self.privateThemes objectAtIndex:indexPath.row];
            if (theme.state == ThemeStateReady) {
                // Return to main screen.
                [[MainViewController sharedInstance] didSelectTheme:theme];
            } else if (theme.state == ThemeStateOnServer || theme.state == ThemeStateDownloadFailed) {
                // Download theme content.
                [[ThemeDownloader sharedInstance] downloadTheme:theme];
            } else if (theme.state == ThemeStateDownloading) {
                // Cancel theme content download.
                [[ThemeDownloader sharedInstance] cancelThemeDownload:theme];
            }
        }
    }
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0:
            return self.topCell.bounds.size.height;
        case 1: {
            // Calculate height of cell.
            Theme *theme = [self.privateThemes objectAtIndex:indexPath.row];
            return [ThemeListViewCell cellHeightForThemeState:theme.state];
        }
        case 2:
            return self.creditsCell0.bounds.size.height;
        case 3:
            return self.creditsCell1.bounds.size.height;
        case 4:
            return self.creditsCell2.bounds.size.height;
        case 5:
            return self.creditsCell3.bounds.size.height;
        default:
            NSAssert(NO, @"Unexpected switch case.");
            return 0;
    }
}


- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    // Set background fill pattern.
    switch (indexPath.section) {
        case 0:
        case 1:
        case 5:
            break;
        case 2:
        case 3:
        case 4:
            cell.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bgr-1.png"]];
            break;
        default:
            NSAssert(NO, @"Unexpected switch case.");
    }
}


#pragma mark -
#pragma mark MFMailComposeViewController delegate


- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    [controller dismissModalViewControllerAnimated:YES];
}


#pragma mark -
#pragma mark Themes protocol


- (void)refreshThemeList:(NSArray *)themeList {
    // Store private copy of theme list.
    NSUInteger oldThemesCount = self.privateThemes.count;
    self.privateThemes = themeList;

    // Update table view.
    [self.tableView beginUpdates];

    if (oldThemesCount > self.privateThemes.count) {

        // Remove superfluous cells. Usually this does not happen.
        NSUInteger count = oldThemesCount - self.privateThemes.count;
        NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:count];
        for (NSUInteger i = 0; i < count; i++) {
            [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:1]];
        }
        [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];

    } else if (oldThemesCount < self.privateThemes.count) {

        // Add new cells.
        NSUInteger count = self.privateThemes.count - oldThemesCount;
        NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:count];
        for (NSUInteger i = 0; i < count; i++) {
            [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:1]];
        }
        [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
    }

    [self.tableView endUpdates];
    [self.tableView beginUpdates];

    // Update all existing cells.
    for (NSUInteger i = 0; i < self.privateThemes.count; i++) {
        Theme *theme = [self.privateThemes objectAtIndex:i];
        ThemeListViewCell *cell = (ThemeListViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:1]];
        [self setupCell:cell withTheme:theme animated:YES];
    }

    [self.tableView endUpdates];
}


#pragma mark -
#pragma mark ThemeDownloader protocol


- (void)themeStateChanged:(Theme *)theme {
    // Lookup index of theme object in array.
    NSUInteger index = [self.privateThemes indexOfObject:theme];
    if (index != NSNotFound) {
        // Propagate theme state and resize cell.
        [self setupCellWithTheme:theme];
    }
}


#pragma mark -
#pragma mark Facebook Protocol


- (void)newFacebookStatus:(BOOL)isLoggedIn
                    error:(BOOL)cannotDownloadFriends
                 progress:(BOOL)isDownloadingFriends
                  friends:(NSDictionary *)friends {
    // Change labels and button according to login state.
    if (isLoggedIn) {
        self.facebookLabel1.text = NSLocalizedString(@"Facebook.Disconnect1", @"Disconnect from Facebook.");
        self.facebookLabel2.text = NSLocalizedString(@"Facebook.Disconnect2", @"Disconnect from Facebook.");
        self.facebookLabel3.text = NSLocalizedString(@"Facebook.Disconnect3", @"Disconnect from Facebook.");
        [self.facebookButton setImage:[UIImage imageNamed:@"button-fb-deactivate-default.png"] forState:UIControlStateNormal];
        [self.facebookButton setImage:[UIImage imageNamed:@"button-fb-deactivate-highlight.png"] forState:UIControlStateHighlighted];
    } else {
        self.facebookLabel1.text = NSLocalizedString(@"Facebook.NotActivated1", @"Facebook is not activated.");
        self.facebookLabel2.text = NSLocalizedString(@"Facebook.NotActivated2", @"Facebook is not activated.");
        self.facebookLabel3.text = NSLocalizedString(@"Facebook.NotActivated3", @"Facebook is not activated.");
        [self.facebookButton setImage:[UIImage imageNamed:@"button-fb-activate-default.png"] forState:UIControlStateNormal];
        [self.facebookButton setImage:[UIImage imageNamed:@"button-fb-activate-highlight.png"] forState:UIControlStateHighlighted];
    }
}


#pragma mark -
#pragma mark UIViewController


- (void)viewDidLoad {
    [super viewDidLoad];
#ifdef DEBUG
    self.debugView.hidden = NO;
#endif

    // Set background fill pattern.
    self.backgroundView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bgr-2.png"]];

    // Use fancy fonts.
    self.aboutLabel.font = selectFont(Rooney_14);
    self.fhpLabel.font = selectFont(Camingo_Italic_14);
    self.mwfkLabel.font = selectFont(Camingo_Italic_14);
    self.raureifLabel.font = selectFont(Camingo_Italic_14);
    self.managementLabel1.font = selectFont(Camingo_Italic_14);
    self.managementLabel2.font = selectFont(Rooney_14);
    self.thanksLabel1.font = selectFont(Camingo_Italic_14);
    self.thanksLabel2.font = selectFont(Rooney_14);
    self.fontsLabel1.font = selectFont(Camingo_Italic_14);
    self.fontsLabel2.font = selectFont(Rooney_14);
    self.thirdPartyLabel1.font = selectFont(Camingo_Italic_14);
    self.thirdPartyLabel2.font = selectFont(Rooney_14);
    self.licenseLabel.font = selectFont(Camingo_14);
    self.facebookLabel1.font = selectFont(Camingo_Bold_14);
    self.facebookLabel2.font = selectFont(Camingo_Italic_14);
    self.facebookLabel3.font = selectFont(Camingo_Italic_14);
    self.tutorialLabel1.font = selectFont(Camingo_Bold_14);
    self.tutorialLabel2.font = selectFont(Camingo_Italic_14);
    self.sendIdLabel1.font = selectFont(Camingo_Bold_14);
    self.sendIdLabel2.font = selectFont(Camingo_Italic_14);
    
    // Localize.
    self.aboutLabel.text = NSLocalizedString(@"Credits.EcoChallenge", @"About EcoChallenge.");
    self.fhpLabel.text = NSLocalizedString(@"Credits.FHP", @"A project of FHP.");
    self.mwfkLabel.text = NSLocalizedString(@"Credits.MWFK", @"Sponsored by MWFK.");
    self.raureifLabel.text = NSLocalizedString(@"Credits.Raureif", @"Developed by Raureif.");
    self.managementLabel1.text = NSLocalizedString(@"Credits.Management1", @"Management.");
    self.managementLabel2.text = NSLocalizedString(@"Credits.Management2", @"Management.");
    self.thanksLabel1.text = NSLocalizedString(@"Credits.Thanks1", @"Thanks.");
    self.thanksLabel2.text = NSLocalizedString(@"Credits.Thanks2", @"Thanks.");
    self.fontsLabel1.text = NSLocalizedString(@"Credits.Fonts1", @"Fonts.");
    self.fontsLabel2.text = NSLocalizedString(@"Credits.Fonts2", @"Fonts.");
    self.thirdPartyLabel1.text = NSLocalizedString(@"Credits.ThirdParty1", @"Third party code.");
    self.thirdPartyLabel2.text = NSLocalizedString(@"Credits.ThirdParty2", @"Third party code.");
    self.licenseLabel.text = NSLocalizedString(@"Credits.License", @"License.");
    self.tutorialLabel1.text = NSLocalizedString(@"Tutorial.Show1", @"Show tutorial.");
    self.tutorialLabel2.text = NSLocalizedString(@"Tutorial.Show2", @"Show tutorial.");
    self.sendIdLabel1.text = NSLocalizedString(@"ID.Send1", @"Send ID.");
    self.sendIdLabel2.text = [NSString stringWithFormat:NSLocalizedString(@"ID.Send2", @"Send ID."), [[ScoreReporter sharedInstance] deviceId]];
    
    // Set tutorial switch state.
    self.tutorialSwitch.on = ([[NSUserDefaults standardUserDefaults] boolForKey:@"didShowHelp"] == NO);
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [Themes sharedInstance].delegate = self;
    [ThemeDownloader sharedInstance].delegate = self;
    [FacebookController sharedInstance].delegate = self;
}


- (void)viewWillDisappear:(BOOL)animated {
    [FacebookController sharedInstance].delegate = nil;
    [ThemeDownloader sharedInstance].delegate = nil;
    [Themes sharedInstance].delegate = nil;
    [super viewWillDisappear:animated];
}


- (void)viewDidUnload {
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
    self.tableView = nil;
    self.topCell = nil;
    self.creditsCell0 = nil;
    self.creditsCell1 = nil;
    self.creditsCell2 = nil;
    self.creditsCell3 = nil;
    self.backgroundView = nil;
    self.aboutLabel = nil;
    self.fhpLabel = nil;
    self.mwfkLabel = nil;
    self.raureifLabel = nil;
    self.managementLabel1 = nil;
    self.managementLabel2 = nil;
    self.thanksLabel1 = nil;
    self.thanksLabel2 = nil;
    self.fontsLabel1 = nil;
    self.fontsLabel2 = nil;
    self.thirdPartyLabel1 = nil;
    self.thirdPartyLabel2 = nil;
    self.licenseLabel = nil;
    self.facebookLabel1 = nil;
    self.facebookLabel2 = nil;
    self.facebookLabel3 = nil;
    self.tutorialLabel1 = nil;
    self.tutorialLabel2 = nil;
    self.sendIdLabel1 = nil;
    self.sendIdLabel2 = nil;
    self.facebookButton = nil;
    self.tutorialSwitch = nil;
    self.debugView = nil;
    [super viewDidUnload];
}


#pragma mark -
#pragma mark NSObject


- (void)dealloc {
    [self viewDidUnload];
    self.privateThemes = nil;
    [super dealloc];
}


@end
