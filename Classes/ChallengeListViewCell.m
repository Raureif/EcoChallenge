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
#import "ChallengeListViewCell.h"


@interface ChallengeListViewCell ()

@property (nonatomic, retain) UIImage *background;
@property (nonatomic, assign) BOOL drawHighlighted;

@end


#pragma mark -


@implementation ChallengeListViewCell

@synthesize individualDateRange;
@synthesize globalDateRange;
@synthesize title;
@synthesize gradient;
@synthesize color;
@synthesize activeIcon;
@synthesize doneIcon;
@synthesize challengeState;
@synthesize challengeNum;
@synthesize background;
@synthesize drawHighlighted;


#define SIDE_OFFSET    10
#define BOTTOM_OFFSET  11


+ (CGFloat)cellHeight {
    return 112 + BOTTOM_OFFSET;
}


- (void)setIndividualDateRange:(DateRange *)aIndividualDateRange {
    if (individualDateRange != aIndividualDateRange) {
        [individualDateRange release];
        individualDateRange = [aIndividualDateRange retain];
        [self setNeedsDisplay];
    }
}


- (void)setGlobalDateRange:(DateRange *)aGlobalDateRange {
    if (globalDateRange != aGlobalDateRange) {
        [globalDateRange release];
        globalDateRange = [aGlobalDateRange retain];
        [self setNeedsDisplay];
    }
}


- (void)setTitle:(NSString *)aTitle {
    if (title != aTitle) {
        [title release];
        title = [aTitle copy];
        [self setNeedsDisplay];
    }
}


- (void)setGradient:(Gradient *)aGradient {
    if (gradient != aGradient) {
        [gradient release];
        gradient = [aGradient retain];
        [self setNeedsDisplay];
    }
}


- (void)setActiveIcon:(UIImage *)anActiveIcon {
    if (activeIcon != anActiveIcon) {
        [activeIcon release];
        activeIcon = [anActiveIcon retain];
        [self setNeedsDisplay];
    }
}


- (void)setDoneIcon:(UIImage *)aDoneIcon {
    if (doneIcon != aDoneIcon) {
        [doneIcon release];
        doneIcon = [aDoneIcon retain];
        [self setNeedsDisplay];
    }
}


- (void)setChallengeState:(ChallengeState)aChallengeState {
    if (challengeState != aChallengeState) {
        challengeState = aChallengeState;
        [self setNeedsDisplay];
    }
}


#pragma mark -
#pragma mark UITableViewCell


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {

        // Load background image.
        self.background = [UIImage imageNamed:@"gray-fill.png"];

        // Set some invalid default challenge state.
        self.challengeState = 42;
    }
    return self;
}


- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    // Overwrite but do not call super method. This prevents the drawing of a blue background.

    // Set flag.
    self.drawHighlighted = highlighted && (self.challengeState != ChallengeStateTeaser);

    // Redraw.
    [self setNeedsDisplay];
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    // Overwrite but do not call super method. This prevents the drawing of a blue background.
}


#pragma mark -
#pragma mark UIView


