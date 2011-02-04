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

#import "DrawUtils.h"
#import "Realtime.h"
#import "MainViewController.h"
#import "ChallengeViewController.h"


/* The UITableView consists of three different sections:
 *
 *   0 = acceptCell
 *   1 = topCell
 *   2 = questionCell
 *   3 = recommendationCell
 *   4 = ScoreListViewCells
 *   5 = bottomCell
 *
 * The ScoreListViewCells are fully handled in the ScoreListViewController.
 */


@interface ChallengeViewController ()

@property (nonatomic, retain) Challenge *challenge;
@property (nonatomic, retain) Challenges *challenges;
@property (nonatomic, retain) UIImage *patternImage;
@property (nonatomic, retain) UIColor *pattern;
@property (nonatomic, retain) ScoreListViewController *scoreListViewController;
@property (nonatomic, assign) BOOL alwaysHideAcceptCell;

- (void)setupQuestionWidgets;

@end


#pragma mark -


@implementation ChallengeViewController

@synthesize tableView;
@synthesize acceptCell;
@synthesize topCell;
@synthesize questionCell;
@synthesize recommendationCell;
@synthesize bottomCell;
@synthesize topCellBackgroundView;
@synthesize bottomCellBackgroundView;
@synthesize backButton;
@synthesize remainingDaysLabel;
@synthesize headerView;
@synthesize stripeView;
@synthesize titleLabel;
@synthesize descriptionLabel;
@synthesize doneLabel;
@synthesize questionLabel;
@synthesize multibuttonArea;
@synthesize spinArea;
@synthesize switchArea;
@synthesize cupView;
@synthesize multibutton0;
@synthesize multibutton1;
@synthesize multibutton2;
@synthesize multibutton3;
@synthesize multibutton4;
@synthesize multibutton5;
@synthesize spinView;
@synthesize spinUpButton;
@synthesize spinDownButton;
@synthesize switchView;
@synthesize challenge;
@synthesize challenges;
@synthesize patternImage;
@synthesize pattern;
@synthesize scoreListViewController;
@synthesize alwaysHideAcceptCell;


// Designated initializer.
- (id)initWithTheme:(Theme *)theme challenges:(Challenges *)aChallenges challenge:(Challenge *)aChallenge {
    if ((self = [super initWithNibName:@"ChallengeView" bundle:nil])) {
        self.challenge = aChallenge;
        self.challenges = aChallenges;

        // Create background fill pattern.
        UIImage *background = [UIImage imageNamed:@"gray-fill.png"];
        CGRect rect = CGRectMake(0, 0, background.size.width, background.size.height);
        if (UIGraphicsBeginImageContextWithOptions != NULL) {
            UIGraphicsBeginImageContextWithOptions(rect.size, YES, 0);
        } else {
            UIGraphicsBeginImageContext(rect.size);
        }
        CGContextDrawTiledImage(UIGraphicsGetCurrentContext(),
                                CGRectMake(0, 0, background.size.width, background.size.height),
                                background.CGImage);
        rect.origin.x += 10;
        rect.size.width -= 20;
        [self.challenge.themeGradient.toColor set];
        CGContextFillRect(UIGraphicsGetCurrentContext(), rect);
        self.patternImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        self.pattern = [UIColor colorWithPatternImage:patternImage];

        // Force loading of view.
        [self view];

        // Create Score view controller.
        self.scoreListViewController = [[[ScoreListViewController alloc] init:ScoreListViewControllerTypeChallenge theme:theme challenge:aChallenge tableView:self.tableView section:4] autorelease];
        self.scoreListViewController.backgroundTexture = self.patternImage;
        self.scoreListViewController.backgroundFill = self.challenge.themeColor;

        // Setup widgets for question.
        [self setupQuestionWidgets];
    }
    return self;
}


- (IBAction)slideOutChallengeView:(id)sender {
    [[MainViewController sharedInstance] slideOutChallengeView:sender];
}


