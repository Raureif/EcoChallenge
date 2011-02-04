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

#import "Scores.h"
#import "Theme.h"
#import "Themes.h"
#import "FacebookController.h"
#import "NetworkActivity.h"
#import "ScoreReporter.h"


/* Upload and download scores from EcoChallenge server.
 * All Facebook IDs and device IDs are anonymized before they are
 * sent to the EcoChallenge server.
 */


@interface ScoreReporter ()

@property (nonatomic, copy) NSString *queueFilename;
@property (nonatomic, retain) NSMutableArray *queue;
@property (nonatomic, assign) NSRange uploadingRange;
@property (nonatomic, assign) NSString *downloadThemeScores;
@property (nonatomic, retain) NSURLConnection *connection;
@property (nonatomic, retain) NSMutableData *responseData;
@property (nonatomic, retain) NSTimer *timer;
@property (nonatomic, assign) BOOL hasGameCenter;

- (void)enqueue:(NSString *)action withIdent:(NSString *)ident;
- (void)startUpload;
- (void)closeConnection;
- (void)reportAchievements;
- (void)applicationWillEnterForeground:(NSNotification *)notification;
- (void)applicationDidEnterBackground:(NSNotification *)notification;
- (void)playerAuthenticationDidChange:(NSNotification *)notification;

NSString *md5(NSString *input);

@end


#pragma mark -


@implementation ScoreReporter

@synthesize queueFilename;
@synthesize queue;
@synthesize uploadingRange;
@synthesize downloadThemeScores;
@synthesize connection;
@synthesize responseData;
@synthesize timer;
@synthesize hasGameCenter;


#define SCORE_URL          @"http://user.eco-challenge.eu/github/score"
#define MAX_DOWNLOAD_SIZE  (256 * 1024)
#define REPORTING_DELAY    5


static ScoreReporter *sharedInstance = nil;


+ (ScoreReporter *)sharedInstance {
    if (sharedInstance == nil) {

        // Create singleton object.
        sharedInstance = [[ScoreReporter alloc] init];

        // Read queue from flash memory.
        sharedInstance.queueFilename = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]
                                        stringByAppendingPathComponent: @"UploadQueue.plist"];
        sharedInstance.queue = [NSMutableArray arrayWithContentsOfFile:sharedInstance.queueFilename];
        if (sharedInstance.queue == nil) {
            sharedInstance.queue = [NSMutableArray arrayWithCapacity:20];
        }

        // Register for iOS multitasking events.
        if ([[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)] && [UIDevice currentDevice].multitaskingSupported) {
            [[NSNotificationCenter defaultCenter] addObserver:sharedInstance selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:sharedInstance selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        }

        // Test if Game Center is available, as documented by Apple.
        sharedInstance.hasGameCenter = (NSClassFromString(@"GKLocalPlayer") && [[[UIDevice currentDevice] systemVersion] compare:@"4.1" options:NSNumericSearch] != NSOrderedAscending);

        // Authenticate local player.
        if (sharedInstance.hasGameCenter) {
            [sharedInstance playerAuthenticationDidChange:nil];
            [[NSNotificationCenter defaultCenter] addObserver:sharedInstance selector:@selector(playerAuthenticationDidChange:) name:GKPlayerAuthenticationDidChangeNotificationName object:nil];
        }
    }
    return sharedInstance;
}


- (void)reportPushNotificationToken:(NSString *)token {
    [self enqueue:@"apns" withIdent:token];
}


- (void)reportCalculatorResultForTheme:(NSString *)themeIdent {
    [self enqueue:@"calculator" withIdent:themeIdent];
}


- (void)reportChallengeScoreForChallenge:(NSString *)challengeIdent {
    [self enqueue:@"challenge" withIdent:challengeIdent];
}


- (void)downloadScoresForTheme:(NSString *)themeIdent {
    self.downloadThemeScores = themeIdent;
    // The user is waiting. Cancel current request.
    [self closeConnection];
    // Stop timer.
    [self.timer invalidate];
    self.timer = nil;
    // Start new request immediately.
    [self startUpload];
}


