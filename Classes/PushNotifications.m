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
#import "Themes.h"
#import "Challenge.h"
#import "Challenges.h"
#import "Scores.h"
#import "ScoreReporter.h"
#import "PushNotifications.h"


@interface PushNotifications ()

@property (nonatomic, copy) NSString *token;

- (void)setApplicationBadge;
- (void)applicationDidEnterBackground:(NSNotification *)notification;
- (void)applicationWillTerminate:(NSNotification *)notification;

@end


#pragma mark -


@implementation PushNotifications

@synthesize token;
@synthesize enabled;


static PushNotifications *sharedInstance = nil;


+ (PushNotifications *)sharedInstance {
    if (sharedInstance == nil) {

        // Create singleton object.
        sharedInstance = [[PushNotifications alloc] init];

        // Set icon badge.
        [sharedInstance setApplicationBadge];

        // Register for iOS multitasking events.
        if ([[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)] && [UIDevice currentDevice].multitaskingSupported) {
            [[NSNotificationCenter defaultCenter] addObserver:sharedInstance selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        }

        // Register for application termination event.
        [[NSNotificationCenter defaultCenter] addObserver:sharedInstance selector:@selector(applicationWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];

#if !TARGET_IPHONE_SIMULATOR
        // Only register for push notifications at application start if they were already registered
        // before, because we want the confirmation box to be shown on the challenge list view.
        if (sharedInstance.enabled) {
            [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
        }
#endif
    }
    return sharedInstance;
}


- (BOOL)enabled {
    return ([[UIApplication sharedApplication] enabledRemoteNotificationTypes] != UIRemoteNotificationTypeNone);
}


- (void)setEnabled:(BOOL)setEnabled {
#if !TARGET_IPHONE_SIMULATOR
    if (setEnabled) {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
    }
#endif
}


- (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSString *newToken = [[[deviceToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]]
                          stringByReplacingOccurrencesOfString:@" " withString:@""];

    // Test if the token is new, i.e. it must not have been sent already since the app started.
    if ([self.token isEqualToString:newToken] == NO) {
        self.token = newToken;
        // Send token to server.
        [[ScoreReporter sharedInstance] reportPushNotificationToken:token];
    }
}


- (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"Failed to register for push notifications: %@", [error localizedDescription]);
}


- (void)didReceiveRemoteNotification:(NSDictionary *)userInfo {
    // Get update check parameter from push notification.
    if ([[userInfo objectForKey:@"update"] unsignedIntValue]) {
        [[Themes sharedInstance] checkForUpdatesNow];
    }
}


- (void)setApplicationBadge {
    NSUInteger openChallenges = 0;
    for (Theme *theme in [Themes sharedInstance].themes) {
        if (theme.state == ThemeStateReady) {
            Challenges *challenges = [[Challenges alloc] initWithTheme:theme];
            if (challenges.accepted > 0) {
                for (Challenge *challenge in challenges.challenges) {
                    if (challenge.state == ChallengeStateRunning && [[Scores sharedInstance] isChallengeAccomplished:challenge.ident] == NO) {
                        openChallenges++;
                    }
                }
            }
            [challenges release];
        }
    }
    [UIApplication sharedApplication].applicationIconBadgeNumber = openChallenges;
}


- (void)applicationDidEnterBackground:(NSNotification *)notification {
    [self setApplicationBadge];
}


- (void)applicationWillTerminate:(NSNotification *)notification {
    [self setApplicationBadge];
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
