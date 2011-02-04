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

#import "Realtime.h"
#import "Scores.h"
#import "Challenge.h"
#import "Challenges.h"


@interface Challenges ()

@property (nonatomic, copy) NSArray *allChallenges;
@property (nonatomic, copy) NSString *themeIdent;
@property (nonatomic, copy) NSString *badgeFilename;

- (void)clockDidChange:(NSNotification *)notification;

@end


#pragma mark -


@implementation Challenges

@synthesize allChallenges;
@synthesize delegate;
@synthesize themeIdent;
@synthesize badgeFilename;


- (id)initWithTheme:(Theme *)theme {
    if ((self = [super init])) {

        NSAssert(theme && theme.dictionaryPath, @"Invalid state.");

        // Read file Theme.plist.
        NSDictionary *themeDict = [NSDictionary dictionaryWithContentsOfFile:theme.dictionaryPath];

        // Read background color.
        UIColor *backgroundColor = [UIColor blackColor];
        id object = [themeDict objectForKey:@"backgroundColor"];
        if ([object isKindOfClass:[NSNumber class]]) {
            NSUInteger intValue = [object unsignedIntValue];
            backgroundColor = [UIColor colorWithRed:((intValue >> 16) & 0xFF) / 255.0
                                              green:((intValue >>  8) & 0xFF) / 255.0
                                               blue:((intValue      ) & 0xFF) / 255.0
                                              alpha:1];
        }

        // Read badge filename.
        object = [themeDict objectForKey:@"badge"];
        if ([object isKindOfClass:[NSString class]]) {
            self.badgeFilename = [[theme.dictionaryPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:object];
            if ([[NSFileManager defaultManager] fileExistsAtPath:self.badgeFilename] == NO) {
                self.badgeFilename = nil;
            }
        }

        // Create object for each valid challenge.
        NSArray *challengeEntries = [themeDict objectForKey:@"challenges"];
        if ([challengeEntries isKindOfClass:[NSArray class]]) {
            NSMutableArray *challengeArray = [NSMutableArray arrayWithCapacity:challengeEntries.count];
            for (NSUInteger i = 0; i < challengeEntries.count; i++) {
                NSDictionary *challengeDictionary = [challengeEntries objectAtIndex:i];
                if ([challengeDictionary isKindOfClass:[NSDictionary class]]) {
                    Challenge *challenge = [[Challenge alloc] initWithDictionary:challengeDictionary
                                                                  themeDirectory:[theme.dictionaryPath stringByDeletingLastPathComponent]
                                                                        gradient:theme.gradient
                                                                           color:backgroundColor];
                    // Test if dictionary has been valid.
                    if (challenge) {
                        [challengeArray addObject:challenge];
                        [challenge release];
                    }
                }
            }

            // Sort challenges by start date.
            [challengeArray sortUsingSelector:@selector(compare:)];

            // Set challenge identifiers.
            for (NSUInteger i = 0; i < challengeArray.count; i++) {
                Challenge *challenge = [challengeArray objectAtIndex:i];
                challenge.challengeNum = i;
                challenge.ident = [NSString stringWithFormat:@"%@.%c", theme.ident, 'A' + challenge.challengeNum];
            }

            self.allChallenges = [NSArray arrayWithArray:challengeArray];
        } else {
            self.allChallenges = [NSArray array];
        }

        // Save theme ident.
        self.themeIdent = theme.ident;

        // Register for clock change events.
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clockDidChange:) name:EcoChallengeClockDidChangeNotficiation object:nil];
    }
    return self;
}


- (void)setDelegate:(id <ChallengesProtocol>)aDelegate {
    if (delegate != aDelegate) {

        NSAssert(delegate == nil || aDelegate == nil, @"Delegate is already set.");

        delegate = aDelegate;

        // Push challenges to delegate.
        [delegate refreshChallengeList:self.challenges];
    }
}


- (UIImage *)badge {
    if (self.badgeFilename) {
        return [UIImage imageWithContentsOfFile:self.badgeFilename];
    } else {
        return nil;
    }
}