- (void)enqueue:(NSString *)action withIdent:(NSString *)ident {
    // Avoid duplicates. Use placeholders instead of removing objectes so self.uploadingRange remains valid.
    if ([action isEqualToString:@"apns"]) {
        for (NSUInteger i = 0; i < [self.queue count]; i++) {
            if ([[[self.queue objectAtIndex:i] objectAtIndex:0] isEqualToString:action]) {
                [self.queue replaceObjectAtIndex:i withObject:[NSArray arrayWithObjects:@"", @"", nil]];
                break;
            }
        }
    } else {
        for (NSUInteger i = 0; i < [self.queue count]; i++) {
            if ([[[self.queue objectAtIndex:i] objectAtIndex:0] isEqualToString:action] && [[[self.queue objectAtIndex:i] objectAtIndex:1] isEqualToString:ident]) {
                [self.queue replaceObjectAtIndex:i withObject:[NSArray arrayWithObjects:@"", @"", nil]];
                break;
            }
        }
    }

    [self.queue addObject:[NSArray arrayWithObjects:action, ident, nil]];

    // Save queue to flash memory.
    [self.queue writeToFile:self.queueFilename atomically:YES];

    if (self.connection == nil) {
        // Start timer.
        [self.timer invalidate];
        self.timer = [NSTimer scheduledTimerWithTimeInterval:REPORTING_DELAY target:self selector:@selector(startUpload) userInfo:nil repeats:NO];
    }
}


- (void)startUpload {
    NSAssert(connection == nil, @"Another request is already performed.");
    if (connection) return;

    // Clean up timer.
    [self.timer invalidate];
    self.timer = nil;

    // Mark range in queue.
    self.uploadingRange = NSMakeRange(0, [self.queue count]);

    // Prepare URL-encoded string.
    NSMutableString *param = [NSMutableString stringWithCapacity:4096];

    // Append anonymized device ID to URL-encoded string.
    [param appendFormat:@"device=%@", md5([[UIDevice currentDevice] uniqueIdentifier])];

    if (self.downloadThemeScores) {
        // Append theme filter to URL-encoded string.
        [param appendFormat:@"&filter=%@", self.downloadThemeScores];

        // Append anonymized Facebook ID to URL-encoded string.
        NSString *facebookID = [FacebookController sharedInstance].facebookID;
        if ([facebookID length] > 0) {
            [param appendFormat:@"&facebook=%@", md5(facebookID)];
        }

        // Append anonymized Facebook IDs of friends to URL-encoded string.
        NSArray *anonymizedIDs = [[FacebookController sharedInstance].friends allKeys];
        for (NSUInteger i = 0; i < [anonymizedIDs count]; i++) {
            [param appendFormat:@"&friends%%5B%u%%5D=%@", i, [anonymizedIDs objectAtIndex:i]];
        }
    }

    for (NSArray *entry in self.queue) {
        NSString *action = [entry objectAtIndex:0];
        NSString *ident = [entry objectAtIndex:1];

        // Skip placeholders.
        if ([action isEqualToString:@""] && [ident isEqualToString:@""]) continue;

        if ([action isEqualToString:@"apns"]) {

            // Append push notification token to URL-encoded string.
            [param appendFormat:@"&apns=%@&sandbox=%u", ident,
#ifdef DEBUG
             1];
#else
             0];
#endif

        } else if ([action isEqualToString:@"calculator"]) {

            // Append calculator result to URL-encoded string.
            [param appendFormat:@"&calculator%%5B%@%%5D%%5B0%%5D=%d&calculator%%5B%@%%5D%%5B1%%5D=%d",
             ident, [[Scores sharedInstance] calculatorResultOfTheme:ident],
             ident, [[Scores sharedInstance] calculatorItemCountOfTheme:ident]];

        } else if ([action isEqualToString:@"challenge"]) {

            // Append challenge scores to URL-encoded string.
            [param appendFormat:@"&challenge%%5B%@%%5D%%5B0%%5D=%u&challenge%%5B%@%%5D%%5B1%%5D=%u",
                ident, [[Scores sharedInstance] isChallengeAccomplished:ident],
                ident, [[Scores sharedInstance] numberOfProcessedItemsOfChallenge:ident]];

        } else {
            NSAssert(NO, @"Invalid action.");
        }
    }

    // Show network activity indicator.
    [NetworkActivity sharedInstance].activityCounter++;

    // Request scores from EcoChallenge server.
    self.responseData = [NSMutableData data];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:SCORE_URL]];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [request setTimeoutInterval:15];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[param dataUsingEncoding:NSUTF8StringEncoding]];
    [[NetworkActivity sharedInstance] logURL:request.URL];
    self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
}