- (void)drawRect:(CGRect)rect {
    NSAssert(self.challengeState != 42, @"Cell has not been initialized.");

    // Draw tiled background.
    CGContextDrawTiledImage(UIGraphicsGetCurrentContext(),
                            CGRectMake(0, 0, self.background.size.width, self.background.size.height),
                            self.background.CGImage);

    // Draw box with rounded corners and gradient.
    CGFloat topOffset = (self.drawHighlighted ? 2 : 0);
    CGRect box = CGRectMake(SIDE_OFFSET, topOffset, self.bounds.size.width - 2 * SIDE_OFFSET, self.bounds.size.height - topOffset - BOTTOM_OFFSET);
    if (self.challengeState == ChallengeStateTeaser) {
        drawRoundedRect(box, 8, 8, [UIColor colorWithWhite:0 alpha:0.25]);
        box.origin.y += 1;
        drawRoundedRect(box, 8, 8, [UIColor colorWithWhite:0.129 alpha:1]);
        drawRoundedRect(box, 8, 8, [UIColor colorWithWhite:1 alpha:0.25]);
        box.size.height -= 1;
        Gradient *grayGradient = [[[Gradient alloc] initWithGradientFrom:0x424343 to:0x2c2b2b] autorelease];
        drawRoundedGradientRect(box, 8, 8, grayGradient);
    } else if (self.drawHighlighted) {
        drawRoundedRect(box, 8, 8, [UIColor colorWithWhite:0 alpha:0.25]);
        box.origin.y += 1;
        drawRoundedRect(box, 8, 8, self.gradient.fromColor);
        drawRoundedRect(box, 8, 8, [UIColor colorWithWhite:1 alpha:0.25]);
        box.size.height -= 1;
        Gradient *inverseGradient = [[[Gradient alloc] initWithGradientFrom:self.gradient.to to:self.gradient.from] autorelease];
        drawRoundedGradientRect(box, 8, 8, inverseGradient);
    } else {
        box.origin.y += 1;
        drawRoundedRect(box, 8, 8, [UIColor colorWithWhite:0 alpha:0.25]);
        box.origin.y -= 1;
        drawRoundedGradientRect(box, 8, 8, self.gradient);
    }

    // Draw button image.
    UIImage *image = nil;
    if (self.challengeState != ChallengeStateTeaser && self.drawHighlighted) {
        image = [UIImage imageNamed:@"arrow-fwd-highlight.png"];
    } else if (self.challengeState != ChallengeStateTeaser) {
        image = [UIImage imageNamed:@"arrow-fwd-default.png"];
    }
    [image drawInRect:CGRectMake(SIDE_OFFSET + 277, topOffset + 21, image.size.width, image.size.height)];

    // Draw icon.
    if (self.challengeState == ChallengeStateTeaser) {
        image = [UIImage imageNamed:@"icon-challenge-preview.png"];
    } else if (self.challengeState == ChallengeStateDone || self.challengeState == ChallengeStateExpired) {
        image = self.doneIcon;
    } else {
        image = self.activeIcon;
    }
    [image drawInRect:CGRectMake(SIDE_OFFSET + 6, topOffset + 6, image.size.width, image.size.height)];

    // Select font for supertitle string.
    DrawUtilsFont font;
    if (self.challengeState == ChallengeStateDone) {
        font = Camingo_Bold_17;
    } else {
        font = Camingo_17;
    }

    // Select font color and shadow for supertitle string.
    UIColor *fontColor, *shadowColor;
    if (challengeState == ChallengeStateTeaser) {
        fontColor = [UIColor colorWithWhite:0.6 alpha:1];
        shadowColor = [UIColor colorWithWhite:0 alpha:0.5];
    } else {
        fontColor = self.color;
        shadowColor = [UIColor colorWithWhite:1 alpha:0.25];
    }

    // Draw supertitle string.
    NSString *str = nil;
    if (self.challengeState == ChallengeStateTeaser) {
        NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
        // Remove the next line as soon as the application becomes localized.
        formatter.locale = [[[NSLocale alloc] initWithLocaleIdentifier:@"de_DE"] autorelease];
        NSArray *weekdays = [formatter standaloneWeekdaySymbols];
        NSInteger weekday = [[NSCalendar currentCalendar] components:NSWeekdayCalendarUnit fromDate:self.globalDateRange.from].weekday - 1;
        str = [NSString stringWithFormat:NSLocalizedString(@"Challenge.FromDay", @"Weekday when next challenge starts."), [weekdays objectAtIndex:weekday]];
    } else if (self.challengeState == ChallengeStateDone) {
        str = NSLocalizedString(@"Challenge.Done", @"Done.");
    } else if (self.challengeState == ChallengeStateExpired) {
        str = NSLocalizedString(@"Challenge.Expired", @"Expired.");
    } else if (self.challengeState == ChallengeStateRunning) {
        NSInteger days = ceilf(([self.individualDateRange.to timeIntervalSince1970] - [Realtime sharedInstance].timeRef) / 60.0 / 60.0 / 24.0) + 1;
        if (days == 1) {
            str = [NSString stringWithFormat:NSLocalizedString(@"Date.RemainingDay", @"One remaining day.")];
        } else {
            str = [NSString stringWithFormat:NSLocalizedString(@"Date.RemainingDays", @"Number of remaining days."), days];
        }
    }
    drawShadowedLabel(CGPointMake(SIDE_OFFSET + 59, topOffset + 17), 220,
                      font, fontColor, shadowColor, 1, str);

    // Select font for title string.
    if (self.challengeState == ChallengeStateTeaser) {
        font = Rooney_Italic_17;
    } else {
        font = Rooney_Italic_20;
    }

    // Select font color and shadow for title string.
    if (challengeState == ChallengeStateTeaser) {
        fontColor = [UIColor colorWithWhite:0.6 alpha:1];
    } else {
        fontColor = [UIColor whiteColor];
    }
    shadowColor = [UIColor colorWithWhite:0 alpha:0.5];

    // Draw title string.
    if (self.challengeState == ChallengeStateTeaser) {
        str = NSLocalizedString(([NSString stringWithFormat:@"Challenge.Teaser%u", self.challengeNum + 1]), @"Challenge teaser.");
    } else {
        str = self.title;
    }
    drawShadowedLabel(CGPointMake(SIDE_OFFSET + 12, topOffset + (self.challengeState == ChallengeStateTeaser ? 58 : 52)), 288,
                      font, fontColor, shadowColor, 2, str);
}


#pragma mark -
#pragma mark NSObject


- (void)dealloc {
    self.individualDateRange = nil;
    self.globalDateRange = nil;
    self.title = nil;
    self.gradient = nil;
    self.color = nil;
    self.activeIcon = nil;
    self.doneIcon = nil;
    self.background = nil;
    [super dealloc];
}


@end
