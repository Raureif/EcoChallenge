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

#import "Themes.h"
#import "ThemeDownloader.h"
#import "Theme.h"


@interface Theme ()

@property (nonatomic, copy, readwrite) NSString *ident;
@property (nonatomic, copy, readwrite) NSString *path;
@property (nonatomic, retain, readwrite) DateRange *dateRange;
@property (nonatomic, copy, readwrite) NSString *title;
@property (nonatomic, retain, readwrite) Gradient *gradient;
@property (nonatomic, retain, readwrite) NSURL *url;
@property (nonatomic, assign) BOOL isTeaser;
@property (nonatomic, assign) BOOL isDownloading;
@property (nonatomic, assign) NSInteger version;

@end


#pragma mark -


@implementation Theme

@synthesize error;
@synthesize progress;
@synthesize state;
@synthesize ident;
@synthesize path;
@synthesize dateRange;
@synthesize title;
@synthesize gradient;
@synthesize url;
@synthesize isTeaser;
@synthesize isDownloading;
@synthesize version;


- (void)setError:(NSError *)anError {
    // Setting an error implies that a download aborted.
    if (error != anError) {
        [error release];
        error = nil;
        if (anError) {
            NSAssert(self.state == ThemeStateDownloading, @"Invalid state.");
            isDownloading = NO;
        }
        error = [anError retain];
    }
}


- (ThemeState)state {
    if (self.isTeaser) {
        NSAssert(self.isDownloading == NO && self.error == nil, @"Invalid state.");
        return ThemeStateTeaser;
    } else if (self.isDownloading) {
        NSAssert(self.error == nil && self.dictionaryPath == nil, @"Invalid state.");
        return ThemeStateDownloading;
    } else if (self.error) {
        NSAssert(self.dictionaryPath == nil, @"Invalid state.");
        return ThemeStateDownloadFailed;
    } else if (self.dictionaryPath) {
        return ThemeStateReady;
    } else {
        return ThemeStateOnServer;
    }
}


- (NSString *)dictionaryPath {
    // Look for file in bundle.
    NSString *file = [[[[[NSBundle mainBundle] resourcePath]
                        stringByAppendingPathComponent:@"Themes"]
                       stringByAppendingPathComponent:self.path]
                      stringByAppendingPathComponent:@"Theme.plist"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:file]) {
        return file;
    }

    // Look for file in Documents folder.
    file = [[[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]
              stringByAppendingPathComponent:@"Themes"]
             stringByAppendingPathComponent:self.path]
            stringByAppendingPathComponent:@"Theme.plist"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:file]) {
        return file;
    }

    return nil;
}


- (void)setIsTeaser:(BOOL)aIsTeaser {
    if (aIsTeaser) {
        NSAssert(self.state == ThemeStateTeaser || self.state == ThemeStateReady || self.state == ThemeStateOnServer, @"Invalid state.");
    }
    isTeaser = aIsTeaser;
}


- (void)setIsDownloading:(BOOL)aIsDownloading {
    if (aIsDownloading) {
        NSAssert(self.state == ThemeStateReady || self.state == ThemeStateOnServer || self.state == ThemeStateDownloadFailed, @"Invalid state.");
        error = nil;
        progress = 0;
    }
    isDownloading = aIsDownloading;
}


- (id)initWithDictionary:(NSDictionary *)dictionary {
    if ((self = [super init])) {

        // Create date formatter.
        NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
        NSLocale *locale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"] autorelease];
        [dateFormatter setLocale:locale];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"Europe/Berlin"]];
        [dateFormatter setDateFormat:@"yyyy-MM-dd"];

        // Initialize parameters from dictionary.

        id object = [dictionary objectForKey:@"fromDate"];
        if ([object isKindOfClass:[NSString class]]) {
            NSDate *fromDate = [dateFormatter dateFromString:object];
            object = [dictionary objectForKey:@"toDate"];
            if ([object isKindOfClass:[NSString class]]) {
                NSDate *toDate = [dateFormatter dateFromString:object];
                self.dateRange = [[[DateRange alloc] initWithRangeFrom:fromDate to:toDate] autorelease];
            }
        }

        object = [dictionary objectForKey:@"title"];
        if ([object isKindOfClass:[NSString class]]) {
            self.title = object;
        }

        object = [dictionary objectForKey:@"fromColor"];
        if ([object isKindOfClass:[NSNumber class]]) {
            NSUInteger fromColor = [object unsignedIntValue];
            object = [dictionary objectForKey:@"toColor"];
            if ([object isKindOfClass:[NSNumber class]]) {
                NSUInteger toColor = [object unsignedIntValue];
                self.gradient = [[[Gradient alloc] initWithGradientFrom:fromColor to:toColor] autorelease];
            }
        }

        object = [dictionary objectForKey:@"version"];
        if ([object isKindOfClass:[NSNumber class]]) {
            self.version = [object unsignedIntValue];
        }

        object = [dictionary objectForKey:@"url"];
        if ([object isKindOfClass:[NSString class]]) {
            self.url = [NSURL URLWithString:object];
        }

        // Validate parameters.
        if (self.dateRange == nil || self.title.length == 0 || self.gradient == nil || self.version <= 0 || self.url == nil) {
            [self release];
            self = nil;
        } else {
            // Create identifier and path name from start date and version.
            self.ident = [NSString stringWithFormat:@"%@", [dateFormatter stringFromDate:self.dateRange.from]];
            self.path = [NSString stringWithFormat:@"%@v%u", self.ident, self.version];
        }
    }
    return self;
}


- (NSComparisonResult)compare:(Theme *)aTheme {
    // Themes are sorted by start date in descending order
    return [aTheme.dateRange.from compare:self.dateRange.from];
}


#pragma mark -
#pragma mark NSObject


- (BOOL)isEqual:(id)anObject {
    // Themes are considered equal if their start date and version match.
    return ([anObject isKindOfClass:[Theme class]] && [self.path isEqualToString:((Theme *)anObject).path]);
}


- (NSUInteger)hash {
    // Themes are considered equal if their start date and version match. So combine these two values as hash code.
    return ([self.dateRange.from timeIntervalSince1970] + self.version);
}


- (NSString *)description {
    return [NSString stringWithFormat:@"%@: %@ (v%u)", self.dateRange, self.title, self.version];
}


- (void)dealloc {
    // Theme objects are weak referenced by the ThemeDownloader. This reference
    // must be broken during deallocation.
    if (self.state == ThemeStateDownloading) {
        [[ThemeDownloader sharedInstance] cancelThemeDownload:self];
    }
    self.error = nil;
    self.ident = nil;
    self.path = nil;
    self.dateRange = nil;
    self.title = nil;
    self.gradient = nil;
    self.url = nil;
    [super dealloc];
}


@end
