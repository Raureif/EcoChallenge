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

#import "DrawUtils.h"
#import "NetworkActivity.h"
#import "FacebookImageDownloader.h"


@interface FacebookImageDownloader ()

@property (nonatomic, copy) NSString *currentFacebookID;
@property (nonatomic, retain) NSMutableArray *downloadQueue;
@property (nonatomic, retain) NSURLConnection *connection;
@property (nonatomic, retain) NSMutableData *responseData;

- (void)downloadNextImageFromQueue;
- (void)closeConnection;
- (void)cancelAllDownloads;
- (void)prepareImageInThread:(NSArray *)arguments;
- (void)applicationDidEnterBackground:(NSNotification *)notification;

@end


#pragma mark -


@implementation FacebookImageDownloader

@synthesize delegate;
@synthesize currentFacebookID;
@synthesize downloadQueue;
@synthesize connection;
@synthesize responseData;


#define MAX_DOWNLOAD_SIZE  (128 * 1024)
#define CACHE_AGE          (7 * 24 * 60 * 60)


static FacebookImageDownloader *sharedInstance = nil;


+ (FacebookImageDownloader *)sharedInstance {
    if (sharedInstance == nil) {

        // Create singleton object.
        sharedInstance = [[FacebookImageDownloader alloc] init];

        // Create download queue.
        sharedInstance.downloadQueue = [NSMutableArray arrayWithCapacity:20];

        // Register for iOS multitasking events.
        if ([[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)] && [UIDevice currentDevice].multitaskingSupported) {
            [[NSNotificationCenter defaultCenter] addObserver:sharedInstance selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        }
    }
    return sharedInstance;
}


- (void)setDelegate:(NSObject<FacebookImageDownloaderProtocol> *)aDelegate {
    if (delegate != aDelegate) {

        NSAssert(delegate == nil || aDelegate == nil, @"Delegate is already set.");

        delegate = aDelegate;

        if (delegate == nil) {
            // Nobody is interested in the images. Stop all downloads.
            [self cancelAllDownloads];
        }
    }
}


- (UIImage *)getImage:(NSString *)facebookID {
    UIImage *image;

    // Test if the image file is cached. A cached image should not be older than one week.
    NSString *file = [[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject]
                       stringByAppendingPathComponent:@"FacebookFriends"]
                      stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", facebookID]];

    if ([[NSFileManager defaultManager] fileExistsAtPath:file]) {
        image = [UIImage imageWithContentsOfFile:file];
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:file error:nil];
        if (attributes == nil || [attributes.fileModificationDate timeIntervalSince1970] >= time(NULL) - CACHE_AGE) {
            return image;
        }
    } else {
        image = [UIImage imageNamed:@"face.png"];
    }

    // Test if the image file is already being downloaded.
    if ([self.currentFacebookID isEqualToString:facebookID] || [self.downloadQueue containsObject:facebookID]) {
        return image;
    }

    // Append facebook ID to queue.
    [self.downloadQueue addObject:facebookID];

    // Start download immediately if no other download is in progress.
    if (self.currentFacebookID == nil) {
        [self downloadNextImageFromQueue];
    }

    return image;
}


- (UIImage *)getCachedImage:(NSString *)facebookID {
    // Test if the image file is cached.
    NSString *file = [[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject]
                       stringByAppendingPathComponent:@"FacebookFriends"]
                      stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", facebookID]];

    if ([[NSFileManager defaultManager] fileExistsAtPath:file]) {
        return [UIImage imageWithContentsOfFile:file];
    } else {
        return [UIImage imageNamed:@"face.png"];
    }
}


- (void)downloadNextImageFromQueue {
    NSAssert([self.downloadQueue count] > 0, @"Download queue is empty.");
    if ([self.downloadQueue count] > 0) {

        // Show network activity indicator.
        [NetworkActivity sharedInstance].activityCounter++;

        // Pop item from queue.
        self.currentFacebookID = [self.downloadQueue objectAtIndex:0];
        [self.downloadQueue removeObjectAtIndex:0];

        // Create URL.
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=square&access_token=%@",
                                           self.currentFacebookID,
                                           [[NSUserDefaults standardUserDefaults] stringForKey:@"facebookAccessToken"]]];

        // Create request.
        self.responseData = [NSMutableData data];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
        [request setTimeoutInterval:15];
        [[NetworkActivity sharedInstance] logURL:request.URL];
        self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
    }
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

    // Clean up.
    self.currentFacebookID = nil;

    if ([self.downloadQueue count] > 0) {
        // Continue with next download in queue.
        [self downloadNextImageFromQueue];
    }
}