- (NSTimeInterval)accepted {
    NSString *filename = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]
                          stringByAppendingPathComponent:@"MyChallenges.plist"];
    return [[[NSDictionary dictionaryWithContentsOfFile:filename] objectForKey:self.themeIdent] unsignedIntValue];
}


- (void)acceptChallenge:(BOOL)accepted {
    NSString *filename = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]
                          stringByAppendingPathComponent:@"MyChallenges.plist"];
    NSMutableDictionary *acceptedChallenges = [NSMutableDictionary dictionaryWithContentsOfFile:filename];
    if (acceptedChallenges == nil) {
        acceptedChallenges = [NSMutableDictionary dictionaryWithCapacity:1];
    }
    if (accepted) {
        // Add theme with timestamp if it has not already been added.
        if ([acceptedChallenges objectForKey:self.themeIdent] == nil) {
            [acceptedChallenges setObject:[NSNumber numberWithInt:[Realtime sharedInstance].timeRef] forKey:self.themeIdent];
        }
    } else {
        // Remove theme.
        [acceptedChallenges removeObjectForKey:self.themeIdent];
    }
    // Write back file.
    [acceptedChallenges writeToFile:filename atomically:YES];
    // Push challenges to delegate.
    [delegate refreshChallengeList:self.challenges];
}


- (NSArray *)challenges {
    NSTimeInterval timeRef = [Realtime sharedInstance].timeRef;
    NSTimeInterval acceptedDate = self.accepted;

    // Set state for challenges. The first challenge is never shown as teaser.
    for (NSUInteger i = 0; i < self.allChallenges.count; i++) {
        Challenge *challenge = [self.allChallenges objectAtIndex:i];

        // Calculate time span between the date when the user accepted the challenge and the release date of challenge.
        NSTimeInterval timeUntilRelease = [challenge.globalDateRange.from timeIntervalSince1970] - acceptedDate;
        if (timeUntilRelease < 0) {
            timeUntilRelease = 0;
        }

        // Calculate projected duration of challenge.
        NSTimeInterval duration = [challenge.globalDateRange.to timeIntervalSince1970] - [challenge.globalDateRange.from timeIntervalSince1970];

        // Set user individual end date, depending on the date when the user accepted the challenge.
        NSDate *endDate = [NSDate dateWithTimeIntervalSince1970:(acceptedDate + timeUntilRelease + duration)];

        // Round up to next midnight.
        NSDateComponents *components = [[NSCalendar currentCalendar] components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit) fromDate:endDate];
        [components setSecond:59];
        [components setMinute:59];
        [components setHour:23];
        endDate = [[NSCalendar currentCalendar] dateFromComponents:components];

        // And this is the individual time span where the challenge is active.
        challenge.individualDateRange = [[[DateRange alloc] initWithRangeFrom:[NSDate dateWithTimeIntervalSince1970:acceptedDate] to:endDate] autorelease];

        // Now set the right challenge state.
        if ([[Scores sharedInstance] isChallengeAccomplished:challenge.ident]) {
            challenge.state = ChallengeStateDone;
        } else if (i > 0 && timeRef < [challenge.globalDateRange.from timeIntervalSince1970]) {
            challenge.state = ChallengeStateTeaser;
        } else if (acceptedDate && timeRef >= [challenge.individualDateRange.to timeIntervalSince1970] + 24 * 60 * 60) {
            challenge.state = ChallengeStateExpired;
        } else if (acceptedDate) {
            challenge.state = ChallengeStateRunning;
        } else {
            challenge.state = ChallengeStateReady;
        }
    }
    return allChallenges;
}


- (void)clockDidChange:(NSNotification *)notification {
    // Let delegate refresh its challenge list, maybe some new challenges became active.
    [self.delegate refreshChallengeList:self.challenges];
}


#pragma mark -
#pragma mark NSObject


- (void)dealloc {
    // We do not want to get informed about clock change events anymore.
    [[NSNotificationCenter defaultCenter] removeObserver:self name:EcoChallengeClockDidChangeNotficiation object:nil];
    self.allChallenges = nil;
    self.delegate = nil;
    self.themeIdent = nil;
    self.badgeFilename = nil;
    [super dealloc];
}


@end
