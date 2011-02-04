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

#import <arpa/inet.h>
#import "FileUtils.h"
#import "NetworkActivity.h"
#import "ThemeDownloader.h"


/* Theme downloads are performed on user request and
 * continue when the application is runnig in background mode.
 */


@interface ThemeDownloader ()

// Theme objects are weak referenced! When a theme object is deallocated
// it calls cancelThemeDownload so we can remove the reference here.
@property (nonatomic, assign) Theme *downloadingTheme;
@property (nonatomic, retain) NSMutableArray *downloadQueue;
@property (nonatomic, retain) NSURLConnection *connection;
@property (nonatomic, retain) NSFileHandle *tempFileHandle;
@property (nonatomic, copy) NSString *tempFile;
@property (nonatomic, assign) NSUInteger tempFileSize;
@property (nonatomic, assign) UIBackgroundTaskIdentifier backgroundTaskIdentifier;

- (void)closeConnection;
- (void)downloadNextThemeFromQueue;
- (void)zipFileHandler:(NSDictionary *)dictionary;

@end


#pragma mark -


@implementation ThemeDownloader

@synthesize delegate;
@synthesize downloadingTheme;
@synthesize downloadQueue;
@synthesize connection;
@synthesize tempFileHandle;
@synthesize tempFile;
@synthesize tempFileSize;
@synthesize backgroundTaskIdentifier;


#define MAX_DOWNLOAD_SIZE       (20 * 1024 * 1024)
#define ERROR_DOMAIN            @"EcoChallenge"
#define LOCALIZED_ERROR_DOMAIN  @"EcoChallengeLocalized"


static ThemeDownloader *sharedInstance = nil;


+ (ThemeDownloader *)sharedInstance {
    if (sharedInstance == nil) {
        // Create singleton object.
        sharedInstance = [[ThemeDownloader alloc] init];
        // Create download queue.
        sharedInstance.downloadQueue = [NSMutableArray arrayWithCapacity:20];
        // Setup background task identifier with default value.
        if ([[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)] && [UIDevice currentDevice].multitaskingSupported) {
            sharedInstance.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        }
    }
    return sharedInstance;
}


- (void)setDelegate:(id <ThemeDownloaderProtocol>)aDelegate {
    if (delegate != aDelegate) {

        NSAssert(delegate == nil || aDelegate == nil, @"Delegate is already set.");

        delegate = aDelegate;

        // Inform new delegate about currently downloading themes.
        if (self.downloadingTheme) {
            [delegate themeStateChanged:self.downloadingTheme];
        }
        for (NSUInteger i = 0; i < self.downloadQueue.count; i++) {
            Theme *theme = [[self.downloadQueue objectAtIndex:i] nonretainedObjectValue];
            [delegate themeStateChanged:theme];
        }
    }
}


- (void)downloadTheme:(Theme *)theme {
    NSAssert(theme && (theme.state == ThemeStateOnServer || theme.state == ThemeStateDownloadFailed), @"Invalid state.");

    // Set new theme state.
    [theme setIsDownloading:YES];
    NSAssert(theme.state == ThemeStateDownloading, @"State cannot be set.");
    if (theme.state == ThemeStateDownloading) {

        // Inform delegate that the download started.
        [self.delegate themeStateChanged:theme];

        // Append theme to queue. Only a weak reference is used.
        [self.downloadQueue addObject:[NSValue valueWithNonretainedObject:theme]];

        // Start download immediately if no other download is in progress.
        if (self.downloadingTheme == nil) {
            [self downloadNextThemeFromQueue];
        }
    }
}


- (void)cancelThemeDownload:(Theme *)theme {
    NSAssert(theme && theme.state == ThemeStateDownloading, @"Invalid state.");

    if ([theme isEqual:self.downloadingTheme]) {
        // Abort current download and continue with next download in queue.
        // This will also inform the delegate that the download cancelled.
        [self closeConnection];
    } else {
        // Dequeue theme if download has not yet started.
        for (NSUInteger i = 0; i < self.downloadQueue.count; i++) {
            if ([theme isEqual:[[self.downloadQueue objectAtIndex:i] nonretainedObjectValue]]) {
                [self.downloadQueue removeObjectAtIndex:i];
                // Set new theme state and inform delegate that the downlad cancelled.
                [theme setIsDownloading:NO];
                [self.delegate themeStateChanged:theme];
                break;
            }
        }
    }
}