- (IBAction)changeMultibutton:(id)sender {
    [self.acceptCell mayReportAcceptedChallengesToServer];

    // Get existing values.
    NSMutableArray *values = [[[[[Scores sharedInstance].scores objectForKey:@"challenges"] objectForKey:self.challenge.ident] mutableCopy] autorelease];
    if (values == nil) {
        values = [NSMutableArray arrayWithCapacity:2 + [self.challenge.multibutton count]];
    }
    // Fill array if necessary.
    for (NSUInteger i = [values count]; i < 2 + [self.challenge.multibutton count]; i++) {
        [values addObject:[NSNumber numberWithUnsignedInt:0]];
    }
    // Toggle flag for individual button.
    [values replaceObjectAtIndex:2 + [sender tag] withObject:([[values objectAtIndex:2 + [sender tag]] unsignedIntValue] == 0 ? [NSNumber numberWithUnsignedInt:1] : [NSNumber numberWithUnsignedInt:0])];
    // Sum up number of pressed buttons.
    NSUInteger sum = 0;
    for (NSUInteger i = 2; i < 2 + [self.challenge.multibutton count]; i++) {
        sum += [[values objectAtIndex:i] unsignedIntValue];
    }
    [values replaceObjectAtIndex:1 withObject:[NSNumber numberWithUnsignedInt:sum]];
    // Check if challenge has been accomplished.
    [values replaceObjectAtIndex:0 withObject:(sum == [self.challenge.multibutton count] ? [NSNumber numberWithUnsignedInt:1] : [NSNumber numberWithUnsignedInt:0])];

    // Save new score.
    [[Scores sharedInstance] reportScore:self.challenge.ident values:values];

    // Set button state.
    [self setupQuestionWidgets];
}


- (IBAction)changeSwitch:(id)sender {
    [self.acceptCell mayReportAcceptedChallengesToServer];

    // Get existing values.
    NSMutableArray *values = [[[[[Scores sharedInstance].scores objectForKey:@"challenges"] objectForKey:self.challenge.ident] mutableCopy] autorelease];
    if (values == nil) {
        values = [NSMutableArray arrayWithCapacity:3];
    }
    // Fill array if necessary.
    for (NSUInteger i = [values count]; i < 3; i++) {
        [values addObject:[NSNumber numberWithUnsignedInt:0]];
    }
    // Increment value.
    [values replaceObjectAtIndex:1 withObject:[NSNumber numberWithUnsignedInt:self.switchView.on]];
    [values replaceObjectAtIndex:2 withObject:[NSNumber numberWithUnsignedInt:self.switchView.on]];
    // Check if challenge has been accomplished.
    [values replaceObjectAtIndex:0 withObject:[NSNumber numberWithUnsignedInt:self.switchView.on]];

    // Save new score.
    [[Scores sharedInstance] reportScore:self.challenge.ident values:values];

    // Set spin state.
    [self setupQuestionWidgets];
}


- (IBAction)spinUp:(id)sender {
    [self.acceptCell mayReportAcceptedChallengesToServer];

    // Get existing values.
    NSMutableArray *values = [[[[[Scores sharedInstance].scores objectForKey:@"challenges"] objectForKey:self.challenge.ident] mutableCopy] autorelease];
    if (values == nil) {
        values = [NSMutableArray arrayWithCapacity:3];
    }
    // Fill array if necessary.
    for (NSUInteger i = [values count]; i < 3; i++) {
        [values addObject:[NSNumber numberWithUnsignedInt:0]];
    }
    // Increment value.
    NSUInteger newValue = [[values objectAtIndex:2] unsignedIntValue] + 1;
    [values replaceObjectAtIndex:1 withObject:[NSNumber numberWithUnsignedInt:newValue]];
    [values replaceObjectAtIndex:2 withObject:[NSNumber numberWithUnsignedInt:newValue]];
    // Check if challenge has been accomplished.
    [values replaceObjectAtIndex:0 withObject:(newValue >= self.challenge.spinAccomplished ? [NSNumber numberWithUnsignedInt:1] : [NSNumber numberWithUnsignedInt:0])];

    // Save new score.
    [[Scores sharedInstance] reportScore:self.challenge.ident values:values];

    // Set spin state.
    [self setupQuestionWidgets];
}


