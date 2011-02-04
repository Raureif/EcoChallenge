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

#import "Challenge.h"
#import "DrawUtils.h"
#import "Realtime.h"
#import "PushNotifications.h"
#import "ScoreReporter.h"
#import "ChallengeAcceptCell.h"


@interface ChallengeAcceptCell ()

@property (nonatomic, retain) SwitchView *switchView;
@property (nonatomic, retain) UIView *blackArea;

- (void)acceptChallenges:(id)sender;

@end


#pragma mark -


@implementation ChallengeAcceptCell

@synthesize challenges;
@synthesize writeProtection;;
@synthesize switchView;
@synthesize blackArea;


- (void)setChallenges:(Challenges *)aChallenges {
    if (challenges != aChallenges) {
        [challenges release];
        challenges = [aChallenges retain];
    }
    self.switchView.on = (challenges.accepted > 0);
    [self setNeedsDisplay];
}


- (void)setWriteProtection:(BOOL)aWriteProtection {
    if (writeProtection != aWriteProtection) {
        writeProtection = aWriteProtection;
        self.switchView.hidden = writeProtection;
        [self setNeedsDisplay];
    }
}


- (void)acceptChallenges:(id)sender {
    // Enable or disable push notifications.
    [PushNotifications sharedInstance].enabled = self.switchView.on;
    // Accept or reject challenges.
    [self.challenges acceptChallenge:self.switchView.on];
}


- (void)mayReportAcceptedChallengesToServer {
    if (self.challenges.accepted > 0 && self.writeProtection == NO) {
        self.writeProtection = YES;
        for (Challenge *challenge in self.challenges.challenges) {
            [[ScoreReporter sharedInstance] reportChallengeScoreForChallenge:challenge.ident];
        }
    }
}


#pragma mark -
#pragma mark UIView


- (void)drawRect:(CGRect)rect {
    NSTimeInterval timeRef = [Realtime sharedInstance].timeRef;
    NSTimeInterval acceptedDate = self.challenges.accepted;

    // Get maximum challenge end date.
    NSTimeInterval maxEndDate = 0;
    for (Challenge *challenge in self.challenges.challenges) {
        maxEndDate = MAX(maxEndDate, [challenge.individualDateRange.to timeIntervalSince1970]);
    }
    maxEndDate += 24 * 60 * 60;

    // Draw tiled background.
    UIImage *backgroundTexture = [UIImage imageNamed:@"gray-fill.png"];
    CGContextDrawTiledImage(UIGraphicsGetCurrentContext(),
                            CGRectMake(0, 0, backgroundTexture.size.width, backgroundTexture.size.height),
                            backgroundTexture.CGImage);

    // Draw top rounded corners.
    [[UIImage imageNamed:@"gray-corners-onblack.png"] drawInRect:CGRectMake(0, 0, 320, 11)];

    // Draw icon.
    [[UIImage imageNamed:@"icon-reminder.png"] drawInRect:CGRectMake(11, 14, 25, 29)];

    // Draw prompt label.
    NSString *text;
    if (acceptedDate > 0) {
        text = NSLocalizedString(@"Challenges.DidAccept", @"Did accept challenges.");
    } else {
        text = NSLocalizedString(@"Challenges.DoAccept", @"Do accept challenges.");
    }
    drawShadowedLabel(CGPointMake(42, 10), 170, Camingo_Bold_14, [UIColor colorWithWhite:0.75 alpha:1], [UIColor colorWithWhite:0 alpha:1], 1, text);

    // Draw subtitle label.
    if (acceptedDate > 0) {
        if (timeRef > maxEndDate) {
            NSInteger days = ceilf((timeRef - maxEndDate) / 60.0 / 60.0 / 24.0) - 1;
            if (days <= 0) {
                text = NSLocalizedString(@"Challenges.NotRunningFor0", @"Does not run for 0 days.");
            } else if (days == 1) {
                text = [NSString stringWithFormat:NSLocalizedString(@"Challenges.NotRunningFor1", @"Does not run for 1 day.")];
            } else {
                text = [NSString stringWithFormat:NSLocalizedString(@"Challenges.NotRunningForX", @"Does not run for x days."), days];
            }
        } else {
            NSInteger days = ceilf((timeRef - acceptedDate) / 60.0 / 60.0 / 24.0) - 1;
            if (days <= 0) {
                text = NSLocalizedString(@"Challenges.RunningFor0", @"Runs for 0 days.");
            } else if (days == 1) {
                text = [NSString stringWithFormat:NSLocalizedString(@"Challenges.RunningFor1", @"Runs for 1 day.")];
            } else {
                text = [NSString stringWithFormat:NSLocalizedString(@"Challenges.RunningForX", @"Runs for x days."), days];
            }
        }
    } else {
        text = NSLocalizedString(@"Challenges.NotRunning", @"Not yet running.");
    }
    drawShadowedLabel(CGPointMake(42, 27), 170, Camingo_Italic_14, [UIColor colorWithWhite:0.35 alpha:1], [UIColor colorWithWhite:0 alpha:1], 1, text);

    // Draw checkmark.
    if (self.writeProtection) {
        if (timeRef > maxEndDate) {
            [[UIImage imageNamed:@"challenge-accepted-inactive.png"] drawInRect:CGRectMake(270, 11, 40, 38)];
        } else {
            [[UIImage imageNamed:@"challenge-accepted-active.png"] drawInRect:CGRectMake(270, 11, 40, 38)];
        }
    }
}


#pragma mark -
#pragma mark NSObject


- (void)awakeFromNib {
    [super awakeFromNib];
    self.switchView = [[[SwitchView alloc] initWithFrame:CGRectMake(206, 11, 104, 38)] autorelease];
    self.switchView.backgroundFill = [UIColor colorWithWhite:0.165 alpha:1];
    [self.switchView addTarget:self action:@selector(acceptChallenges:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:self.switchView];

    // Draw black background above cell. It's a trick: The UITableView has a gray background so the
    // cell insertion of the ScoreListViewController uses gray, too. But because the UITableView
    // should have a black background, the top cell (i.e. this cell) draws a black area outside
    // its view.
    self.blackArea = [[UIView alloc] initWithFrame:CGRectMake(0, -240, self.bounds.size.width, 240)];
    self.blackArea.backgroundColor = [UIColor blackColor];
    [self addSubview:self.blackArea];
}


- (void)dealloc {
    self.challenges = nil;
    self.switchView = nil;
    self.blackArea = nil;
    [super dealloc];
}


@end
