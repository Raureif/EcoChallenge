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

#import "FacebookController.h"
#import "ScoreListViewCell.h"
#import "ScoreListViewController.h"


@interface ScoreListViewController ()

@property (nonatomic, assign) ScoreListViewControllerType type;
@property (nonatomic, assign) ScoreListViewControllerState state;
@property (nonatomic, assign) NSUInteger section;
@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, copy) NSArray *privateFriends;
@property (nonatomic, retain) UIWebView *webView;
@property (nonatomic, copy) NSString *themeIdent;
@property (nonatomic, copy) NSString *challengeIdent;
@property (nonatomic, copy) NSString *statsText;

- (void)refreshOnScreenCells;
- (void)setupCell:(ScoreListViewCell *)cell atRow:(NSUInteger)row;

@end


#pragma mark -


@implementation ScoreListViewController

@synthesize type;
@synthesize state;
@synthesize section;
@synthesize tableView;
@synthesize privateFriends;
@synthesize challengeIdents;
@synthesize backgroundTexture;
@synthesize backgroundFill;
@synthesize unitText;
@synthesize chartsLabel;
@synthesize worldwideChallengesLabel;
@synthesize webView;
@synthesize themeIdent;
@synthesize challengeIdent;
@synthesize statsText;


- (void)setChallengeIdents:(NSArray *)aChallengeIdents {
    if (challengeIdents != aChallengeIdents) {
        [challengeIdents release];
        challengeIdents = [aChallengeIdents copy];
        [self refreshOnScreenCells];
    }
}


- (void)setBackgroundTexture:(UIImage *)aBackground {
    if (backgroundTexture != aBackground) {
        [backgroundTexture release];
        backgroundTexture = [aBackground retain];
        [self refreshOnScreenCells];
    }
}


- (id)init:(ScoreListViewControllerType)aScoreViewControllerType theme:(Theme *)theme challenge:(Challenge *)challenge tableView:(UITableView *)aTableView section:(NSUInteger)aSection {
    if ((self = [super init])) {
        self.type = aScoreViewControllerType;
        self.themeIdent = theme.ident;
        self.challengeIdent = challenge.ident;
        self.statsText = challenge.statsText;
        self.tableView = aTableView;
        self.section = aSection;

        // Create WebKit.
        if (self.type == ScoreListViewControllerTypeChallenge) {
            self.webView = [[[UIWebView alloc] init] autorelease];
            self.webView.dataDetectorTypes = UIDataDetectorTypeNone;
            self.webView.userInteractionEnabled = NO;
            self.webView.delegate = self;
            // We would like to set
            //   self.webView.scrollsToTop = NO;
            // here but Steve does not allow this.
        }
    }
    return self;
}


- (UITableViewCell *)cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *const CellIdentifier = @"ScoreListViewCell";

    // Try to re-use ScoreListViewCell object.
    ScoreListViewCell *cell = (ScoreListViewCell *)[self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[ScoreListViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }

    // Initialize cell.
    [self setupCell:cell atRow:indexPath.row];

    return cell;
}


- (NSInteger)numberOfRowsInSection {
    if (self.type == ScoreListViewControllerTypeChallenge) {
        return 1;
    } else if (self.state == ScoreListViewControllerStateNormal) {
        return self.privateFriends.count;
    } else if (self.state == ScoreListViewControllerStateLogin) {
        return 2;
    } else {
        return 1;
    }
}


- (CGFloat)heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.type == ScoreListViewControllerTypeChallenge && self.webView.frame.size.height > 1) {
        return self.webView.frame.size.height + 16;
    } else {
        return [ScoreListViewCell cellHeight];
    }
}


- (void)scrollViewDidEndDragging:(BOOL)decelerate {
    // Load face images for currently displayed cells.
    if (!decelerate) {
        [self refreshOnScreenCells];
    }
}


- (void)scrollViewDidEndDecelerating {
    // Load face images for currently displayed cells.
    [self refreshOnScreenCells];
}


- (void)viewWillAppear:(BOOL)animated {
    [[Scores sharedInstance] setDelegate:self themeIdent:self.themeIdent];
    [FacebookImageDownloader sharedInstance].delegate = self;
}


- (void)viewWillDisappear:(BOOL)animated {
    [FacebookImageDownloader sharedInstance].delegate = nil;
    [Scores sharedInstance].delegate = nil;
}