- (IBAction)spinDown:(id)sender {
    [self.acceptCell mayReportAcceptedChallengesToServer];

    // Get existing values.
    NSMutableArray *values = [[[[[Scores sharedInstance].scores objectForKey:@"challenges"] objectForKey:self.challenge.ident] mutableCopy] autorelease];
    if (values == nil) {
        values = [NSMutableArray arrayWithCapacity:3];
    }
    // Fill array if necessary.
    for (NSUInteger i = [values count]; i < 3; i++) {
        [values addObject:[NSNumber numberWithUnsignedInt:0]];
    }
    // Decrement value.
    NSUInteger newValue = [[values objectAtIndex:2] unsignedIntValue] - 1;
    [values replaceObjectAtIndex:1 withObject:[NSNumber numberWithUnsignedInt:newValue]];
    [values replaceObjectAtIndex:2 withObject:[NSNumber numberWithUnsignedInt:newValue]];
    // Check if challenge is still accomplished.
    [values replaceObjectAtIndex:0 withObject:(newValue >= self.challenge.spinAccomplished ? [NSNumber numberWithUnsignedInt:1] : [NSNumber numberWithUnsignedInt:0])];

    // Save new score.
    [[Scores sharedInstance] reportScore:self.challenge.ident values:values];

    // Set spin state.
    [self setupQuestionWidgets];
}


