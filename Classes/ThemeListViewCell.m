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
#import "ThemeListViewCell.h"


@interface ThemeListViewCell ()

@property (nonatomic, retain) ThemeListViewCellView *themeListViewCellView;
@property (nonatomic, retain) NSTimer *timer;
@property (nonatomic, retain) UIProgressView *progressView;
@property (nonatomic, retain) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic, assign) BOOL drawHighlighted;

- (void)resizeCellAnimationDidFinish;
- (void)setupSupertitle;
- (void)setupSubtitle;
- (void)setupButtonImage;
- (void)setupIcons;
- (void)setupWidgetPositions;
- (void)applicationWillEnterForeground:(NSNotification *)notification;
- (void)applicationDidEnterBackground:(NSNotification *)notification;

@end


#pragma mark -


@implementation ThemeListViewCell

@synthesize dateRange;
@synthesize title;
@synthesize error;
@synthesize gradient;
@synthesize isExpired;
@synthesize challenges;
@synthesize progress;
@synthesize themeState;
@synthesize themeListViewCellView;
@synthesize timer;
@synthesize progressView;
@synthesize activityIndicatorView;
@synthesize drawHighlighted;


#define SIDE_OFFSET    10
#define BOTTOM_OFFSET  11


+ (CGFloat)cellHeightForThemeState:(ThemeState)themeState {
    if (themeState == ThemeStateTeaser || themeState == ThemeStateOnServer) {
        return 58 + BOTTOM_OFFSET;
    } else {
        return 80 + BOTTOM_OFFSET;
    }
}


- (void)setDateRange:(DateRange *)aDateRange {
    if (dateRange != aDateRange) {
        [dateRange release];
        dateRange = [aDateRange retain];
        [self setupSupertitle];
    }
}


- (void)setTitle:(NSString *)aTitle {
    if (title != aTitle) {
        [title release];
        title = [aTitle copy];
        self.themeListViewCellView.title = title;
    }
}


- (void)setError:(NSError *)anError {
    if (error != anError) {
        [error release];
        error = [anError retain];
        if (self.timer == nil) {
            [self setupSubtitle];
        }
    }
}


- (void)setGradient:(Gradient *)aGradient {
    if (gradient != aGradient) {
        [gradient release];
        gradient = [aGradient retain];
        [self setNeedsDisplay];
    }
}


- (void)setChallenges:(NSArray *)aChallenges {
    if (challenges != aChallenges) {
        [challenges release];
        challenges = [aChallenges copy];
        if (self.timer == nil) {
            [self setupIcons];
            [self setupSubtitle];
        }
    }
}


- (void)setProgress:(float)aProgress {
    if (progress != aProgress) {
        progress = aProgress;
        self.progressView.progress = progress;
    }
}


- (void)setThemeState:(ThemeState)aThemeState {
    [self setThemeState:aThemeState animated:NO];
}


- (void)setThemeState:(ThemeState)aThemeState animated:(BOOL)animated {
    ThemeState previousThemeState = themeState;

    if (themeState != aThemeState) {
        themeState = aThemeState;

        // Set new frame size.
        if (animated == NO) {
            self.frame = CGRectMake(0, 0, 320, [ThemeListViewCell cellHeightForThemeState:themeState]);
        }

        // Remove icons, subtitle and progress bar. Add them later in method resizeCellAnimationDidFinish.
        self.themeListViewCellView.icons = nil;
        self.themeListViewCellView.subtitle = nil;
        [self.progressView removeFromSuperview];
        self.progressView = nil;

        // Set font color.
        if (themeState == ThemeStateTeaser) {
            self.themeListViewCellView.fontColor = [UIColor colorWithWhite:0.6 alpha:1];
        } else {
            self.themeListViewCellView.fontColor = [UIColor whiteColor];
        }
        
        // Show button image.
        [self setupButtonImage];

        // Show super title.
        [self setupSupertitle];

        // Show or hide spinning wheel.
        if (themeState == ThemeStateDownloading) {
            self.activityIndicatorView = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite] autorelease];
            [self setupWidgetPositions];
            [self addSubview:self.activityIndicatorView];
            [self.activityIndicatorView startAnimating];
        } else {
            [self.activityIndicatorView removeFromSuperview];
            self.activityIndicatorView = nil;
        }

        // Either show the lower part of the cell immediately or delay its appearance.
        if (self.timer == nil) {
            if (animated && [ThemeListViewCell cellHeightForThemeState:previousThemeState] != [ThemeListViewCell cellHeightForThemeState:themeState]) {
                self.timer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(resizeCellAnimationDidFinish) userInfo:nil repeats:NO];
            } else {
                [self resizeCellAnimationDidFinish];
            }
        }

        // Redraw to ajdust gradient to current state.
        [self setNeedsDisplay];
    }
}


