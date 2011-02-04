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

#import "ScoreReporter.h"
#import "Realtime.h"
#import "PushNotifications.h"
#import "FacebookController.h"
#import "MainViewController.h"
#import "Application.h"


@implementation Application

@synthesize window;


#pragma mark -
#pragma mark UIApplication delegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Load defaults.
    [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"UserDefaults" ofType:@"plist"]]];
    [[NSUserDefaults standardUserDefaults] synchronize];

    // Initialize random number generator.
    srandom(time(NULL));

    // Create shared object, which will authenticate the player in Game Center.
    [ScoreReporter sharedInstance];

    // Create shared object which will enable remote push notifications.
    [PushNotifications sharedInstance];

    // Create shared object which will try to restore Facebook session.
    [FacebookController sharedInstance];

    // Create shared object which will start a timer.
    [Realtime sharedInstance];

    // Has the app been launched with a parameter?
    if ([launchOptions objectForKey:@"UIApplicationLaunchOptionsRemoteNotificationKey"]) {
        [[PushNotifications sharedInstance] didReceiveRemoteNotification:[launchOptions objectForKey:@"UIApplicationLaunchOptionsRemoteNotificationKey"]];
    } else if ([launchOptions objectForKey:@"UIApplicationLaunchOptionsURLKey"]) {
        [[FacebookController sharedInstance] handleOpenURL:[launchOptions objectForKey:@"UIApplicationLaunchOptionsURLKey"]];
    }

    // Add main view controller.
    [MainViewController sharedInstance].view.frame = [UIScreen mainScreen].applicationFrame;
    [self.window addSubview:[MainViewController sharedInstance].view];

    // Start the show.
    [self.window makeKeyAndVisible];
    return YES;
}


- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [[PushNotifications sharedInstance] didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}


- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    [[PushNotifications sharedInstance] didFailToRegisterForRemoteNotificationsWithError:error];
}


- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [[PushNotifications sharedInstance] didReceiveRemoteNotification:userInfo];
}


- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    return [[FacebookController sharedInstance] handleOpenURL:url];
}


@end