- (void)setupQuestionWidgets {
    NSArray *values = [[[Scores sharedInstance].scores objectForKey:@"challenges"] objectForKey:self.challenge.ident];

    switch (self.challenge.questionType) {

        case ChallengeQuestionTypeMultibutton: {
            // Setup multibutton area.
            NSUInteger count = [self.challenge.multibutton count];
            switch (count) {
                case 6:
                    self.multibutton5.hidden = NO;
                    if ([values count] >= 2 + 6 && [[values objectAtIndex:2 + 5] unsignedIntValue]) {
                        [self.multibutton5 setImage:[[self.challenge.multibutton objectAtIndex:5] objectForKey:@"doneIcon"] forState:UIControlStateNormal];
                        [self.multibutton5 setBackgroundImage:[UIImage imageNamed:@"challenge-select-done.png"] forState:UIControlStateNormal];
                        [self.multibutton5 setBackgroundImage:[UIImage imageNamed:@"challenge-select-done-highlight.png"] forState:UIControlStateHighlighted];
                    } else {
                        [self.multibutton5 setImage:[[self.challenge.multibutton objectAtIndex:5] objectForKey:@"activeIcon"] forState:UIControlStateNormal];
                        [self.multibutton5 setBackgroundImage:[UIImage imageNamed:@"challenge-select-default.png"] forState:UIControlStateNormal];
                        [self.multibutton5 setBackgroundImage:[UIImage imageNamed:@"challenge-select-highlight.png"] forState:UIControlStateHighlighted];
                    }
                    /* Fall through. */
                case 5:
                    self.multibutton4.hidden = NO;
                    if ([values count] >= 2 + 5 && [[values objectAtIndex:2 + 4] unsignedIntValue]) {
                        [self.multibutton4 setImage:[[self.challenge.multibutton objectAtIndex:4] objectForKey:@"doneIcon"] forState:UIControlStateNormal];
                        [self.multibutton4 setBackgroundImage:[UIImage imageNamed:@"challenge-select-done.png"] forState:UIControlStateNormal];
                        [self.multibutton4 setBackgroundImage:[UIImage imageNamed:@"challenge-select-done-highlight.png"] forState:UIControlStateHighlighted];
                    } else {
                        [self.multibutton4 setImage:[[self.challenge.multibutton objectAtIndex:4] objectForKey:@"activeIcon"] forState:UIControlStateNormal];
                        [self.multibutton4 setBackgroundImage:[UIImage imageNamed:@"challenge-select-default.png"] forState:UIControlStateNormal];
                        [self.multibutton4 setBackgroundImage:[UIImage imageNamed:@"challenge-select-highlight.png"] forState:UIControlStateHighlighted];
                    }
                    /* Fall through. */
                case 4:
                    self.multibutton3.hidden = NO;
                    if ([values count] >= 2 + 4 && [[values objectAtIndex:2 + 3] unsignedIntValue]) {
                        [self.multibutton3 setImage:[[self.challenge.multibutton objectAtIndex:3] objectForKey:@"doneIcon"] forState:UIControlStateNormal];
                        [self.multibutton3 setBackgroundImage:[UIImage imageNamed:@"challenge-select-done.png"] forState:UIControlStateNormal];
                        [self.multibutton3 setBackgroundImage:[UIImage imageNamed:@"challenge-select-done-highlight.png"] forState:UIControlStateHighlighted];
                    } else {
                        [self.multibutton3 setImage:[[self.challenge.multibutton objectAtIndex:3] objectForKey:@"activeIcon"] forState:UIControlStateNormal];
                        [self.multibutton3 setBackgroundImage:[UIImage imageNamed:@"challenge-select-default.png"] forState:UIControlStateNormal];
                        [self.multibutton3 setBackgroundImage:[UIImage imageNamed:@"challenge-select-highlight.png"] forState:UIControlStateHighlighted];
                    }
                    /* Fall through. */
                case 3:
                    self.multibutton2.hidden = NO;
                    if ([values count] >= 2 + 3 && [[values objectAtIndex:2 + 2] unsignedIntValue]) {
                        [self.multibutton2 setImage:[[self.challenge.multibutton objectAtIndex:2] objectForKey:@"doneIcon"] forState:UIControlStateNormal];
                        [self.multibutton2 setBackgroundImage:[UIImage imageNamed:@"challenge-select-done.png"] forState:UIControlStateNormal];
                        [self.multibutton2 setBackgroundImage:[UIImage imageNamed:@"challenge-select-done-highlight.png"] forState:UIControlStateHighlighted];
                    } else {
                        [self.multibutton2 setImage:[[self.challenge.multibutton objectAtIndex:2] objectForKey:@"activeIcon"] forState:UIControlStateNormal];
                        [self.multibutton2 setBackgroundImage:[UIImage imageNamed:@"challenge-select-default.png"] forState:UIControlStateNormal];
                        [self.multibutton2 setBackgroundImage:[UIImage imageNamed:@"challenge-select-highlight.png"] forState:UIControlStateHighlighted];
                    }
                    /* Fall through. */
                case 2:
                    self.multibutton1.hidden = NO;
                    if ([values count] >= 2 + 2 && [[values objectAtIndex:2 + 1] unsignedIntValue]) {
                        [self.multibutton1 setImage:[[self.challenge.multibutton objectAtIndex:1] objectForKey:@"doneIcon"] forState:UIControlStateNormal];
                        [self.multibutton1 setBackgroundImage:[UIImage imageNamed:@"challenge-select-done.png"] forState:UIControlStateNormal];
                        [self.multibutton1 setBackgroundImage:[UIImage imageNamed:@"challenge-select-done-highlight.png"] forState:UIControlStateHighlighted];
                    } else {
                        [self.multibutton1 setImage:[[self.challenge.multibutton objectAtIndex:1] objectForKey:@"activeIcon"] forState:UIControlStateNormal];
                        [self.multibutton1 setBackgroundImage:[UIImage imageNamed:@"challenge-select-default.png"] forState:UIControlStateNormal];
                        [self.multibutton1 setBackgroundImage:[UIImage imageNamed:@"challenge-select-highlight.png"] forState:UIControlStateHighlighted];
                    }
                    /* Fall through. */
                case 1:
                    self.multibutton0.hidden = NO;
                    if ([values count] >= 2 + 1 && [[values objectAtIndex:2 + 0] unsignedIntValue]) {
                        [self.multibutton0 setImage:[[self.challenge.multibutton objectAtIndex:0] objectForKey:@"doneIcon"] forState:UIControlStateNormal];
                        [self.multibutton0 setBackgroundImage:[UIImage imageNamed:@"challenge-select-done.png"] forState:UIControlStateNormal];
                        [self.multibutton0 setBackgroundImage:[UIImage imageNamed:@"challenge-select-done-highlight.png"] forState:UIControlStateHighlighted];
                    } else {
                        [self.multibutton0 setImage:[[self.challenge.multibutton objectAtIndex:0] objectForKey:@"activeIcon"] forState:UIControlStateNormal];
                        [self.multibutton0 setBackgroundImage:[UIImage imageNamed:@"challenge-select-default.png"] forState:UIControlStateNormal];
                        [self.multibutton0 setBackgroundImage:[UIImage imageNamed:@"challenge-select-highlight.png"] forState:UIControlStateHighlighted];
                    }
            }
            // Sum up number of pressed buttons.
            NSUInteger sum = 0;
            for (NSUInteger i = 2; i < 2 + [self.challenge.multibutton count]; i++) {
                if ([values count] > i) {
                    sum += [[values objectAtIndex:i] unsignedIntValue];
                }
            }
            self.cupView.progress = ((float)sum / (float)[self.challenge.multibutton count]);
            break;
        }

        case ChallengeQuestionTypeSpin: {
            // Setup spin area.
            NSUInteger value = ([values count] >= 3 ? [[values objectAtIndex:2] unsignedIntValue] : 0);
            self.spinView.value = value;
            self.spinDownButton.enabled = (value > 0);
            self.spinUpButton.enabled = (value < self.challenge.spinMax);
            self.cupView.progress = ((float)value / (float)self.challenge.spinAccomplished);
            break;
        }

        case ChallengeQuestionTypeSwitch: {
            // Setup switch area.
            NSUInteger value = ([values count] >= 3 ? [[values objectAtIndex:2] unsignedIntValue] : 0);
            self.switchView.on = (value ? 1 : 0);
            self.cupView.progress = (value ? 1.0 : 0.0);
            break;
        }
    }
}