- (void)refreshOnScreenCells {
    for (NSIndexPath *indexPath in [self.tableView indexPathsForVisibleRows]) {
        if (indexPath.section == self.section) {
            ScoreListViewCell *cell = (ScoreListViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
            [self setupCell:cell atRow:indexPath.row];
        }
    }
}


- (void)setupCell:(ScoreListViewCell *)cell atRow:(NSUInteger)row {
    cell.backgroundTexture = self.backgroundTexture;
    cell.backgroundFill = self.backgroundFill;
    cell.sideOffset = (self.type == ScoreListViewControllerTypeChallenge ? 14 : 10);
    cell.webView = nil;

    // Initialize cell according to type and current state.
    switch (self.state) {

        case ScoreListViewControllerStateLogin:
            if (row == 0) {
                cell.type = ScoreListViewCellTypeSpoiler;
                cell.roundedCornersOnTop = YES;
                cell.roundedCornersOnBottom = NO;
                cell.separatorLine = NO;
            } else {
                cell.type = ScoreListViewCellTypeLogin;
                cell.roundedCornersOnTop = NO;
                cell.roundedCornersOnBottom = YES;
                cell.separatorLine = NO;
            }
            break;

        case ScoreListViewControllerStateWaiting:
            cell.type = ScoreListViewCellTypeWaiting;
            cell.roundedCornersOnTop = YES;
            cell.roundedCornersOnBottom = YES;
            cell.separatorLine = NO;
            break;

        case ScoreListViewControllerStateError:
            cell.type = ScoreListViewCellTypeError;
            cell.roundedCornersOnTop = YES;
            cell.roundedCornersOnBottom = YES;
            cell.separatorLine = NO;
            break;

        case ScoreListViewControllerStateNoFriends:
            cell.type = ScoreListViewCellTypeNoFriends;
            cell.roundedCornersOnTop = YES;
            cell.roundedCornersOnBottom = YES;
            cell.separatorLine = NO;
            break;

        case ScoreListViewControllerStateNormal:
             switch (self.type) {

                case ScoreListViewControllerTypeChallengeList:
                    cell.type = ScoreListViewCellTypeChallengeList;

                    if (self.privateFriends.count == 1) {
                        cell.roundedCornersOnTop = YES;
                        cell.roundedCornersOnBottom = YES;
                        cell.separatorLine = NO;
                    } else if (row == 0) {
                        cell.roundedCornersOnTop = YES;
                        cell.roundedCornersOnBottom = NO;
                        cell.separatorLine = YES;
                    } else if (row == self.privateFriends.count - 1) {
                        cell.roundedCornersOnTop = NO;
                        cell.roundedCornersOnBottom = YES;
                        cell.separatorLine = NO;
                    } else {
                        cell.roundedCornersOnTop = NO;
                        cell.roundedCornersOnBottom = NO;
                        cell.separatorLine = YES;
                    }         NSDictionary *friend = [self.privateFriends objectAtIndex:row];
                    if ((self.tableView.dragging == NO && self.tableView.decelerating == NO)) {
                        cell.photo = [[FacebookImageDownloader sharedInstance] getImage:[friend objectForKey:@"id"]];
                    } else {
                        cell.photo = [[FacebookImageDownloader sharedInstance] getCachedImage:[friend objectForKey:@"id"]];
                    }
                    cell.name = [friend objectForKey:@"firstName"];
                    // Look up scores of friends.
                    NSDictionary *scores = [friend objectForKey:@"scores"];
                    NSMutableArray *values = [NSMutableArray arrayWithCapacity:self.challengeIdents.count];
                    for (NSUInteger i = 0; i < self.challengeIdents.count; i++) {
                        NSNumber *completion = [scores objectForKey:[self.challengeIdents objectAtIndex:i]];
                        if (completion && [completion doubleValue] > 0.0) {
                            [values addObject:[NSNumber numberWithBool:YES]];
                        } else {
                            [values addObject:[NSNumber numberWithBool:NO]];
                        }
                    }
                    cell.values = values;
                    break;

                case ScoreListViewControllerTypeChallenge: {
                    if (self.webView.frame.size.height <= 1) {
                        cell.type = ScoreListViewCellTypeWaiting;
                    } else {
                        cell.type = ScoreListViewCellTypeChallenge;
                        // Embed WebKit into cell.
                        cell.webView = self.webView;
                    }
                    cell.roundedCornersOnTop = YES;
                    cell.roundedCornersOnBottom = YES;
                    cell.separatorLine = NO;
                    break;
                }

                case ScoreListViewControllerTypeAchievements: {
                    cell.type = ScoreListViewCellTypeAchievement;
                    cell.separatorLine = (row != self.privateFriends.count - 1);
                    friend = [self.privateFriends objectAtIndex:row];
                    if ((self.tableView.dragging == NO && self.tableView.decelerating == NO)) {
                        cell.photo = [[FacebookImageDownloader sharedInstance] getImage:[friend objectForKey:@"id"]];
                    } else {
                        cell.photo = [[FacebookImageDownloader sharedInstance] getCachedImage:[friend objectForKey:@"id"]];
                    }
                    cell.name = [friend objectForKey:@"firstName"];
                    // Look up scores of friends.
                    scores = [friend objectForKey:@"scores"];
                    cell.values = [NSArray arrayWithObjects:
                                   [NSNumber numberWithUnsignedInt:(row + 1)],
                                   [NSNumber numberWithUnsignedInt:[[scores objectForKey:@"accomplished"] unsignedIntValue]],
                                   nil];
                    // Use striped background for local user.
                    if ([[friend objectForKey:@"id"] isEqualToString:[FacebookController sharedInstance].facebookID]) {
                        cell.backgroundFill = [UIColor colorWithPatternImage:[UIImage imageNamed:@"erfolg-ich-pattern.png"]];
                    }
                    break;
                }

                case ScoreListViewControllerTypeCalculator:
                    cell.type = ScoreListViewCellTypeCalculator;
                    if (self.privateFriends.count == 1) {
                        cell.roundedCornersOnTop = YES;
                        cell.roundedCornersOnBottom = YES;
                        cell.separatorLine = NO;
                    } else if (row == 0) {
                        cell.roundedCornersOnTop = YES;
                        cell.roundedCornersOnBottom = NO;
                        cell.separatorLine = YES;
                    } else if (row == self.privateFriends.count - 1) {
                        cell.roundedCornersOnTop = NO;
                        cell.roundedCornersOnBottom = YES;
                        cell.separatorLine = NO;
                    } else {
                        cell.roundedCornersOnTop = NO;
                        cell.roundedCornersOnBottom = NO;
                        cell.separatorLine = YES;
                    }
                    friend = [self.privateFriends objectAtIndex:row];
                    if ((self.tableView.dragging == NO && self.tableView.decelerating == NO)) {
                        cell.photo = [[FacebookImageDownloader sharedInstance] getImage:[friend objectForKey:@"id"]];
                    } else {
                        cell.photo = [[FacebookImageDownloader sharedInstance] getCachedImage:[friend objectForKey:@"id"]];
                    }
                    cell.name = [friend objectForKey:@"firstName"];
                    // Look up calculator results of friends.
                    NSArray *results = [[friend objectForKey:@"scores"] objectForKey:self.themeIdent];
                    if ([results count] == 2) {
                        cell.values = [NSArray arrayWithObjects:[results objectAtIndex:0], [results objectAtIndex:1], (self.unitText ? self.unitText : @""), nil];
                    } else {
                        cell.values = [NSArray arrayWithObjects:[NSNumber numberWithUnsignedInt:0], [NSNumber numberWithUnsignedInt:0], (self.unitText ? self.unitText : @""), nil];
                    }
                    break;

            }
            break;
    }

    // Modify rounded corners for achievements view.
    if (self.type == ScoreListViewControllerTypeAchievements) {
        cell.roundedCornersOnTop = NO;
        cell.roundedCornersOnBottom = NO;
    }
}


#pragma mark -
#pragma mark Score Protocol


- (void)newScoreStatus:(BOOL)isFacebookLoggedIn
         facebookError:(BOOL)cannotDownloadFacebookFriends
                 error:(BOOL)cannotDownloadScore
              progress:(BOOL)isDownloadingScore
               friends:(NSArray *)friends
   worldwideChallenges:(NSUInteger)worldwideChallenges {

    NSUInteger oldRowCount = [self numberOfRowsInSection];

    // Store private copy of friend list.
    self.privateFriends = friends;

    // Set new state.
    switch (self.type) {

        case ScoreListViewControllerTypeChallengeList:
        case ScoreListViewControllerTypeAchievements:
        case ScoreListViewControllerTypeCalculator:
            if (isFacebookLoggedIn == NO) {
                self.state = ScoreListViewControllerStateLogin;
            } else if (cannotDownloadFacebookFriends || cannotDownloadScore) {
                self.state = ScoreListViewControllerStateError;
            } else if (isDownloadingScore) {
                self.state = ScoreListViewControllerStateWaiting;
            } else if (friends.count == 0) {
                self.state = ScoreListViewControllerStateNoFriends;
            } else {
                self.state = ScoreListViewControllerStateNormal;
            }
            break;

        case ScoreListViewControllerTypeChallenge:
            if (cannotDownloadScore) {
                self.state = ScoreListViewControllerStateError;
            } else if (isDownloadingScore) {
                self.state = ScoreListViewControllerStateWaiting;
            } else {
                self.state = ScoreListViewControllerStateNormal;

                // Resize WebKit to minimum size. In theory a height of 0 would be used here, but the WebKit render engine would freak out.
                self.webView.frame = CGRectMake(22, 8, 276, 1);

                NSMutableString *html = [NSMutableString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"score" ofType:@"tmpl"] encoding:NSUTF8StringEncoding error:NULL];

                NSArray *array = [[Scores sharedInstance].challenges objectForKey:self.challengeIdent];
                NSUInteger participants = (array ? [[array objectAtIndex:0] unsignedIntValue] : 0);
                NSUInteger items = (array ? [[array objectAtIndex:1] unsignedIntValue] : 0);

                if (participants > 0 && items > 0) {
                    // Show chalkboard.
                    if (items > 90) {
                        [html appendString:@"    <div class=\"chalk90plus\"></div>\n"];
                    } else {
                        for (NSUInteger i = 0; i < items / 5; i++) {
                            [html appendString:@"    <div class=\"chalk5\"></div>\n"];
                        }
                        if (items % 5 > 0) {
                            [html appendFormat:@"    <div class=\"chalk%u\"></div>\n", items % 5];
                        }
                    }

                    // Show global statistics.
                    [html appendString:@"    <div id=\"text\">\n      "];
                    [html appendFormat:self.statsText, participants, items];

                    // Look up friends.
                    NSMutableArray *firstNames = [NSMutableArray arrayWithCapacity:[self.privateFriends count]];
                    for (NSDictionary *friend in self.privateFriends) {
                        NSNumber *completion = [[friend objectForKey:@"scores"] objectForKey:self.challengeIdent];
                        if (completion && [completion doubleValue] > 0.0) {
                            [firstNames addObject:[friend objectForKey:@"firstName"]];
                        }
                    }

                    if ([firstNames count] > 0) {
                        for (NSUInteger i = 0; i < [firstNames count]; i++) {
                            if (i == 0) {
                                [html appendString:NSLocalizedString(@"Scores.AmongstOthers", @"Continue sentence.")];
                            } else if (i == [firstNames count] - 1) {
                                [html appendString:NSLocalizedString(@"Scores.And", @"Enumeration of friends.")];
                            } else {
                                [html appendString:@", "];
                            }
                            [html appendFormat:@"<b>%@</b>", [firstNames objectAtIndex:i]];
                        }
                    }
                    [html appendString:@".\n</div>\n"];
                } else {
                    [html appendFormat:@"    <div id=\"text\">\n%@\n    \n</div>\n", NSLocalizedString(@"Scores.NoParticipants", @"No participants.")];
                }
                [html appendString:@"  </html>\n</body>\n"];

                [self.webView loadHTMLString:html baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath] isDirectory:YES]];
            }
            break;
    }

    if (self.type == ScoreListViewControllerTypeAchievements && self.state == ScoreListViewControllerStateNormal) {
        // Add local user to friend list.
        NSMutableArray *mutableFriends = [[friends mutableCopy] autorelease];
        NSDictionary *myself = [NSDictionary dictionaryWithObjectsAndKeys:
                                [FacebookController sharedInstance].facebookID,      @"id",
                                NSLocalizedString(@"Scores.Myself", @"Myself."),     @"firstName",
                                [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInt:[[Scores sharedInstance] accomplishedChallengeCount]]
                                                            forKey:@"accomplished"], @"scores",
                                nil];
        [mutableFriends addObject:myself];

        // Sort friend list by number of accomplished challenges.
        NSSortDescriptor *sortDescriptor1 = [[[NSSortDescriptor alloc] initWithKey:@"scores.accomplished" ascending:NO] autorelease];
        NSSortDescriptor *sortDescriptor2 = [[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES] autorelease];
        NSSortDescriptor *sortDescriptor3 = [[[NSSortDescriptor alloc] initWithKey:@"id" ascending:YES] autorelease];
        self.privateFriends = [mutableFriends sortedArrayUsingDescriptors:[NSArray arrayWithObjects:sortDescriptor1, sortDescriptor2, sortDescriptor3, nil]];

        // Set text of UILabel.
        self.chartsLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Achievements.Charts", @"Charts."),
                                 [self.privateFriends indexOfObject:myself] + 1,
                                 [self.privateFriends count]];
    }
    if (self.type == ScoreListViewControllerTypeAchievements) {
        // Set text of UILabel.
        NSNumberFormatter *formatter = [[[NSNumberFormatter alloc] init] autorelease];
        // Remove the next line as soon as the application becomes localized.
        formatter.locale = [[[NSLocale alloc] initWithLocaleIdentifier:@"de_DE"] autorelease];
        [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
        self.worldwideChallengesLabel.text = [formatter stringForObjectValue:[NSNumber numberWithUnsignedInt:worldwideChallenges]];
    }

    NSUInteger newRowCount = [self numberOfRowsInSection];

    // Update table view.
    [self.tableView beginUpdates];

    if (oldRowCount > newRowCount) {

        // Remove superfluous cells.
        NSUInteger count = oldRowCount - newRowCount;
        NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:count];
        for (NSUInteger i = 0; i < count; i++) {
            [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:self.section]];
        }
        [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];

    } else if (oldRowCount < newRowCount) {

        // Add new cells.
        NSUInteger count = newRowCount - oldRowCount;
        NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:count];
        for (NSUInteger i = 0; i < count; i++) {
            [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:self.section]];
        }
        [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
    }

    [self.tableView endUpdates];
    [self.tableView beginUpdates];

    // Update all existing cells.
    [self refreshOnScreenCells];

    [self.tableView endUpdates];
}


