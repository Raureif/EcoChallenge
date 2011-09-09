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

#import "NetworkActivity.h"
#import "FacebookController.h"


/* Login to Facebook, load own Facebook ID and load list of friends.
 *
 * The list of friends will only be loaded at the moment when a delegate
 * is set or when the application enteres foreground mode (and a delegate
 * is set). To spare Facebooks's servers the list of friends will be
 * cached for 10 minutes. Errors are only cached for 2 minutes.
 */


@interface FacebookController ()

@property (nonatomic, copy, readwrite) NSDictionary *friends;
@property (nonatomic, assign,readwrite) BOOL cannotDownloadFriends;
@property (nonatomic, assign, readwrite) BOOL isDownloadingFriends;
@property (nonatomic, retain) Facebook *facebook;
@property (nonatomic, copy) NSString *cacheFile;

- (void)downloadFriends;
- (void)informDelegate;
- (void)applicationWillEnterForeground:(NSNotification *)notification;

@end


#pragma mark -


@implementation FacebookController

@synthesize delegate;
@synthesize friends;
@synthesize isDownloadingFriends;
@synthesize cannotDownloadFriends;
@synthesize facebook;
@synthesize cacheFile;


#define NORMAL_CACHE_AGE  (10 * 60)
#define ERROR_CACHE_AGE   (2 * 60)


static FacebookController *sharedInstance = nil;


