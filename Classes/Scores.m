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
#import "Challenge.h"
#import "ScoreReporter.h"
#import "Scores.h"


/* The scores will only be loaded at the moment when a delegate
 * is set or when the application enteres foreground mode (and a delegate
 * is set). The scores for one theme are cached for one minute.
 */


@interface Scores ()

@property (nonatomic, copy, readwrite) NSDictionary *challenges;
@property (nonatomic, copy, readwrite) NSArray *friends;
@property (nonatomic, copy, readwrite) NSDictionary *scores;
@property (nonatomic, assign, readwrite) NSUInteger worldwideChallenges;
@property (nonatomic, assign, readwrite) BOOL cannotDownloadScore;
@property (nonatomic, assign, readwrite) BOOL isDownloadingScore;
@property (nonatomic, copy) NSString *delegateThemeIdent;
@property (nonatomic, copy) NSString *scoreFilename;

- (void)downloadScore;
- (void)informDelegate;

@end


#pragma mark -


@implementation Scores

@synthesize delegate;
@synthesize challenges;
@synthesize friends;
@synthesize scores;
@synthesize worldwideChallenges;
@synthesize cannotDownloadScore;
@synthesize isDownloadingScore;
@synthesize delegateThemeIdent;
@synthesize scoreFilename;


static Scores *sharedInstance = nil;


+ (Scores *)sharedInstance {
    if (sharedInstance == nil) {

        // Create singleton object.
        sharedInstance = [[Scores alloc] init];

        // Read score file from home directory.
        sharedInstance.scoreFilename = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]
                                        stringByAppendingPathComponent:@"Scores.plist"];
        sharedInstance.scores = [NSDictionary dictionaryWithContentsOfFile:sharedInstance.scoreFilename];
    }
    return sharedInstance;
}


- (void)setDelegate:(id <ScoresProtocol>)aDelegate {
    [self setDelegate:aDelegate themeIdent:nil];
}


- (BOOL)isDownloadingScore {
    return (isDownloadingScore || [FacebookController sharedInstance].isDownloadingFriends);
}


- (void)setDelegate:(id <ScoresProtocol>)aDelegate themeIdent:(NSString *)ident {
    if (delegate != aDelegate) {

        NSAssert(delegate == nil || aDelegate == nil, @"Delegate is already set.");

        delegate = aDelegate;
        self.delegateThemeIdent = ident;

        if (delegate) {
            // Let Facebook controller fetch friend list. This will eventually start
            // the download of the scores and inform our delegate about the current state.
            [FacebookController sharedInstance].delegate = self;
        } else {
            // We do not want to get informed about new friends lists from Facebook controller.
            [FacebookController sharedInstance].delegate = nil;
        }
    }
}


- (BOOL)isThemeAccomplished:(Theme *)theme {
    // A theme is accomplished if all of its challenges are accomplished.
    if (theme.state == ThemeStateReady) {
        BOOL completedAllChallenges = YES;
        NSArray *allChallenges = [[[[Challenges alloc] initWithTheme:theme] autorelease] challenges];
        if ([allChallenges count] == 0) {
            completedAllChallenges = NO;
        }
        for (Challenge *challenge in allChallenges) {
            if ([self isChallengeAccomplished:challenge.ident] == NO) {
                completedAllChallenges = NO;
            }
        }
        return completedAllChallenges;
    }
    return NO;
}


- (BOOL)isChallengeAccomplished:(NSString *)challengeIdent {
    NSArray *values = [[self.scores objectForKey:@"challenges"] objectForKey:challengeIdent];
    return ([values count] >= 1 && [[values objectAtIndex:0] unsignedIntValue] > 0);
}


- (NSUInteger)numberOfProcessedItemsOfChallenge:(NSString *)challengeIdent {
    NSArray *values = [[self.scores objectForKey:@"challenges"] objectForKey:challengeIdent];
    return ([values count] >= 2 ? [[values objectAtIndex:1] unsignedIntValue] : 0);
}


- (NSInteger)calculatorResultOfTheme:(NSString *)themeIdent {
    NSArray *values = [[self.scores objectForKey:@"calculators"] objectForKey:themeIdent];
    return ([values count] >= 1 ? [[values objectAtIndex:0] intValue] : 0);
}


- (NSInteger)calculatorItemCountOfTheme:(NSString *)themeIdent {
    NSArray *values = [[self.scores objectForKey:@"calculators"] objectForKey:themeIdent];
    return ([values count] >= 2 ? [[values objectAtIndex:1] intValue] : 0);
}


- (NSUInteger)accomplishedChallengeCount {
    NSUInteger count = 0;
    for (Theme *theme in [Themes sharedInstance].themes) {
        if (theme.state == ThemeStateReady) {
            NSArray *allChallenges = [[[[Challenges alloc] initWithTheme:theme] autorelease] challenges];
            for (Challenge *challenge in allChallenges) {
                if ([self isChallengeAccomplished:challenge.ident]) {
                    count++;
                }
            }
        }
    }
    return count;
}


- (NSUInteger)acceptedChallengeCount {
    NSUInteger count = 0;
    for (Theme *theme in [Themes sharedInstance].themes) {
        if (theme.state == ThemeStateReady) {
            Challenges *aChallenges = [[[Challenges alloc] initWithTheme:theme] autorelease];
            if (aChallenges.accepted) {
                count += [aChallenges.challenges count];
            }
        }
    }
    return count;
}


