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
#import "FacebookController.h"


@protocol ScoresProtocol <NSObject>

- (void)newScoreStatus:(BOOL)isFacebookLoggedIn
         facebookError:(BOOL)cannotDownloadFacebookFriends
                 error:(BOOL)cannotDownloadScore
              progress:(BOOL)isDownloadingScore
               friends:(NSArray *)friends
   worldwideChallenges:(NSUInteger)worldwideChallenges;

@end


#pragma mark -


// Singleton object.
@interface Scores: NSObject <FacebookProtocol> {
    id <ScoresProtocol> delegate;
    NSDictionary *challenges;
    NSArray *friends;
    NSDictionary *scores;
    NSUInteger worldwideChallenges;
    BOOL cannotDownloadScore;
    BOOL isDownloadingScore;
    NSString *delegateThemeIdent;
    NSString *scoreFilename;
}

+ (Scores *)sharedInstance;

@property (nonatomic, assign) id <ScoresProtocol> delegate;
@property (nonatomic, copy, readonly) NSDictionary *challenges;
@property (nonatomic, copy, readonly) NSArray *friends;
@property (nonatomic, copy, readonly) NSDictionary *scores;
@property (nonatomic, assign, readonly) NSUInteger worldwideChallenges;
@property (nonatomic, assign, readonly) BOOL cannotDownloadScore;
@property (nonatomic, assign, readonly) BOOL isDownloadingScore;

- (void)setDelegate:(id <ScoresProtocol>)aDelegate themeIdent:(NSString *)ident;

- (BOOL)isThemeAccomplished:(Theme *)theme;
- (BOOL)isChallengeAccomplished:(NSString *)challengeIdent;
- (NSUInteger)numberOfProcessedItemsOfChallenge:(NSString *)challengeIdent;
- (NSInteger)calculatorResultOfTheme:(NSString *)themeIdent;
- (NSInteger)calculatorItemCountOfTheme:(NSString *)themeIdent;
- (NSUInteger)accomplishedChallengeCount;
- (NSUInteger)acceptedChallengeCount;

// The values array contains by definition
//   0     = Challenge accomplished (yes = 1, no = 0).
//   1     = Number of processed items, i.e. pressed buttons, spin value or switch state.
//   2 - 9 = Multibutton states (normal = 0, pressed = 1).
- (void)reportScore:(NSString *)challengeIdent values:(NSArray *)values;

- (void)reportCalculatorResult:(NSString *)themeIdent result:(NSInteger)result count:(NSInteger)count;


// This method is called by object ScoreUploader.
- (void)didDownloadScores:(BOOL)success friends:(NSArray *)aFriends challenges:(NSDictionary *)aChallenges worldwideChallenges:(NSUInteger)aWorldwideChallenges;

@end