+ (FacebookController *)sharedInstance {
    if (sharedInstance == nil) {

        // Create singleton object.
        sharedInstance = [[FacebookController alloc] init];

        // Read Facebook App ID from file Info.plist.
        NSString *appId = [[[[[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleURLTypes"] objectAtIndex:0] objectForKey:@"CFBundleURLSchemes"] objectAtIndex:0] substringFromIndex:2];

        // Create FBConnect object.
        sharedInstance.facebook = [[[Facebook alloc] initWithAppId:appId] autorelease];

        // Try to restore Facebook session.
        NSString *accessToken = [[NSUserDefaults standardUserDefaults] stringForKey:@"facebookAccessToken"];
        NSDate *expirationDate = [NSDate dateWithTimeIntervalSince1970:[[NSUserDefaults standardUserDefaults] doubleForKey:@"facebookExpirationDate"]];
        if ([accessToken length] > 0 && [expirationDate compare:[NSDate date]] == NSOrderedDescending) {
            sharedInstance.facebook.accessToken = accessToken;
            sharedInstance.facebook.expirationDate = expirationDate;
            sharedInstance.facebook.sessionDelegate = sharedInstance;
        }

        // Remove cached Facebook ID if session cannot be restored.
        if ([sharedInstance.facebook isSessionValid] == NO) {
            [[NSUserDefaults standardUserDefaults] setObject:@"" forKey:@"facebookID"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }

        // Load cached friends.
        sharedInstance.cacheFile = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]
                                    stringByAppendingPathComponent: @"FacebookFriends.plist"];
        sharedInstance.friends = [NSDictionary dictionaryWithContentsOfFile:sharedInstance.cacheFile];

        // Register for iOS multitasking events.
        if ([[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)] && [UIDevice currentDevice].multitaskingSupported) {
            [[NSNotificationCenter defaultCenter] addObserver:sharedInstance selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
        }
    }
    return sharedInstance;
}


- (void)setDelegate:(id <FacebookProtocol>)aDelegate {
    if (delegate != aDelegate) {

        NSAssert(delegate == nil || aDelegate == nil, @"Delegate is already set.");

        delegate = aDelegate;

        if (delegate) {
            // Start download process and inform delegate about current state.
            [self downloadFriends];
        }
    }
}


- (BOOL)isLoggedIn {
    return [self.facebook isSessionValid];
}


- (NSString *)facebookID {
    return [[NSUserDefaults standardUserDefaults] stringForKey:@"facebookID"];
}


- (BOOL)handleOpenURL:(NSURL *)url {
    return [self.facebook handleOpenURL:url];
}


- (void)login {
    if (self.facebook.isSessionValid) {
        // Call login handler directly.
        [self fbDidLogin];
    } else {
        // Show login dialog.
        [self.facebook authorize:[NSArray arrayWithObjects:@"offline_access", nil] delegate:self];
    }
}


- (void)logout {
    [self.facebook logout:self];
}


- (void)downloadFriends {
    // Start download process if the Facebook session is valid, a delegate is set, no other
    // download is currently performed, no previous successful download has been performed within the
    // last 10 minutes (spare the Facebook servers) and the application is running in foreground
    // mode (FBConnect methods cannot be cancelled and might call this method after the application
    // has entered background mode).

    if ([self isLoggedIn] && self.delegate && self.isDownloadingFriends == NO) {

        if ([[UIApplication sharedApplication] respondsToSelector:@selector(applicationState)] && [UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {

            // Set error flag.
            self.cannotDownloadFriends = YES;

        } else if (self.friends == nil &&
                   time(NULL) < [[NSUserDefaults standardUserDefaults] integerForKey:@"lastFacebookFriendsDownload"] + ERROR_CACHE_AGE) {

            // Set error flag.
            self.cannotDownloadFriends = YES;

        } else if (self.friends == nil ||
                   time(NULL) >= [[NSUserDefaults standardUserDefaults] integerForKey:@"lastFacebookFriendsDownload"] + NORMAL_CACHE_AGE) {

            // Remove cached friends.
            [[NSFileManager defaultManager] removeItemAtPath:self.cacheFile error:NULL];
            self.friends = nil;

            // Clear error flag.
            self.cannotDownloadFriends = NO;

            // FBRequest starts.
            self.isDownloadingFriends = YES;

            // Show network activity indicator.
            [NetworkActivity sharedInstance].activityCounter++;

            // Store timestamp of download.
            [[NSUserDefaults standardUserDefaults] setInteger:time(NULL) forKey:@"lastFacebookFriendsDownload"];
            [[NSUserDefaults standardUserDefaults] synchronize];

            // Get own Facebook ID if it has not been cached yet.
            NSString *facebookID = [[NSUserDefaults standardUserDefaults] stringForKey:@"facebookID"];
            if ([facebookID length] > 0) {
                // Call request handler directly.
                [self request:nil didLoad:[NSDictionary dictionaryWithObjectsAndKeys:facebookID, @"id", nil]];
            } else {
                // Request user ID.
                [self.facebook requestWithGraphPath:@"me" andDelegate:self];
            }
        }
    }

    [self informDelegate];
}


- (void)informDelegate {
    // NSLog(@"Facebook: isLoggedIn=%d cannotDownloadFriends=%d isDownloadingFriends=%d friends=%u",
    //       self.isLoggedIn, self.cannotDownloadFriends, self.isDownloadingFriends, [self.friends count]);
    [self.delegate newFacebookStatus:self.isLoggedIn
                               error:self.cannotDownloadFriends
                            progress:self.isDownloadingFriends
                             friends:self.friends];
}


- (void)applicationWillEnterForeground:(NSNotification *)notification {
    // Start download process after [UIApplication sharedApplication].applicationState has been set to UIApplicationStateActive.
    [self performSelector:@selector(downloadFriends) withObject:nil afterDelay:0];
}


#pragma mark -
#pragma mark FBSession delegate


- (void)fbDidLogin {
    // Save Facebook session.
    if ([self.facebook.accessToken length] > 0 && self.facebook.expirationDate) {
        [[NSUserDefaults standardUserDefaults] setObject:self.facebook.accessToken forKey:@"facebookAccessToken"];
        [[NSUserDefaults standardUserDefaults] setDouble:[self.facebook.expirationDate timeIntervalSince1970] forKey:@"facebookExpirationDate"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }

    // Start download process and inform delegate about new state.
    [self downloadFriends];
}


- (void)fbDidLogout {
    // Remove Facebook session.
    [[NSUserDefaults standardUserDefaults] setObject:@"" forKey:@"facebookAccessToken"];
    [[NSUserDefaults standardUserDefaults] setDouble:0 forKey:@"facebookExpirationDate"];
    [[NSUserDefaults standardUserDefaults] setObject:@"" forKey:@"facebookID"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    // Inform delegate about new state.
    [self informDelegate];
}


#pragma mark -
#pragma mark FBRequest delegate


- (void)request:(FBRequest *)request didLoad:(id)result {
    // Hide network activity indicator.
    [NetworkActivity sharedInstance].activityCounter--;

    // FBRequest stops.
    self.isDownloadingFriends = NO;

    // FBConnect methods cannot be cancelled so this method might be called after the application has entered background mode.
    if (self.delegate == nil || ([[UIApplication sharedApplication] respondsToSelector:@selector(applicationState)] && [UIApplication sharedApplication].applicationState == UIApplicationStateBackground)) {

        // Set error flag.
        self.cannotDownloadFriends = YES;

    } else if ([result isKindOfClass:[NSDictionary class]]) {

        NSString *facebookID = [result objectForKey:@"id"];
        if ([facebookID isKindOfClass:[NSString class]]) {

            // Store own Facebook ID.
            [[NSUserDefaults standardUserDefaults] setObject:facebookID forKey:@"facebookID"];
            [[NSUserDefaults standardUserDefaults] synchronize];

            // FBRequest starts.
            self.isDownloadingFriends = YES;

            // Show network activity indicator.
            [NetworkActivity sharedInstance].activityCounter++;

            // Request friends. Use FQL instead of the newer Graph API because it only requires one request.
            NSString *fql = [NSString stringWithFormat:@"SELECT uid, name, first_name FROM user WHERE uid IN (SELECT uid2 FROM friend WHERE uid1 = %@)", facebookID];
            NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObject:fql forKey:@"query"];
            [self.facebook requestWithMethodName: @"fql.query" andParams:params andHttpMethod:@"GET" andDelegate:self];

        } else {
            // Set error flag.
            self.cannotDownloadFriends = YES;
#ifdef DEBUG
            NSLog(@"Cannot request Facebook API: Unsupported file format.");
#endif
        }

    } else if ([result isKindOfClass:[NSArray class]]) {

        NSMutableDictionary *mutableFriends = [NSMutableDictionary dictionaryWithCapacity:[result count]];

        // Create list of friends from Facebook reply.
        for (NSDictionary *entry in result) {
            if ([entry isKindOfClass:[NSDictionary class]]) {
                NSNumber *facebookID = [entry objectForKey:@"uid"];
                NSString *name = [entry objectForKey:@"name"];
                NSString *firstName = [entry objectForKey:@"first_name"];
                if ([facebookID isKindOfClass:[NSNumber class]] && [name isKindOfClass:[NSString class]] && [firstName isKindOfClass:[NSString class]]) {

                    // Generate anonymized ID.
                    const char *c_facebookID = [[facebookID stringValue] UTF8String];
                    unsigned char c_md5[CC_MD5_DIGEST_LENGTH];
                    CC_MD5(c_facebookID, strlen(c_facebookID), c_md5);
                    NSMutableString *anonymizedID = [NSMutableString stringWithCapacity:(CC_MD5_DIGEST_LENGTH * 2)];
                    for (NSUInteger i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
                        [anonymizedID appendFormat:@"%02x", c_md5[i]];
                    }

                    // Add all information to friend list.
                    NSMutableDictionary *friend = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                   [facebookID stringValue], @"id",
                                                   anonymizedID,             @"anonymizedID",
                                                   name,                     @"name",
                                                   firstName,                @"firstName",
                                                   nil];
                    [mutableFriends setObject:friend forKey:anonymizedID];
                }
            }
        }

        self.friends = mutableFriends;

        // Write friends to flash memory.
        [self.friends writeToFile:self.cacheFile atomically:YES];

        // Unset error flag.
        self.cannotDownloadFriends = NO;

    } else {
        // Set error flag.
        self.cannotDownloadFriends = YES;
#ifdef DEBUG
        NSLog(@"Cannot request Facebook API: Unsupported file format.");
#endif
    }

    // Inform delegate about download error or new friends.
    [self informDelegate];
}


- (void)request:(FBRequest *)request didFailWithError:(NSError *)error {
#ifdef DEBUG
    NSLog(@"Cannot request Facebook API: %@", [error localizedDescription]);
#endif

    // Hide network activity indicator.
    [NetworkActivity sharedInstance].activityCounter--;

    // FBRequest stops.
    self.isDownloadingFriends = NO;

    // Set error flag.
    self.cannotDownloadFriends = YES;

    // Inform delegate about error.
    [self informDelegate];
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


- (oneway void)release {
    // Do nothing.
}


- (id)autorelease {
    return self;
}


@end