- (void)closeConnection {
    // Cancel connection and clean up.
    if (self.connection) {
        [self.connection cancel];
        self.connection = nil;

        // Hide network activity indicator.
        [NetworkActivity sharedInstance].activityCounter--;
    }
    self.responseData = nil;
}


- (void)reportAchievements {
    // Report all achievements for all themes.
    if (sharedInstance.hasGameCenter && [GKLocalPlayer localPlayer].authenticated) {
        for (Theme *theme in [Themes sharedInstance].themes) {
            if ([[Scores sharedInstance] isThemeAccomplished:theme]) {
                NSString *ident = [theme.ident stringByReplacingOccurrencesOfString:@"-" withString:@"."];
                GKAchievement *achievement = [[[GKAchievement alloc] initWithIdentifier:ident] autorelease];
                if (achievement) {
                    achievement.percentComplete = 100;
                    [achievement reportAchievementWithCompletionHandler:^(NSError *error) {}];
                }
            }
        }
    }
}


- (void)applicationWillEnterForeground:(NSNotification *)notification {
    // If necessary, re-authenticate local player.
    if (self.hasGameCenter) {
        [sharedInstance playerAuthenticationDidChange:nil];
    }

    // If the queue is not empty, start new request.
    if ([self.queue count] > 0) {
        [self startUpload];
    }
}


- (void)applicationDidEnterBackground:(NSNotification *)notification {
    // Stop timer.
    [self.timer invalidate];
    self.timer = nil;

    // Cancel download
    [self closeConnection];
}


- (void)playerAuthenticationDidChange:(NSNotification *)notification {
    // Authenticate local player.
    if (sharedInstance.hasGameCenter && [GKLocalPlayer localPlayer].authenticated == NO) {
        [[GKLocalPlayer localPlayer] authenticateWithCompletionHandler:^(NSError *error) {
            if (error == nil) {
                [self reportAchievements];
            }
        }];
    }
}


NSString *md5(NSString *input) {
    const char *c_input = [input UTF8String];
    unsigned char c_md5[CC_MD5_DIGEST_LENGTH];
    CC_MD5(c_input, strlen(c_input), c_md5);
    NSMutableString *result = [NSMutableString stringWithCapacity:(CC_MD5_DIGEST_LENGTH * 2)];
    for (NSUInteger i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [result appendFormat:@"%02x", c_md5[i]];
    }
    return result;
}


