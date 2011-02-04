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

#import "ZipArchive.h"
#import "FileUtils.h"


@interface FileUtils ()

@property (nonatomic, copy, readwrite) NSString *downloadsDirectory;

- (void)extractZipFileInThread:(NSArray *)arguments;
- (void)removeItemAtPathInThread:(NSString *)path;
- (void)startup;

@end


#pragma mark -


@implementation FileUtils

@synthesize downloadsDirectory;


static FileUtils *sharedInstance = nil;


+ (FileUtils *)sharedInstance {
    if (sharedInstance == nil) {
        // Create singleton object.
        sharedInstance = [[FileUtils alloc] init];
        // Remove all temporary files at startup.
        [sharedInstance startup];
    }
    return sharedInstance;
}


- (NSString *)tempNameInPath:(NSString *)path {
    // Create temporary file name.
    NSString *tempName;
    do {
        tempName = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"tmp%u", random()]];
    } while ([[NSFileManager defaultManager] fileExistsAtPath:tempName]);
    return tempName;
}


- (void)removeItemAtPathAsynchronously:(NSString *)path {
    // The filesystem remove operation could be a long running operation, so we take
    // special care and perform it asynchronously.

    if (path) {
        // Create Deleted directory. It is okay if it already exists.
        NSString *deletedDirectory = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"Deleted"];
        [[NSFileManager defaultManager] createDirectoryAtPath:deletedDirectory withIntermediateDirectories:YES attributes:nil error:NULL];

        // Create temporary name in Deleted directory.
        NSString *tempName = [self tempNameInPath:deletedDirectory];

        // Move file to temporary name in Deleted directory.
        [[NSFileManager defaultManager] moveItemAtPath:path toPath:tempName error:NULL];

        // Start remove operation of file in background thread.
        [self performSelectorInBackground:@selector(removeItemAtPathInThread:) withObject:tempName];
    }
}


- (void)extractZipFile:(NSString *)zipFile notifyObject:(id)object withSelector:(SEL)zipFileHandler {
    // Determine target directory.
    NSString *targetDirectory = [self tempNameInPath:[zipFile stringByDeletingLastPathComponent]];

    // The uncompression operation could be a long running operation, so we take
    // special care and perform it asynchronously.
    [self performSelectorInBackground:@selector(extractZipFileInThread:)
                           withObject:[NSArray arrayWithObjects:zipFile, targetDirectory, object, [NSValue valueWithPointer:zipFileHandler], nil]];
}


- (void)extractZipFileInThread:(NSArray *)arguments {
    // Really extract zip file. This method is executed in a thread.
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    // Get stuffed arguments.
    NSString *zipFile = [arguments objectAtIndex:0];
    NSString *targetDirectory = [arguments objectAtIndex:1];
    id object = [arguments objectAtIndex:2];
    SEL zipFileHandler = [[arguments objectAtIndex:3] pointerValue];

    // Extract zip archive.
    BOOL success = NO;
    BOOL noSpace = NO;
    if ([[NSFileManager defaultManager] fileExistsAtPath:zipFile]) {
        ZipArchive* zipArchive = [[ZipArchive alloc] init];
        if ([zipArchive UnzipOpenFile:zipFile]) {
            int res = [zipArchive UnzipFileTo:targetDirectory overWrite:YES];
            success = (res == 1);
            noSpace = (res == -1);
            [zipArchive UnzipCloseFile];
        }
        [zipArchive release];
    }

    if (success == NO) {
        // Remove target directory on error.
        [[NSFileManager defaultManager] removeItemAtPath:targetDirectory error:NULL];
    }

    // Inform caller.
    NSDictionary *returnValue = [NSDictionary dictionaryWithObjectsAndKeys:
                                 targetDirectory, @"targetDirectory",
                                 [NSNumber numberWithBool:success], @"success",
                                 [NSNumber numberWithBool:noSpace], @"noSpace",
                                 nil];
    [object performSelectorOnMainThread:zipFileHandler withObject:returnValue waitUntilDone:YES];

    [pool drain];
}


- (void)removeItemAtPathInThread:(NSString *)path {
    // Really remove file or directory. This method is executed in a thread.
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
    [pool drain];
}


- (void)startup {
    // Directory paths.
    self.downloadsDirectory = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"Downloads"];
    NSString *deletedDirectory = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"Deleted"];
    NSString *tempDirectory = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"Temp"];

    // Create Temp directory. It is okay if it already exists (this means that the app has
    // been terminated during the previous remove operation).
    [[NSFileManager defaultManager] createDirectoryAtPath:tempDirectory withIntermediateDirectories:YES attributes:nil error:NULL];

    // Move Downloads and Deleted directories to Temp directory, so they can be removed
    // asynchronously. The Temp directory will only be used at this point and will not
    // be used again, so this is a safe operation.
    [[NSFileManager defaultManager] moveItemAtPath:self.downloadsDirectory toPath:[self tempNameInPath:tempDirectory] error:NULL];
    [[NSFileManager defaultManager] moveItemAtPath:deletedDirectory toPath:[self tempNameInPath:tempDirectory] error:NULL];

    // Start remove operation of Temp folder in background thread.
    [self performSelectorInBackground:@selector(removeItemAtPathInThread:) withObject:tempDirectory];

    // Create (empty) Downloads directory.
    [[NSFileManager defaultManager] createDirectoryAtPath:self.downloadsDirectory withIntermediateDirectories:YES attributes:nil error:NULL];
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