- (void)resizeCellAnimationDidFinish {
    // Deallocate timer.
    [self.timer invalidate];
    self.timer = nil;

    // Show icons.
    [self setupIcons];

    // Show subtitle.
    [self setupSubtitle];

    // Show progress bar.
    if (themeState == ThemeStateDownloading) {
        self.progressView = [[[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar] autorelease];
        self.progressView.progress = self.progress;
        [self setupWidgetPositions];
        [self addSubview:self.progressView];
    }
}


- (void)setupSupertitle {
    // Show start and end date of theme.
    if (self.themeState == ThemeStateTeaser) {
        self.themeListViewCellView.supertitle = NSLocalizedString(@"Date.NextWeek", @"Next week.");
    } else {
        self.themeListViewCellView.supertitle = [self.dateRange description];
    }
}


- (void)setupSubtitle {
    if (self.themeState == ThemeStateReady) {
        // Show number of open or expired challenges.
        NSUInteger challengeCount = 0;
        for (NSUInteger i = 0; i < self.challenges.count; i++) {
            if ([[self.challenges objectAtIndex:i] boolValue] == NO) {
                challengeCount++;
            }
        }
        if (self.isExpired && challengeCount == 1) {
            self.themeListViewCellView.subtitle = NSLocalizedString(@"Challenge.Expired1", @"One expired challenge.");
        } else if (self.isExpired) {
            self.themeListViewCellView.subtitle = [NSString stringWithFormat:NSLocalizedString(@"Challenge.ExpiredX", @"More than one expired challenges."), challengeCount];
        } else if (challengeCount == 1) {
            self.themeListViewCellView.subtitle = NSLocalizedString(@"Challenge.Open1", @"One open challenge.");
        } else {
            self.themeListViewCellView.subtitle = [NSString stringWithFormat:NSLocalizedString(@"Challenge.OpenX", @"More than one open challenges."), challengeCount];            
        }
    } else if (self.themeState == ThemeStateDownloading) {
        self.themeListViewCellView.subtitle = NSLocalizedString(@"Network.Loading", @"Loading.");
    } else if (self.themeState == ThemeStateDownloadFailed) {
        self.themeListViewCellView.subtitle = [self.error localizedDescription];
    } else {
        self.themeListViewCellView.subtitle = nil;
    }
}


- (void)setupButtonImage {
    // Choose button image by theme state.
    if (self.themeState == ThemeStateOnServer && self.drawHighlighted) {
        self.themeListViewCellView.buttonImage = [UIImage imageNamed:@"themenauswahl-download-highlight.png"];
    } else if (self.themeState == ThemeStateOnServer) {
        self.themeListViewCellView.buttonImage = [UIImage imageNamed:@"themenauswahl-download-default.png"];
    } else if (self.themeState == ThemeStateDownloadFailed && self.drawHighlighted) {
        self.themeListViewCellView.buttonImage = [UIImage imageNamed:@"themenauswahl-refresh-highlight.png"];
    } else if (self.themeState == ThemeStateDownloadFailed) {
        self.themeListViewCellView.buttonImage = [UIImage imageNamed:@"themenauswahl-refresh-default.png"];
    } else {
        self.themeListViewCellView.buttonImage = nil;
    }
}


- (void)setupIcons {
    if (self.themeState == ThemeStateReady) {
        // Add checkmark icon for each challenge.
        NSMutableArray *icons = [NSMutableArray arrayWithCapacity:self.challenges.count];
        for (NSUInteger i = 0; i < self.challenges.count; i++) {
            if ([[self.challenges objectAtIndex:i] boolValue]) {
                [icons addObject:[UIImage imageNamed:@"challengecheckbox-on.png"]];
            } else {
                [icons addObject:[UIImage imageNamed:@"challengecheckbox-off.png"]];
            }
        }
        self.themeListViewCellView.icons = [NSArray arrayWithArray:icons];
    } else if (self.themeState == ThemeStateDownloadFailed) {
        self.themeListViewCellView.icons = [NSArray arrayWithObjects:[UIImage imageNamed:@"themenauswahl-error-flash.png"], nil];
    } else {
        self.themeListViewCellView.icons = nil;
    }
}


- (void)setupWidgetPositions {
    CGFloat topOffset = (self.drawHighlighted ? 2 : 0);
    self.activityIndicatorView.frame = CGRectMake(SIDE_OFFSET + 273, topOffset + 20, 20, 20);
    self.progressView.frame = CGRectMake(SIDE_OFFSET + 12, topOffset + 60, 125, 11);
}


- (void)applicationWillEnterForeground:(NSNotification *)notification {
    // Start spinning wheel animation.
    [self.activityIndicatorView startAnimating];
}


- (void)applicationDidEnterBackground:(NSNotification *)notification {
    // Stop timer.
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
        [self resizeCellAnimationDidFinish];
    }
}