- (void)cancelAllThemeDownloads {
    // Dequeue all not yet started downloads.
    for (NSUInteger i = 0; i < self.downloadQueue.count; i++) {
        Theme *theme = [[self.downloadQueue objectAtIndex:i] nonretainedObjectValue];
        // Set new theme state and inform delegate that the downlad cancelled.
        [theme setIsDownloading:NO];
        [self.delegate themeStateChanged:theme];
    }
    [self.downloadQueue removeAllObjects];

    // Abort current download.
    // This will also inform the delegate that the download cancelled and
    // will unregister the background task.
    [self closeConnection];
}


- (void)closeConnection {
    // Cancel connection and clean up.
    if (self.connection) {
        [self.connection cancel];
        self.connection = nil;

        // Hide network activity indicator.
        [NetworkActivity sharedInstance].activityCounter--;
    }

    // Close and remove temporary file.
    [self.tempFileHandle closeFile];
    self.tempFileHandle = nil;
    if (self.tempFile) {
        [[NSFileManager defaultManager] removeItemAtPath:self.tempFile error:NULL];
        self.tempFile = nil;
    }

    // Set new theme state and inform delegate.
    if (self.downloadingTheme) {
        [self.downloadingTheme setIsDownloading:NO];
        [self.delegate themeStateChanged:self.downloadingTheme];
        self.downloadingTheme = nil;
    }

    if (self.downloadQueue.count > 0) {
        // Continue with next download in queue.
        [self downloadNextThemeFromQueue];
    } else {
        // No more themes in the queue. Unregister background task.
        if ([[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)] && [UIDevice currentDevice].multitaskingSupported &&
            self.backgroundTaskIdentifier != UIBackgroundTaskInvalid) {

            [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskIdentifier];
            self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        }
    }
}


- (void)downloadNextThemeFromQueue {
    NSAssert(self.downloadQueue.count > 0, @"Download queue is empty.");
    if (self.downloadQueue.count > 0) {

        // Show network activity indicator.
        [NetworkActivity sharedInstance].activityCounter++;

        // Pop item from queue.
        self.downloadingTheme = [[self.downloadQueue objectAtIndex:0] nonretainedObjectValue];
        [self.downloadQueue removeObjectAtIndex:0];

        // Create temporary file.
        self.tempFile = [[FileUtils sharedInstance] tempNameInPath:[FileUtils sharedInstance].downloadsDirectory];
        [[NSFileManager defaultManager] createFileAtPath:self.tempFile contents:[NSData data] attributes:nil];
        self.tempFileHandle = [NSFileHandle fileHandleForWritingAtPath:self.tempFile];
        // The tempFileHandle may be nil. This case is handled in connection:didReceiveData.

        // Create request.
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.downloadingTheme.url];
        [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
        [request setTimeoutInterval:15];
        [[NetworkActivity sharedInstance] logURL:request.URL];
        self.connection = [NSURLConnection connectionWithRequest:request delegate:self];

        // Register background task if not already done.
        if ([[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)] && [UIDevice currentDevice].multitaskingSupported &&
            self.backgroundTaskIdentifier == UIBackgroundTaskInvalid) {

            self.backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
                [self cancelAllThemeDownloads];
            }];
        }
    }
}