#pragma mark -
#pragma mark Challenges protocol


- (void)refreshChallengeList:(NSArray *)challengeList {
    if (self.challenge.state == ChallengeStateDone) {
        self.remainingDaysLabel.text = NSLocalizedString(@"Challenge.Done", @"Done.");
    } else if (self.challenge.state == ChallengeStateExpired) {
        self.remainingDaysLabel.text = NSLocalizedString(@"Challenge.Expired", @"Expired.");
    } else if (self.challenge.state == ChallengeStateRunning) {
        // Set remaining days label.
        NSUInteger days = ceilf(([self.challenge.individualDateRange.to timeIntervalSince1970] - [Realtime sharedInstance].timeRef) / 60.0 / 60.0 / 24.0) + 1;
        if (days == 1) {
            self.remainingDaysLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Date.RemainingDay", @"One remaining day.")];
        } else {
            self.remainingDaysLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Date.RemainingDays", @"Number of remaining days."), days];
        }
    } else {
        self.remainingDaysLabel.text = @"";
    }

    // Make widgets inactive if challenge is not running.
    self.stripeView.opaque = YES;
    if (self.challenge.state == ChallengeStateRunning) {
        [[self.stripeView superview] sendSubviewToBack:self.stripeView];
        self.stripeView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"stripes.png"]];
    } else {
        [[self.stripeView superview] bringSubviewToFront:self.stripeView];
        self.stripeView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"stripes-thick.png"]];
    }
    self.stripeView.opaque = NO;

    // Refresh text nearby accept challenges switch.
    self.acceptCell.challenges = self.challenges;
}


#pragma mark -
#pragma mark UITableView data source


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0:
            return self.acceptCell;
        case 1:
            return self.topCell;
        case 2:
            return self.questionCell;
        case 3:
            return self.recommendationCell;
        case 4:
            return [self.scoreListViewController cellForRowAtIndexPath:indexPath];
        case 5:
            return self.bottomCell;
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
        case 1:
        case 2:
        case 3:
        case 4:
            return 1;
        case 5:
            return [self.scoreListViewController numberOfRowsInSection];
        default:
            NSAssert(NO, @"Unexpected switch case.");
            return 0;
    }
}


#pragma mark -
#pragma mark UITableView delegate


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 3) {
        // Show flip view with recommendation.
        [[MainViewController sharedInstance] showFlipView:self.challenge.recommendationURL
                                                    title:NSLocalizedString(@"Challenge.Tip", @"Tip.")
                                          backgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"gray-fill.png"]]
                                                 gradient:self.challenge.themeGradient];
    }
}


- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    // Set background fill pattern.
    if (indexPath.section == 2) {
        cell.backgroundColor = pattern;
    }
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0:
            return (self.alwaysHideAcceptCell ? 11 : self.acceptCell.bounds.size.height);
        case 1:
            return self.topCell.bounds.size.height;
        case 2:
            return self.questionCell.bounds.size.height;
        case 3:
            return self.recommendationCell.bounds.size.height;
        case 4:
            return [self.scoreListViewController heightForRowAtIndexPath:indexPath];
        case 5:
            return self.bottomCell.bounds.size.height;
        default:
            NSAssert(NO, @"Unexpected switch case.");
            return 0;
    }
}


#pragma mark -
#pragma mark UIViewController


- (void)viewDidLoad {
    [super viewDidLoad];

    // Create top cell background. Beware of mirrored Quartz 2D coordinate system.
    CGRect rect = CGRectMake(0, 0, self.topCellBackgroundView.bounds.size.width, self.topCellBackgroundView.bounds.size.height);
    if (UIGraphicsBeginImageContextWithOptions != NULL) {
        UIGraphicsBeginImageContextWithOptions(rect.size, YES, 0);
    } else {
        UIGraphicsBeginImageContext(rect.size);
    }
    UIImage *background = [UIImage imageNamed:@"gray-fill.png"];
    CGContextDrawTiledImage(UIGraphicsGetCurrentContext(),
                            CGRectMake(0, 0, background.size.width, background.size.height),
                            background.CGImage);
    rect.origin.x += 10;
    rect.size.width -= 20;
    drawRoundedGradientRect(rect, 8, 0, self.challenge.themeGradient);
    self.topCellBackgroundView.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    // Setup recommendation cell.
    self.recommendationCell.backgroundTexture = self.patternImage;
    self.recommendationCell.recommendation = self.challenge.recommendation;

    // Create bottom cell background.
    rect = CGRectMake(0, 0, self.bottomCellBackgroundView.bounds.size.width, self.bottomCellBackgroundView.bounds.size.height);
    if (UIGraphicsBeginImageContextWithOptions != NULL) {
        UIGraphicsBeginImageContextWithOptions(rect.size, YES, 0);
    } else {
        UIGraphicsBeginImageContext(rect.size);
    }
    CGContextDrawTiledImage(UIGraphicsGetCurrentContext(),
                            CGRectMake(0, 0, background.size.width, background.size.height),
                            background.CGImage);
    rect.origin.x += 10;
    rect.origin.y += 1;
    rect.size.width -= 20;
    rect.size.height = self.bottomCell.bounds.size.height - 11;
    drawRoundedRect(rect, 0, 8, [UIColor colorWithWhite:0 alpha:0.25]);
    rect.origin.y -= 1;
    drawRoundedRect(rect, 0, 8, self.challenge.themeGradient.toColor);
    self.bottomCellBackgroundView.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    // Set switch background.
    self.switchView.backgroundFill = self.challenge.themeColor;

    // Use fancy fonts.
    self.backButton.titleLabel.font = selectFont(Camingo_14);
    self.remainingDaysLabel.font = selectFont(Camingo_14);
    self.titleLabel.font = selectFont(Rooney_Italic_20);
    self.descriptionLabel.font = selectFont(Rooney_16);
    self.doneLabel.font = selectFont(Camingo_Bold_17);
    self.questionLabel.font = selectFont(Rooney_Italic_14);

    // Localize.
    self.doneLabel.text = NSLocalizedString(@"Challenge.IsDone", @"Done?");
    for (int i = 0; i < 3; i++) {
        UIControlState state = (i == 0 ? UIControlStateNormal : (i == 1 ? UIControlStateHighlighted : UIControlStateDisabled));
        [self.backButton setTitle:NSLocalizedString(@"Challenge.Back", @"Back.") forState:state];
    }

    // Fill in content.
    self.headerView.image = self.challenge.headerImage;
    self.titleLabel.text = self.challenge.title;
    self.descriptionLabel.text = self.challenge.descriptionText;
    self.questionLabel.text = self.challenge.question;

    // Resize top cell to fit text height.
    CGSize size = [self.descriptionLabel.text sizeWithFont:self.descriptionLabel.font constrainedToSize:CGSizeMake(self.descriptionLabel.frame.size.width, MAXFLOAT) lineBreakMode:UILineBreakModeWordWrap];
    CGRect newFrame = self.descriptionLabel.frame;
    newFrame.size.height = size.height;
    self.descriptionLabel.frame = newFrame;
    newFrame = self.topCell.frame;
    newFrame.size.height = self.descriptionLabel.frame.origin.y + self.descriptionLabel.frame.size.height + 15;
    self.topCell.frame = newFrame;

    // Resize question label to fit text height.
    size = [self.questionLabel.text sizeWithFont:self.questionLabel.font constrainedToSize:CGSizeMake(self.questionLabel.frame.size.width, MAXFLOAT) lineBreakMode:UILineBreakModeWordWrap];
    newFrame = self.questionLabel.frame;
    newFrame.size.height = size.height;
    self.questionLabel.frame = newFrame;

    // Show select multibutton, switch or spin buttons according to question type.
    if (challenge.questionType == ChallengeQuestionTypeSwitch) {

        self.switchArea.hidden = NO;

        self.questionLabel.hidden = YES;

        newFrame = self.doneLabel.frame;
        newFrame.origin.y = 11;
        self.doneLabel.frame = newFrame;

        newFrame = self.questionCell.frame;
        newFrame.size.height = self.switchArea.bounds.size.height;
        self.questionCell.frame = newFrame;

    } else {

        newFrame = self.multibuttonArea.frame;
        newFrame.origin.y = self.questionLabel.frame.origin.y + self.questionLabel.frame.size.height;
        self.multibuttonArea.frame = newFrame;

        newFrame = self.cupView.frame;
        newFrame.origin.y = self.multibuttonArea.frame.origin.y + 7;
        self.cupView.frame = newFrame;

        newFrame = self.questionCell.frame;
        newFrame.size.height = self.multibuttonArea.frame.origin.y + self.multibuttonArea.frame.size.height;
        self.questionCell.frame = newFrame;

        if (challenge.questionType == ChallengeQuestionTypeMultibutton) {
            self.multibuttonArea.hidden = NO;
        } else if (challenge.questionType == ChallengeQuestionTypeSpin) {
            self.spinArea.frame = self.multibuttonArea.frame;
            self.spinArea.hidden = NO;
        } else {
            NSAssert(NO, @"Invalid question type.");
        }

    }

    // Hide challenge accepted switch if the challenges have already been accepted.
    self.acceptCell.writeProtection = (self.challenges.accepted > 0);
    self.alwaysHideAcceptCell = self.acceptCell.writeProtection;
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
    self.topCell = nil;
    self.questionCell = nil;
    self.recommendationCell = nil;
    self.bottomCell = nil;
    self.topCellBackgroundView = nil;
    self.bottomCellBackgroundView = nil;
    self.backButton = nil;
    self.remainingDaysLabel = nil;
    self.headerView = nil;
    self.stripeView = nil;
    self.titleLabel = nil;
    self.descriptionLabel = nil;
    self.doneLabel = nil;
    self.questionLabel = nil;
    self.multibuttonArea = nil;
    self.switchArea = nil;
    self.spinArea = nil;
    self.cupView = nil;
    self.multibutton0 = nil;
    self.multibutton1 = nil;
    self.multibutton2 = nil;
    self.multibutton3 = nil;
    self.multibutton4 = nil;
    self.multibutton5 = nil;
    self.spinView = nil;
    self.spinUpButton = nil;
    self.spinDownButton = nil;
    self.switchView = nil;
    [super viewDidUnload];
}


#pragma mark -
#pragma mark NSObject


- (void)dealloc {
    [self viewDidUnload];
    self.challenge = nil;
    self.challenges.delegate = nil;
    self.challenges = nil;
    self.patternImage = nil;
    self.pattern = nil;
    self.scoreListViewController = nil;
    [super dealloc];
}


@end
