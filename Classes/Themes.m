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
#import "Realtime.h"
#import "Theme.h"
#import "ThemeDownloader.h"
#import "Themes.h"


/* Immediately after application start up, immediately after the application entered
 * foreground mode, and once every five minutes of runtime a test is performed whether
 * the last successful update check is older than one hour. If so, the online update
 * check is performed. Therefore, if the update check fails, it will be re-tried
 * every five minutes.
 *
 * The network status indicator will only be activated if the delegate is set.
 */


@interface Themes ()

@property (nonatomic, copy) NSArray *allThemes;
@property (nonatomic, assign) NSInteger version;
@property (nonatomic, retain) NSURLConnection *connection;
@property (nonatomic, retain) NSMutableData *responseData;

- (void)closeConnection;
- (void)readThemesFromFlash;
- (void)applicationDidEnterBackground:(NSNotification *)notification;
- (void)clockDidChange:(NSNotification *)notification;

@end


#pragma mark -


@implementation Themes

@synthesize allThemes;
@synthesize delegate;
@synthesize version;
@synthesize connection;
@synthesize responseData;


#define DOWNLOAD_URL       @"http://update.eco-challenge.eu/github/themes-de.plist"
#define MAX_DOWNLOAD_SIZE  (512 * 1024)
#define CACHE_AGE          (60 * 60)


static Themes *sharedInstance = nil;


+ (Themes *)sharedInstance {
    if (sharedInstance == nil) {

        // Create singleton object.
        sharedInstance = [[Themes alloc] init];

        // Read themes from flash.
        [sharedInstance readThemesFromFlash];

        // Register for iOS multitasking events.
        if ([[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)] && [UIDevice currentDevice].multitaskingSupported) {
            [[NSNotificationCenter defaultCenter] addObserver:sharedInstance selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        }

        // Register for clock change events.
        [[NSNotificationCenter defaultCenter] addObserver:sharedInstance selector:@selector(clockDidChange:) name:EcoChallengeClockDidChangeNotficiation object:nil];

        // Start update check.
        [sharedInstance clockDidChange:nil];
    }
    return sharedInstance;
}


- (void)setDelegate:(id <ThemesProtocol>)aDelegate {
    if (delegate != aDelegate) {

        NSAssert(delegate == nil || aDelegate == nil, @"Delegate is already set.");

        delegate = aDelegate;

        // Show or hide network activity indicator if delegate is set resp. not set.
        if (self.connection) {
            if (delegate) {
                [NetworkActivity sharedInstance].activityCounter++;
            } else {
                [NetworkActivity sharedInstance].activityCounter--;
            }
        }

        // Reset all download errors.
        for (NSUInteger i = 0; i < self.allThemes.count; i++) {
            Theme *theme = [self.allThemes objectAtIndex:i];
            theme.error = nil;
        }

        // Push themes to delegate.
        [delegate refreshThemeList:self.themes];
    }
}


- (NSArray *)themes {
    NSTimeInterval timeRef = [Realtime sharedInstance].timeRef;
    BOOL hasAddedTeaser = NO;
    NSMutableArray *themes = [NSMutableArray arrayWithCapacity:self.allThemes.count];

    // Filter theme list. The first theme is always shown as active. At most one teaser is shown.
    // A teaser will become active within three days.

    for (NSUInteger i = 0; i < self.allThemes.count; i++) {
        Theme *theme = [self.allThemes objectAtIndex:(self.allThemes.count - 1 - i)];
        if (i == 0 || timeRef >= [theme.dateRange.from timeIntervalSince1970]) {
            [theme setIsTeaser:NO];
            [themes insertObject:theme atIndex:0];
        } else if (hasAddedTeaser == NO && timeRef >= [theme.dateRange.from timeIntervalSince1970] - 3 * 24 * 60 * 60) {
            // Cancel download of teaser. Should not happen.
            if (theme.state == ThemeStateDownloading) {
                [[ThemeDownloader sharedInstance] cancelThemeDownload:theme];
            }
            [theme setIsTeaser:YES];
            [themes insertObject:theme atIndex:0];
            hasAddedTeaser = YES;
        } else {
            // Cancel download of hidden theme. Should not happen.
            if (theme.state == ThemeStateDownloading) {
                [[ThemeDownloader sharedInstance] cancelThemeDownload:theme];
            }
            [theme setIsTeaser:YES];
        }
    }
    return [NSArray arrayWithArray:themes];
}


- (void)checkForUpdatesNow {
    // Do nothing if an update check is already being performed.
    if (self.connection == nil) {

        // Reset timestamp of previous update check for error recovery (if this update check
        // fails the next update check will be performed by the timer).
        [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"lastThemeUpdateCheck"];
        [[NSUserDefaults standardUserDefaults] synchronize];

        // Create request.
        self.responseData = [NSMutableData data];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:DOWNLOAD_URL]];
        [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
        [request setTimeoutInterval:15];
        [[NetworkActivity sharedInstance] logURL:request.URL];
        self.connection = [NSURLConnection connectionWithRequest:request delegate:self];

        // Show network activity indicator if delegate is set.
        if (self.delegate) {
            [NetworkActivity sharedInstance].activityCounter++;
        }
    }
}


- (void)closeConnection {
    if (self.connection) {

        // Cancel connection and clean up.
        [self.connection cancel];
        self.connection = nil;

        // Hide network activity indicator if delegate is set.
        if (self.delegate) {
            [NetworkActivity sharedInstance].activityCounter--;
        }
    }

    // Clean up.
    self.responseData = nil;
}