- (void)cancelAllDownloads {
     // Dequeue all not yet started downloads.
     [self.downloadQueue removeAllObjects];

     // Abort current download.
     [self closeConnection];
}


- (void)prepareImageInThread:(NSArray *)arguments {
    // Prepare image. This method is executed in a thread. This is
    // still part of the download process.

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    // Get stuffed arguments.
    UIImage *image = [arguments objectAtIndex:0];
    NSString *facebookID = [arguments objectAtIndex:1];
    NSObject<FacebookImageDownloaderProtocol> *delegateObject = ([arguments count] < 3 ? nil : [arguments objectAtIndex:2]);

    // Create cache directory.
    NSString *cacheDirectory = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject]
                                stringByAppendingPathComponent:@"FacebookFriends"];
    [[NSFileManager defaultManager] createDirectoryAtPath:cacheDirectory withIntermediateDirectories:YES attributes:nil error:NULL];

    // Save retina display version of image to flash memory.
    NSString *file = [cacheDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@@2x.png", facebookID]];
    image = makeRoundedImage(image, 4);
    NSData *imageData = [NSData dataWithData:UIImagePNGRepresentation(image)];
    [imageData writeToFile:file atomically:YES];

    // Generate normal version from retina display version by scaling the image.
    if (UIGraphicsBeginImageContextWithOptions != NULL) {
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(25, 25), NO, 0);
    } else {
        UIGraphicsBeginImageContext(CGSizeMake(25, 25));
    }
    [image drawInRect:CGRectMake(0, 0, 25, 25)];
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    // Save normal version of image to flash memory.
    file = [cacheDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", facebookID]];
    imageData = [NSData dataWithData:UIImagePNGRepresentation(image)];
    [imageData writeToFile:file atomically:YES];

    // Push image to delegate.
    [delegateObject performSelectorOnMainThread:@selector(downloadedFacebookImage:) withObject:facebookID waitUntilDone:YES];

    // Clean up and continue with next download in queue.
    [self performSelectorOnMainThread:@selector(closeConnection) withObject:nil waitUntilDone:YES];

    [pool drain];
}


- (void)applicationDidEnterBackground:(NSNotification *)notification {
    // Cancel all downloads.
    [self cancelAllDownloads];
}


#pragma mark -
#pragma mark NSURLConnection delegate


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    if ([response expectedContentLength] <= MAX_DOWNLOAD_SIZE) {
        // Reset response data.
        [self.responseData setLength:0];
    } else {
        // Call error handler.
        NSError *err = [NSError errorWithDomain:@"EcoChallenge" code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Downloaded file is too large.", NSLocalizedDescriptionKey, nil]];
        [self connection:self.connection didFailWithError:err];
    }
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    if ([self.responseData length] + [data length] <= MAX_DOWNLOAD_SIZE) {
        // Concatenate response data.
        [self.responseData appendData:data];
    } else {
        // Call error handler.
        NSError *err = [NSError errorWithDomain:@"EcoChallenge" code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Downloaded file is too large.", NSLocalizedDescriptionKey, nil]];
        [self connection:self.connection didFailWithError:err];
    }
}


- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)err {
#ifdef DEBUG
    NSLog(@"Cannot download file %@.jpg: %@", self.currentFacebookID, [err localizedDescription]);
#endif
    // Clean up and continue with next download in queue.
    [self closeConnection];
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // Try to load image from response data.
    UIImage *image = [[[UIImage alloc] initWithData:self.responseData] autorelease];
    if (image) {

        // The image preparation operation could be a long running operation, so we take
        // special care and perform it asynchronously.
        [self performSelectorInBackground:@selector(prepareImageInThread:) withObject:[NSArray arrayWithObjects:image, self.currentFacebookID, self.delegate, nil]];

    } else {
#ifdef DEBUG
        NSLog(@"Cannot download file %@.jpg: Unsupported file format.", self.currentFacebookID);
#endif
        // Clean up and continue with next download in queue.
        [self closeConnection];
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