#pragma mark -
#pragma mark UITableViewCell


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {

        // Add sub-view which will not be scaled during resize animation.
        self.themeListViewCellView = [[[ThemeListViewCellView alloc] initWithFrame:CGRectMake(0, 0, 320, [ThemeListViewCell cellHeightForThemeState:ThemeStateReady])] autorelease];
        self.themeListViewCellView.offset = CGPointMake(SIDE_OFFSET, 0);
        [self addSubview:self.themeListViewCellView];

        // Set some invalid default theme state.
        self.themeState = 42;

        // Register for iOS multitasking events.
        if ([[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)] && [UIDevice currentDevice].multitaskingSupported) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        }
    }
    return self;
}


- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    // Overwrite but do not call super method. This prevents the drawing of a blue background.

    // Set flag.
    self.drawHighlighted = highlighted && (self.themeState == ThemeStateReady ||
                                           self.themeState == ThemeStateOnServer ||
                                           self.themeState == ThemeStateDownloadFailed ||
                                           self.themeState == ThemeStateDownloading);

    // Offset content by two pixels if highlighted.
    self.themeListViewCellView.offset = CGPointMake(SIDE_OFFSET, self.drawHighlighted ? 2 : 0);

    // Adjust button image to highlighted state.
    [self setupButtonImage];

    // Adjust widget positions to highlighted state.
    [self setupWidgetPositions];

    // Redraw to ajdust gradient to highlighted state.
    [self setNeedsDisplay];
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    // Overwrite but do not call super method. This prevents the drawing of a blue background.
}


#pragma mark -
#pragma mark UIView


- (void)drawRect:(CGRect)rect {
    NSAssert(self.themeState != 42, @"Cell has not been initialized.");

    CGFloat topOffset = (self.drawHighlighted ? 2 : 0);
    CGRect box = CGRectMake(SIDE_OFFSET, topOffset, self.bounds.size.width - 2 * SIDE_OFFSET, self.bounds.size.height - topOffset - BOTTOM_OFFSET);

    // Draw box with rounded corners and gradient.
    if (self.themeState == ThemeStateTeaser) {
        box.origin.y += 1;
        drawRoundedRect(box, 8, 8, [UIColor colorWithWhite:0.129 alpha:1]);
        drawRoundedRect(box, 8, 8, [UIColor colorWithWhite:1 alpha:0.25]);
        box.origin.y -= 1;
        Gradient *grayGradient = [[[Gradient alloc] initWithGradientFrom:0x424343 to:0x2c2b2b] autorelease];
        drawRoundedGradientRect(box, 8, 8, grayGradient);
    } else if (self.drawHighlighted) {
        box.origin.y += 1;
        drawRoundedRect(box, 8, 8, self.gradient.fromColor);
        drawRoundedRect(box, 8, 8, [UIColor colorWithWhite:1 alpha:0.25]);
        box.origin.y -= 1;
        Gradient *inverseGradient = [[[Gradient alloc] initWithGradientFrom:self.gradient.to to:self.gradient.from] autorelease];
        drawRoundedGradientRect(box, 8, 8, inverseGradient);
    } else {
        drawRoundedGradientRect(box, 8, 8, self.gradient);
    }
}


#pragma mark -
#pragma mark NSObject


- (void)dealloc {
    // We do not want to get informed when application enters background mode anymore.
    if ([[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)] && [UIDevice currentDevice].multitaskingSupported) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    self.dateRange = nil;
    self.title = nil;
    self.error = nil;
    self.gradient = nil;
    self.challenges = nil;
    self.themeListViewCellView = nil;
    self.timer = nil;
    self.progressView = nil;
    self.activityIndicatorView = nil;
    [super dealloc];
}


@end
