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


// Singleton object.
@interface ScoreReporter: NSObject <NSURLConnectionDataDelegate, NSURLConnectionDelegate> {
    NSString *queueFilename;
    NSMutableArray *queue;
    NSRange uploadingRange;
    NSString *downloadThemeScores;
    NSURLConnection *connection;
    NSMutableData *responseData;
    NSTimer *timer;
    BOOL hasGameCenter;
}

+ (ScoreReporter *)sharedInstance;

- (void)reportPushNotificationToken:(NSString *)token;
- (void)reportCalculatorResultForTheme:(NSString *)themeIdent;
- (void)reportChallengeScoreForChallenge:(NSString *)challengeIdent;
- (void)downloadScoresForTheme:(NSString *)themeIdent;
- (NSString *)deviceId;

@end