- (void)zipFileHandler:(NSDictionary *)dictionary {
    // This method will be executed after the zip file has been extracted. This is
    // still part of the download process.

    // Unmarshal parameters.
    NSString *targetDirectory = [dictionary objectForKey:@"targetDirectory"];
    BOOL success = [[dictionary objectForKey:@"success"] boolValue];
    BOOL noSpace = [[dictionary objectForKey:@"noSpace"] boolValue];

    NSString *themeDirectory = [targetDirectory stringByAppendingPathComponent:self.downloadingTheme.path];
    NSString *themePlist = [themeDirectory stringByAppendingPathComponent:@"Theme.plist"];

    if (noSpace) {
        // Set error.
        self.downloadingTheme.error = [NSError errorWithDomain:LOCALIZED_ERROR_DOMAIN code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Error.NoSpace", @"Not enough space."), NSLocalizedDescriptionKey, nil]];
#ifdef DEBUG
        NSLog(@"Cannot download file %@.zip: %@", self.downloadingTheme.path, [self.downloadingTheme.error localizedDescription]);
#endif

        // Check if file Theme.plist exists and if it is parsable.
    } else if (success && targetDirectory && [[NSFileManager defaultManager] fileExistsAtPath:themePlist] && [NSDictionary dictionaryWithContentsOfFile:themePlist]) {

        // Move directory to Documents folder.
        NSString *themesDirectory = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"Themes"];
        [[NSFileManager defaultManager] createDirectoryAtPath:themesDirectory withIntermediateDirectories:YES attributes:nil error:NULL];
        NSString *copyTo = [themesDirectory stringByAppendingPathComponent:self.downloadingTheme.path];
        [[FileUtils sharedInstance] removeItemAtPathAsynchronously:copyTo];
        [[NSFileManager defaultManager] moveItemAtPath:themeDirectory toPath:copyTo error:NULL];

    } else {
        // Set error.
        self.downloadingTheme.error = [NSError errorWithDomain:LOCALIZED_ERROR_DOMAIN code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Error.NoReply", @"Invalid server reply."), NSLocalizedDescriptionKey, nil]];
#ifdef DEBUG
        NSLog(@"Cannot download file %@.zip: %@", self.downloadingTheme.path, [self.downloadingTheme.error localizedDescription]);
#endif
    }

    // Remove extraction directory.
    [[FileUtils sharedInstance] removeItemAtPathAsynchronously:targetDirectory];

    // Clean up and continue with next download in queue.
    // This will also inform the delegate that the download finished.
    [self closeConnection];
}


#pragma mark -
#pragma mark NSURLConnection delegate


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    if ([response expectedContentLength] <= MAX_DOWNLOAD_SIZE) {
        // Reset response data.
        [self.tempFileHandle truncateFileAtOffset:0];
        // Save file size.
        self.tempFileSize = [response expectedContentLength];
    } else {
        // Call error handler.
        NSError *err = [NSError errorWithDomain:ERROR_DOMAIN code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Downloaded file is too large.", NSLocalizedDescriptionKey, nil]];
        [self connection:self.connection didFailWithError:err];
    }
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    if ([self.tempFileHandle offsetInFile] + data.length <= MAX_DOWNLOAD_SIZE) {

        // Try to write response data to flash memory.
        BOOL noSpace = (self.tempFileHandle == nil);
        @try {
            [self.tempFileHandle writeData:data];
        }
        @catch (NSException *e) {
            noSpace = YES;
        }
        if (noSpace) {
            // Call error handler.
            NSError *err = [NSError errorWithDomain:LOCALIZED_ERROR_DOMAIN code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Error.NoSpace", @"Not enough space."), NSLocalizedDescriptionKey, nil]];
            [self connection:self.connection didFailWithError:err];
        } else {
            // Inform delegate about download progress.
            self.downloadingTheme.progress = (float)[self.tempFileHandle offsetInFile] / (float)self.tempFileSize;
            [self.delegate themeStateChanged:self.downloadingTheme];
        }
    } else {
        // Call error handler.
        NSError *err = [NSError errorWithDomain:ERROR_DOMAIN code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Downloaded file is too large.", NSLocalizedDescriptionKey, nil]];
        [self connection:self.connection didFailWithError:err];
    }
}


- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)err {
#ifdef DEBUG
    NSLog(@"Cannot download file %@.zip: %@", self.downloadingTheme.path, [err localizedDescription]);
#endif

    // Change error description.
    if ([[err domain] isEqualToString:LOCALIZED_ERROR_DOMAIN] == NO) {
        BOOL noInternetConnection = NO;

        // Test if there is an Internet connection.
        struct sockaddr_in addr;
        memset(&addr, 0, sizeof(addr));
        addr.sin_len = sizeof(addr);
        addr.sin_family = AF_INET;

        SCNetworkReachabilityRef networkReachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (struct sockaddr *)&addr);
        if (networkReachability) {
            SCNetworkReachabilityFlags flags;
            if (SCNetworkReachabilityGetFlags(networkReachability, &flags)) {
                noInternetConnection = !(flags & kSCNetworkReachabilityFlagsReachable);
            }
            CFRelease(networkReachability);
        }

        if ([[err domain] isEqualToString:ERROR_DOMAIN]) {
            err =[NSError errorWithDomain:LOCALIZED_ERROR_DOMAIN code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Error.NoReply", @"Invalid server reply."), NSLocalizedDescriptionKey, nil]];
        } else if (noInternetConnection) {
            err = [NSError errorWithDomain:LOCALIZED_ERROR_DOMAIN code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Error.NoInternet", @"No Internet connection."), NSLocalizedDescriptionKey, nil]];
        } else {
            err = [NSError errorWithDomain:LOCALIZED_ERROR_DOMAIN code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Error.NoServer", @"Server does not reply."), NSLocalizedDescriptionKey, nil]];
        }
    }

    // Set error.
    self.downloadingTheme.error = err;

    // Clean up and continue with next download in queue.
    // This will also inform the delegate that the download failed.
    [self closeConnection];
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // Inform delegate about download progress.
    self.downloadingTheme.progress = 1;
    [self.delegate themeStateChanged:self.downloadingTheme];

    // Close file.
    [self.tempFileHandle closeFile];

    // Extract ZIP file.
    [[FileUtils sharedInstance] extractZipFile:self.tempFile notifyObject:self withSelector:@selector(zipFileHandler:)];
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
