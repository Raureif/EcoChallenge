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
#import "FacebookController.h"
#import "MainViewController.h"
#import "ScoreListViewCell.h"


@interface ScoreListViewCell ()

@property (nonatomic, retain) UIButton *button;
@property (nonatomic, retain) UILabel *label;
@property (nonatomic, retain) UIActivityIndicatorView *activityIndicatorView;

- (void)setupWidgets;
- (void)login:(id)sender;
- (void)invite:(id)sender;
- (void)applicationWillEnterForeground:(NSNotification *)notification;

@end


#pragma mark -


@implementation ScoreListViewCell

@synthesize type;
@synthesize roundedCornersOnTop;
@synthesize roundedCornersOnBottom;
@synthesize separatorLine;
@synthesize stripes;
@synthesize backgroundTexture;
@synthesize backgroundFill;
@synthesize photo;
@synthesize name;
@synthesize values;
@synthesize sideOffset;
@synthesize webView;
@synthesize button;
@synthesize label;
@synthesize activityIndicatorView;


+ (CGFloat)cellHeight {
    return 41;
}


- (void)setType:(ScoreListViewCellType)aScoreListViewCellType {
    if (type != aScoreListViewCellType) {
        type = aScoreListViewCellType;
        [self setupWidgets];
        [self setNeedsDisplay];
    }
}


- (void)setRoundedCornersOnTop:(BOOL)aRoundedCornersOnTop {
    if (roundedCornersOnTop != aRoundedCornersOnTop) {
        roundedCornersOnTop = aRoundedCornersOnTop;
        [self setNeedsDisplay];
    }
}


- (void)setRoundedCornersOnBottom:(BOOL)aRoundedCornersOnBottom {
    if (roundedCornersOnBottom != aRoundedCornersOnBottom) {
        roundedCornersOnBottom = aRoundedCornersOnBottom;
        [self setNeedsDisplay];
    }
}


- (void)setSeparatorLine:(BOOL)aSeparatorLine {
    if (separatorLine != aSeparatorLine) {
        separatorLine = aSeparatorLine;
        [self setNeedsDisplay];
    }
}


- (void)setStripes:(BOOL)aStripes {
    if (stripes != aStripes) {
        stripes = aStripes;
        [self setNeedsDisplay];
    }
}


- (void)setBackgroundTexture:(UIImage *)aBackgroundTexture {
    if (backgroundTexture != aBackgroundTexture) {
        [backgroundTexture release];
        backgroundTexture = [aBackgroundTexture retain];
        [self setNeedsDisplay];
    }
}


- (void)setBackgroundFill:(UIColor *)aBackgroundColor {
    if (backgroundFill != aBackgroundColor) {
        [backgroundFill release];
        backgroundFill = [aBackgroundColor retain];
        [self setNeedsDisplay];
    }
}


- (void)setPhoto:(UIImage *)aPhoto {
    if (photo != aPhoto) {
        [photo release];
        photo = [aPhoto retain];
        [self setNeedsDisplay];
    }
}


- (void)setName:(NSString *)aName {
    if (name != aName) {
        [name release];
        name = [aName copy];
        [self setNeedsDisplay];
    }
}


- (void)setValues:(NSArray *)aValues {
    if (values != aValues) {
        [values release];
        values = [aValues copy];
        [self setNeedsDisplay];
    }
}


- (void)setSideOffset:(CGFloat)aSideOffset {
    if (sideOffset != aSideOffset) {
        sideOffset = aSideOffset;
        [self setupWidgets];
        [self setNeedsDisplay];
    }
}


- (void)setWebView:(UIWebView *)aWebView {
    if (webView != aWebView) {
        if (webView) {
            [webView removeFromSuperview];
        }
        [webView release];
        webView = [aWebView retain];
        if (webView) {
            [self addSubview:webView];
        }
    }
}