- (void)reportScore:(NSString *)challengeIdent values:(NSArray *)values {
    // Change immutable property list.
    NSMutableDictionary *mutableScores = [[self.scores mutableCopy] autorelease];
    if (mutableScores == nil) {
        mutableScores = [NSMutableDictionary dictionaryWithCapacity:1];
    }
    if ([mutableScores objectForKey:@"challenges"] == nil) {
        [mutableScores setObject:[NSDictionary dictionaryWithObject:values forKey:challengeIdent] forKey:@"challenges"];
    } else {
        NSMutableDictionary *mutableChallenges = [[mutableScores objectForKey:@"challenges"] mutableCopy];
        [mutableChallenges removeObjectForKey:challengeIdent];
        [mutableChallenges setObject:values forKey:challengeIdent];
        [mutableScores removeObjectForKey:@"challenges"];
        [mutableScores setObject:mutableChallenges forKey:@"challenges"];
        [mutableChallenges release];
    }
    self.scores = mutableScores;

    // Report to server.
    [[ScoreReporter sharedInstance] reportChallengeScoreForChallenge:challengeIdent];

    // Save property list to flash memory.
    [self.scores writeToFile:self.scoreFilename atomically:YES];
}


- (void)reportCalculatorResult:(NSString *)themeIdent result:(NSInteger)result count:(NSInteger)count {
    // Prepare values.
    NSArray *values = [NSArray arrayWithObjects:[NSNumber numberWithInt:result], [NSNumber numberWithInt:count], nil];

    // Change immutable property list.
    NSMutableDictionary *mutableScores = [[self.scores mutableCopy] autorelease];
    if (mutableScores == nil) {
        mutableScores = [NSMutableDictionary dictionaryWithCapacity:1];
    }
    if ([mutableScores objectForKey:@"calculators"] == nil) {
        [mutableScores setObject:[NSDictionary dictionaryWithObject:values forKey:themeIdent] forKey:@"calculators"];
    } else {
        NSMutableDictionary *mutableCalculator = [[mutableScores objectForKey:@"calculators"] mutableCopy];
        [mutableCalculator removeObjectForKey:themeIdent];
        [mutableCalculator setObject:values forKey:themeIdent];
        [mutableScores removeObjectForKey:@"calculators"];
        [mutableScores setObject:mutableCalculator forKey:@"calculators"];
        [mutableCalculator release];
    }
    self.scores = mutableScores;

    // Report to server.
    [[ScoreReporter sharedInstance] reportCalculatorResultForTheme:themeIdent];

    // Save property list to flash memory.
    [self.scores writeToFile:self.scoreFilename atomically:YES];
}


- (void)didDownloadScores:(BOOL)success friends:(NSArray *)aFriends challenges:(NSDictionary *)aChallenges worldwideChallenges:(NSUInteger)aWorldwideChallenges {
    if (success) {
        self.cannotDownloadScore = NO;
        self.friends = aFriends;
        self.challenges = aChallenges;
        self.worldwideChallenges = aWorldwideChallenges;
    } else {
        self.cannotDownloadScore = YES;
    }
    self.isDownloadingScore = NO;

    // Inform delegate about download error or new score.
    [self informDelegate];
}


- (void)downloadScore {
    if (self.delegate) {
        self.isDownloadingScore = YES;
        if (self.delegateThemeIdent) {
            [[ScoreReporter sharedInstance] downloadScoresForTheme:self.delegateThemeIdent];
        } else {
            [[ScoreReporter sharedInstance] downloadScoresForTheme:@"achievements"];
        }
    }
    [self informDelegate];
}


- (void)informDelegate {
    // NSLog(@"Score: isFacebookLoggedIn=%d cannotDownloadFacebookFriends=%d cannotDownloadScore:%d isDownloadingScore=%d friends=%u",
    //       [FacebookController sharedInstance].isLoggedIn, [FacebookController sharedInstance].cannotDownloadFriends, self.cannotDownloadScore, self.isDownloadingScore, [self.friends count]);
    [self.delegate newScoreStatus:[FacebookController sharedInstance].isLoggedIn
                    facebookError:[FacebookController sharedInstance].cannotDownloadFriends
                               error:self.cannotDownloadScore
                            progress:self.isDownloadingScore
                             friends:self.friends
                 worldwideChallenges:self.worldwideChallenges];
}


#pragma mark -
#pragma mark Facebook Protocol


- (void)newFacebookStatus:(BOOL)isLoggedIn
                    error:(BOOL)cannotDownloadFriends
                 progress:(BOOL)isDownloadingFriends
                  friends:(NSDictionary *)friends {
    if (isDownloadingFriends == NO) {
        // Download scores after Facebook controller has finished the download of the list of friends.
        // This will also inform the delegate about the new Facebook state.
        [self downloadScore];
    } else {
        // Inform delegate about new Facebook state.
        [self informDelegate];
    }
}


#pragma mark -
#pragma mark NSObject


+ (id)allocWithZone:(NSZone *)zone {
    if (sharedInstance == nil) {
        sharedInstance = [super allocWithZone:zone];
        return sharedInstance;
    }
    return nil;
}


- (id)copyWithZone:(NSZone *)zone {
    return self;
}


- (id)retain {
    return self;
}


- (NSUInteger)retainCount {
    // Object cannot be released.
    return NSUIntegerMax;
}


- (void)release {
    // Do nothing.
}


- (id)autorelease {
    return self;
}


@end