#pragma mark -
#pragma mark FacebookImageDownloader protocol


- (void)downloadedFacebookImage:(NSString *)facebookID {
    // Look for friend with this Facebook ID.
    for (NSUInteger i = 0; i < self.privateFriends.count; i++) {
        NSDictionary *friend = [self.privateFriends objectAtIndex:i];
        if ([[friend objectForKey:@"id"] isEqualToString:facebookID]) {
            // Update associated cell.
            ScoreListViewCell *cell = (ScoreListViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:self.section]];
            [self setupCell:cell atRow:i];
            break;
        }
    }
}


#pragma mark -
#pragma mark UIWebView delegate


- (void)webViewDidFinishLoad:(UIWebView *)webView {
    // Modify WebKit background color.
    CGFloat const *components = CGColorGetComponents(self.backgroundFill.CGColor);
    [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.body.style.backgroundColor = '#%02x%02x%02x';",
                                                          (int)(components[0] * 255), (int)(components[1] * 255), (int)(components[2] * 255)]];

    // Resize WebKit to fit page height.
    CGRect newFrame = self.webView.frame;
    newFrame.size.height = [[self.webView stringByEvaluatingJavaScriptFromString:@"document.body.scrollHeight"] intValue];
    self.webView.frame = newFrame;

    // Update all existing cells.
    [self.tableView beginUpdates];
    [self refreshOnScreenCells];
    [self.tableView endUpdates];
}


#pragma mark -
#pragma mark NSObject


- (void)dealloc {
    self.tableView = nil;
    self.privateFriends = nil;
    self.challengeIdents = nil;
    self.backgroundTexture = nil;
    self.backgroundFill = nil;
    self.unitText = nil;
    self.chartsLabel = nil;
    self.worldwideChallengesLabel = nil;
    self.webView.delegate = nil;
    self.webView = nil;
    self.themeIdent = nil;
    self.challengeIdent = nil;
    self.statsText = nil;
    [super dealloc];
}


@end