- (void)setupWidgets {
    // Show or hide button.
    if (self.type == ScoreListViewCellTypeLogin) {
        self.button = [UIButton buttonWithType:UIButtonTypeCustom];
        self.button.frame = CGRectMake(self.sideOffset + 191, 1, 101, 40);
        [self.button setImage:[UIImage imageNamed:@"button-fb-activate-default.png"] forState:UIControlStateNormal];
        [self.button setImage:[UIImage imageNamed:@"button-fb-activate-highlight.png"] forState:UIControlStateHighlighted];
        [self.button addTarget:self action:@selector(login:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.button];
    } else if (self.type == ScoreListViewCellTypeNoFriends && [MFMailComposeViewController canSendMail]) {
        self.button = [UIButton buttonWithType:UIButtonTypeCustom];
        self.button.frame = CGRectMake(self.sideOffset + 191, 1, 101, 40);
        [self.button setImage:[UIImage imageNamed:@"button-invite-default.png"] forState:UIControlStateNormal];
        [self.button setImage:[UIImage imageNamed:@"button-invite-highlight.png"] forState:UIControlStateHighlighted];
        [self.button addTarget:self action:@selector(invite:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.button];
    } else {
        [self.button removeFromSuperview];
        self.button = nil;
    }

    // Show or hide label. The text of this label could be drawn in method drawRect: but this looks awkward during
    // cell rezising, which happens between the cell types ScoreListViewCellTypeChallenge and ScoreListViewCellTypeWaiting.
    if (self.type == ScoreListViewCellTypeWaiting) {
        self.label = [[[UILabel alloc] initWithFrame:CGRectMake(self.sideOffset + 12, 2, 288, 36)] autorelease];
        self.label.font = selectFont(Camingo_Italic_14);
        self.label.textColor = [UIColor colorWithWhite:0.5 alpha:1];
        self.label.shadowColor = [UIColor colorWithWhite:0 alpha:0.5];
        self.label.shadowOffset = CGSizeMake(0, 1);
        self.label.opaque = NO;
        self.label.backgroundColor = [UIColor clearColor];
        self.label.text = NSLocalizedString(@"Scores.Waiting", @"Waiting for scores.");
        [self addSubview:self.label];
    } else {
        [self.label removeFromSuperview];
        self.label = nil;
    }

    // Show or hide spinning wheel.
    if (self.type == ScoreListViewCellTypeWaiting) {
        self.activityIndicatorView = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite] autorelease];
        self.activityIndicatorView.frame = CGRectMake(self.bounds.size.width - 32 - self.sideOffset, 11, 20, 20);
        [self addSubview:self.activityIndicatorView];
        [self.activityIndicatorView startAnimating];
    } else {
        [self.activityIndicatorView removeFromSuperview];
        self.activityIndicatorView = nil;
    }
}


- (void)login:(id)sender {
    [[FacebookController sharedInstance] login];
}


- (void)invite:(id)sender {
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mailComposeViewController = [[MFMailComposeViewController alloc] init];
        mailComposeViewController.mailComposeDelegate = self;
        [mailComposeViewController setSubject:NSLocalizedString(@"Mail.Invite.Subject", @"Invitation subject.")];
        [mailComposeViewController setMessageBody:[NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Email" ofType:@"html"] encoding:NSUTF8StringEncoding error:NULL] isHTML:YES];
        [[MainViewController sharedInstance] presentModalViewController:mailComposeViewController animated:YES];
        [mailComposeViewController release];
    }
}


- (void)applicationWillEnterForeground:(NSNotification *)notification {
    // Start spinning wheel animation.
    [self.activityIndicatorView startAnimating];
}


#pragma mark -
#pragma mark MFMailComposeViewController delegate


- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    [controller dismissModalViewControllerAnimated:YES];
}


#pragma mark -
#pragma mark UITableViewCell


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.clipsToBounds = YES;

        // Set some invalid default cell state.
        self.type = 42;

        // Register for iOS multitasking events.
        if ([[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)] && [UIDevice currentDevice].multitaskingSupported) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
        }
    }
    return self;
}


#pragma mark -
#pragma mark UIView