#pragma mark -
#pragma mark NSURLConnection delegate


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    if ([response expectedContentLength] <= MAX_DOWNLOAD_SIZE) {
        // Reset response data.
        [self.responseData setLength:0];
    } else {
        // Call error handler.
        NSError *error = [NSError errorWithDomain:@"EcoChallenge" code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Server reply is too large.", NSLocalizedDescriptionKey, nil]];
        [self connection:self.connection didFailWithError:error];
    }
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    if ([self.responseData length] + [data length] <= MAX_DOWNLOAD_SIZE) {
        // Concatenate response data.
        [self.responseData appendData:data];
    } else {
        // Call error handler.
        NSError *error = [NSError errorWithDomain:@"EcoChallenge" code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Server reply is too large.", NSLocalizedDescriptionKey, nil]];
        [self connection:self.connection didFailWithError:error];
    }
}


- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
#ifdef DEBUG
    NSLog(@"Cannot request file score: %@", [error localizedDescription]);
#endif
    // Clean up.
    [self closeConnection];
    self.downloadThemeScores = nil;

    // Start retransmission timer.
    [self.timer invalidate];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:(5 * 60) target:self selector:@selector(startUpload) userInfo:nil repeats:NO];
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // Parse response data.
    NSDictionary *plist;
    if ([NSPropertyListSerialization respondsToSelector:@selector(propertyListWithData:options:format:error:)]) {
        NSError *error = nil;
        plist = (NSDictionary *)[NSPropertyListSerialization propertyListWithData:responseData options:0 format:NULL error:&error];
    } else {
        NSString *error = nil;
        plist = (NSDictionary *)[NSPropertyListSerialization propertyListFromData:responseData mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:&error];
        [error release];
    }

    // Clean up.
    [self closeConnection];

    if ([plist isKindOfClass:[NSDictionary class]]) {
        NSMutableArray *friends = [NSMutableArray arrayWithCapacity:[plist count]];
        NSMutableDictionary *challenges = nil;
        NSUInteger worldwideChallenges = 0;

        // Validate server response.
        for (NSString *key in [plist allKeys]) {
            if ([key isEqualToString:@"accomplished"]) {
                id object = [plist objectForKey:key];
                if ([object isKindOfClass:[NSNumber class]]) {
                    worldwideChallenges = [object unsignedIntValue];
                }
            } else {
                NSDictionary *score = [plist objectForKey:key];
                if ([score isKindOfClass:[NSDictionary class]]) {
                    if ([key isEqualToString:@"challenges"]) {

                        challenges = [NSMutableDictionary dictionaryWithCapacity:[score count]];
                        for (NSString *ident in score) {
                            NSArray *items = [score objectForKey:ident];
                            if ([items isKindOfClass:[NSArray class]] && [items count] == 2 &&
                                [[items objectAtIndex:0] isKindOfClass:[NSNumber class]] && [[items objectAtIndex:1] isKindOfClass:[NSNumber class]]) {
                                [challenges setObject:items forKey:ident];
                            }
                        }

                    } else {

                        BOOL valid = YES;
                        for (NSString *ident in score) {
                            // Calculator result?
                            if ([ident length] == 10 /* xxxx-xx-xx */) {
                                NSArray *items = [score objectForKey:ident];
                                valid = ([items isKindOfClass:[NSArray class]] && [items count] == 2 &&
                                         [[items objectAtIndex:0] isKindOfClass:[NSNumber class]] && [[items objectAtIndex:1] isKindOfClass:[NSNumber class]]);
                                break;
                                // Challenge results.
                            } else {
                                NSNumber *items = [score objectForKey:ident];
                                valid = ([items isKindOfClass:[NSNumber class]]);
                                break;
                            }
                        }
                        if (valid) {
                            // Associate the reported friend scores with the known friends.
                            NSMutableDictionary *friendInfo = [[FacebookController sharedInstance].friends objectForKey:key];
                            if (friendInfo) {
                                friendInfo = [friendInfo mutableCopy];
                                [friendInfo setObject:score forKey:@"scores"];
                                [friends addObject:friendInfo];
                                [friendInfo release];
                            }
                        }
                    }
                }
            }
        }

        // Sort friends by name.
        NSSortDescriptor *sortDescriptor1 = [[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES] autorelease];
        NSSortDescriptor *sortDescriptor2 = [[[NSSortDescriptor alloc] initWithKey:@"id" ascending:YES] autorelease];
        [friends sortUsingDescriptors:[NSArray arrayWithObjects:sortDescriptor1, sortDescriptor2, nil]];

        if ([self.queue count] > self.uploadingRange.length) {
            // In the meantime new items where added to the queue. Start timer.
            [self.timer invalidate];
            self.timer = [NSTimer scheduledTimerWithTimeInterval:REPORTING_DELAY target:self selector:@selector(startUpload) userInfo:nil repeats:NO];
        }

        // Remove completed items from queue.
        [self.queue removeObjectsInRange:self.uploadingRange];
        self.uploadingRange = NSMakeRange(0, 0);

        // Save queue to flash memory.
        [self.queue writeToFile:self.queueFilename atomically:YES];

        // Inform Scores object about results.
        if (self.downloadThemeScores) {
            self.downloadThemeScores = nil;
            [[Scores sharedInstance] didDownloadScores:YES friends:friends challenges:challenges worldwideChallenges:worldwideChallenges];
        }

        // Report achievements to Game Center.
        [self reportAchievements];

    } else {
#ifdef DEBUG
        NSLog(@"Cannot request file score: Unsupported file format.");
#endif
        // Inform Scores object about error.
        [[Scores sharedInstance] didDownloadScores:NO friends:nil challenges:nil worldwideChallenges:0];

        // Start retransmission timer.
        [self.timer invalidate];
        self.timer = [NSTimer scheduledTimerWithTimeInterval:(5 * 60) target:self selector:@selector(startUpload) userInfo:nil repeats:NO];
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