- (void)readThemesFromFlash {
    // Choose theme list file either from home directory or from bundle.
    NSString *file = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]
                      stringByAppendingPathComponent: @"Themes.plist"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:file] == NO) {
        file = [[NSBundle mainBundle] pathForResource:@"Themes" ofType:@"plist"];
    }

    // Read dictionary file.
    NSDictionary *plist = [NSDictionary dictionaryWithContentsOfFile:file];

    // Get version.
    NSInteger plistVersion = 0;
    id object = [plist objectForKey:@"version"];
    if ([object isKindOfClass:[NSNumber class]]) {
        plistVersion = [object intValue];
    }

    if (plistVersion > 0) {
        self.version = plistVersion;

        // Create object for each valid theme.
        NSArray *themesEntries = [plist objectForKey:@"themes"];
        if ([themesEntries isKindOfClass:[NSArray class]]) {
            NSMutableArray *themesArray = [NSMutableArray arrayWithCapacity:themesEntries.count];
            for (NSUInteger i = 0; i < themesEntries.count; i++) {
                NSDictionary *themeDictionary = [themesEntries objectAtIndex:i];
                if ([themeDictionary isKindOfClass:[NSDictionary class]]) {
                    Theme *theme = [[Theme alloc] initWithDictionary:themeDictionary];
                    // Test if dictionary has been valid.
                    if (theme) {
                        // No two equal themes with the same start date and version must exist.
                        NSUInteger themeExists = [themesArray indexOfObject:theme];
                        if (themeExists == NSNotFound) {
                            // Recycle theme objects so downloads are not interrupted.
                            NSUInteger recycleTheme = (self.allThemes ? [self.allThemes indexOfObject:theme] : NSNotFound);
                            if (recycleTheme == NSNotFound) {
                                [themesArray addObject:theme];
                            } else {
                                // Can the theme really be recycled?
                                Theme *recycledTheme = [self.allThemes objectAtIndex:recycleTheme];
                                if ([recycledTheme.dateRange isEqual:theme.dateRange] &&
                                    [recycledTheme.title isEqualToString:theme.title] &&
                                    [recycledTheme.gradient isEqual:theme.gradient] &&
                                    [recycledTheme.url isEqual:theme.url]) {
                                    [themesArray addObject:recycledTheme];
                                } else {
                                    [themesArray addObject:theme];
                                }
                            }
                        }
                        [theme release];
                    }
                }
            }

            // Sort themes by start date.
            [themesArray sortUsingSelector:@selector(compare:)];

            self.allThemes = [NSArray arrayWithArray:themesArray];
        } else {
            self.allThemes = [NSArray array];
        }
    }

    NSAssert(self.allThemes, @"Theme list not loaded.");
}


- (void)applicationDidEnterBackground:(NSNotification *)notification {
    // Cancel update check.
    [self closeConnection];
}


- (void)clockDidChange:(NSNotification *)notification {
    // Let delegate refresh its theme list, maybe some new themes became active.
    [self.delegate refreshThemeList:self.themes];

    // Do not start update check if the previous update check has been performed within the last 60 minutes.
    if (time(NULL) >= [[NSUserDefaults standardUserDefaults] integerForKey:@"lastThemeUpdateCheck"] + CACHE_AGE) {
        [self checkForUpdatesNow];
    }
}


#pragma mark -
#pragma mark NSURLConnection delegate


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    if ([response expectedContentLength] <= MAX_DOWNLOAD_SIZE) {
        // Reset response data.
        [self.responseData setLength:0];
    } else {
        // Call error handler.
        NSError *error = [NSError errorWithDomain:@"EcoChallenge" code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Downloaded file is too large.", NSLocalizedDescriptionKey, nil]];
        [self connection:self.connection didFailWithError:error];
    }
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    if (self.responseData.length + data.length <= MAX_DOWNLOAD_SIZE) {
        // Concatenate response data.
        [self.responseData appendData:data];
    } else {
        // Call error handler.
        NSError *error = [NSError errorWithDomain:@"EcoChallenge" code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Downloaded file is too large.", NSLocalizedDescriptionKey, nil]];
        [self connection:self.connection didFailWithError:error];
    }
}


- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
#ifdef DEBUG
    NSLog(@"Cannot download file themes-de.plist: %@", [error localizedDescription]);
#endif
    // Clean up.
    [self closeConnection];
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

    // Get version.
    NSInteger plistVersion = 0;
    id object = [plist objectForKey:@"version"];
    if ([object isKindOfClass:[NSNumber class]]) {
        plistVersion = [object intValue];
    }

    // Store timestamp of update check if response data can be parsed.
    if (plistVersion > 0) {
        [[NSUserDefaults standardUserDefaults] setInteger:time(NULL) forKey:@"lastThemeUpdateCheck"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    } else {
#ifdef DEBUG
        NSLog(@"Cannot download file themes-de.plist: Unsupported file format.");
#endif
    }

    // Test if new themes list has a newer version.
    if (plistVersion > self.version) {

        // Store downloaded file.
        NSString *file = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]
                          stringByAppendingPathComponent: @"Themes.plist"];
        if ([plist writeToFile:file atomically:YES]) {
            // Re-read themes list from flash.
            [self readThemesFromFlash];

            // Inform delegate about new theme list.
            [self.delegate refreshThemeList:self.themes];

        } else {
            NSLog(@"Error: Cannot overwrite file Themes.plist.");
        }
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