- (void)drawRect:(CGRect)rect {
    NSAssert(self.type != 42, @"Cell has not been initialized.");

    // Draw tiled background.
    CGContextDrawTiledImage(UIGraphicsGetCurrentContext(),
                            CGRectMake(0, 0, self.backgroundTexture.size.width, self.backgroundTexture.size.height),
                            self.backgroundTexture.CGImage);

    // Draw box with rounded corners.
    CGRect box = CGRectMake(self.sideOffset, 0, self.bounds.size.width - 2 * self.sideOffset, self.bounds.size.height - 1);

    if (self.roundedCornersOnTop == NO) {
        // Simply draw box outside of the drawing rectangle to get right angled corners.
        box.origin.y -= 8;
        box.size.height += 8;
    }

    if (self.roundedCornersOnBottom == NO) {
        // Simply draw box outside of the drawing rectangle to get right angled corners.
        box.size.height += 8;
    }

    drawRoundedRect(box, 8, 8, [UIColor colorWithWhite:0 alpha:0.25]);
    box.origin.y += 1;
    drawRoundedRect(box, 8, 8, self.backgroundFill);
    drawRoundedRect(box, 8, 8, [UIColor colorWithWhite:1 alpha:0.25]);
    box.size.height -= 1;
    drawRoundedRect(box, 8, 8, self.backgroundFill);

    // Draw separator line.
    if (self.separatorLine) {
        [[UIColor colorWithWhite:0.133 alpha:1] set];
        CGContextMoveToPoint(UIGraphicsGetCurrentContext(), box.origin.x, self.bounds.size.height);
        CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), box.origin.x + box.size.width, self.bounds.size.height);
        CGContextStrokePath(UIGraphicsGetCurrentContext());
    }

    // Draw text strings.
    UIColor *fontColor = [UIColor colorWithWhite:0.5 alpha:1];
    UIColor *shadowColor = [UIColor colorWithWhite:0 alpha:0.5];
    switch (self.type) {

        case ScoreListViewCellTypeLogin:
            // Draw text string.
            drawShadowedLabel(CGPointMake(self.sideOffset + 12, 3), 288, Camingo_Bold_14, [UIColor whiteColor], shadowColor, 2,
                              NSLocalizedString(@"Facebook.NotActivated1", @"Facebook is not activated."));
            break;

        case ScoreListViewCellTypeSpoiler:
            // Draw text string.
            drawShadowedLabel(CGPointMake(self.sideOffset + 12, 6), 288, Camingo_Italic_14, fontColor, shadowColor, 2,
                              NSLocalizedString(@"Facebook.NotActivated2", @"Facebook is not activated."));
            break;

        case ScoreListViewCellTypeWaiting:
            // Nothing to draw. The text is displayed in an UILabel.
            break;

        case ScoreListViewCellTypeError:
            // Draw error message string.
            drawShadowedLabel(CGPointMake(self.sideOffset + 32, 2), 268, Camingo_Italic_14, fontColor, shadowColor, 2,
                              NSLocalizedString(@"Scores.Error", @"Score download error."));
            // Draw icon.
            UIImage *image = [UIImage imageNamed:@"themenauswahl-error-flash.png"];
            [image drawInRect:CGRectMake(self.sideOffset + 9, 12, image.size.width, image.size.height)];
            break;

        case ScoreListViewCellTypeNoFriends:
            // Draw text string.
            drawShadowedLabel(CGPointMake(self.sideOffset + 12, 2), 288, Camingo_Italic_14, fontColor, shadowColor, 2,
                              NSLocalizedString(@"Facebook.NoFriends", @"No Facebook friends."));
            break;

        case ScoreListViewCellTypeChallengeList:
            // Draw face image.
            [self.photo drawInRect:CGRectMake(self.sideOffset + 11, 8, 25, 25)];
            // Draw checkmarks.
            CGFloat pos = self.bounds.size.width - self.sideOffset - 8;
            for (NSInteger i = self.values.count - 1; i >= 0; i--) {
                if ([[self.values objectAtIndex:i] boolValue] == YES) {
                    image = [UIImage imageNamed:@"challengecheckbox-on.png"];
                } else {
                    image = [UIImage imageNamed:@"challengecheckbox-off.png"];
                }
                pos -= image.size.width + 1;
                [image drawInRect:CGRectMake(pos, 12, image.size.width, image.size.height)];
            }
            // Draw name string.
            drawLabel(CGPointMake(sideOffset + 45, 11), pos - sideOffset - 49, Rooney_Bold_14, [UIColor whiteColor], 1, self.name);
            break;

        case ScoreListViewCellTypeAchievement:
            // Draw chart string.
            drawShadowedLabel(CGPointMake(sideOffset + 11, 8), 31, Camingo_Bold_17, fontColor, shadowColor, 1,
                              [NSString stringWithFormat:@"%@.", [self.values objectAtIndex:0]]);
            // Draw face image.
            [self.photo drawInRect:CGRectMake(self.sideOffset + 42, 8, 25, 25)];
            // Draw name string.
            drawLabel(CGPointMake(sideOffset + 76, 8), 135, Rooney_17, [UIColor whiteColor], 1, self.name);
            // Draw challenges string.
            CGFloat offset = drawLabelAligned(CGPointMake(self.bounds.size.width - sideOffset - 7, 13), 80, Camingo_12, fontColor, 1,
                                              NSLocalizedString(@"Scores.Accomplished", @"Accomplished."), UITextAlignmentRight);
            // Draw number of challenges string.
            NSNumberFormatter *formatter = [[[NSNumberFormatter alloc] init] autorelease];
            // Remove the next line as soon as the application becomes localized.
            formatter.locale = [[[NSLocale alloc] initWithLocaleIdentifier:@"de_DE"] autorelease];
            [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
            drawLabelAligned(CGPointMake(offset - 4, 8), 80, Rooney_Bold_17, [UIColor whiteColor], 1,
                             [formatter stringForObjectValue:[self.values objectAtIndex:1]], UITextAlignmentRight);
            break;

        case ScoreListViewCellTypeCalculator:
            // Draw face image.
            [self.photo drawInRect:CGRectMake(self.sideOffset + 11, 8, 25, 25)];
            // Draw name string.
            offset = drawLabel(CGPointMake(sideOffset + 45, 11), 166, Rooney_Bold_14, [UIColor whiteColor], 1, self.name);
            // Draw number of items string.
            NSString *text;
            if ([[self.values objectAtIndex:1] unsignedIntValue] == 1) {
                text = NSLocalizedString(@"Facebook.Entry", @"One calculator entry.");
            } else {
                text = [NSString stringWithFormat:NSLocalizedString(@"Facebook.Entries", @"Number of calculator entries."), [[self.values objectAtIndex:1] unsignedIntValue]];
            }
            drawLabel(CGPointMake(sideOffset + offset + 50, 11), 166 - offset, Rooney_14, fontColor, 1, text);
            // Draw unit string. Draw it transparently if the number of calculator entries is zero.
            offset = drawLabelAligned(CGPointMake(self.bounds.size.width - sideOffset - 7, 13), 80, Camingo_14,
                                      [UIColor colorWithWhite:1 alpha:([[self.values objectAtIndex:1] unsignedIntValue] > 0 ? 1 : 0)], 1, [self.values objectAtIndex:2], UITextAlignmentRight);
            // Draw count string.
            formatter = [[[NSNumberFormatter alloc] init] autorelease];
            // Remove the next line as soon as the application becomes localized.
            formatter.locale = [[[NSLocale alloc] initWithLocaleIdentifier:@"de_DE"] autorelease];
            [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
            drawLabelAligned(CGPointMake(offset - 2, 7), 80, Camingo_Bold_20, [UIColor whiteColor], 1,
                             ([[self.values objectAtIndex:1] unsignedIntValue] > 0 ? [formatter stringForObjectValue:[self.values objectAtIndex:0]] : @"-"), UITextAlignmentRight);
            break;

        case ScoreListViewCellTypeChallenge:
            // Nothing to draw. The content is displayed in an UIWebView.
            break;
    }
}


#pragma mark -
#pragma mark NSObject


- (void)dealloc {
    // We do not want to get informed when application enters background mode anymore.
    if ([[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)] && [UIDevice currentDevice].multitaskingSupported) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    }
    self.backgroundTexture = nil;
    self.backgroundFill = nil;
    self.photo = nil;
    self.name = nil;
    self.values = nil;
    self.webView = nil;
    self.button = nil;
    self.label = nil;
    self.activityIndicatorView = nil;
    [super dealloc];
}


@end
