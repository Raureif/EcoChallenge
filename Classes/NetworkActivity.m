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


@implementation NetworkActivity

@synthesize activityCounter;


static NetworkActivity *sharedInstance = nil;


+ (NetworkActivity *)sharedInstance {
    if (sharedInstance == nil) {
        // Create singleton object.
        sharedInstance = [[NetworkActivity alloc] init];
    }
    return sharedInstance;
}


- (void)setActivityCounter:(NSInteger)anActivityCounter {
    NSAssert(anActivityCounter >= 0, @"Invalid activity counter.");
    activityCounter = anActivityCounter;
    // Turn network status indicator on or off.
    [UIApplication sharedApplication].networkActivityIndicatorVisible = (activityCounter > 0);
}


- (void)logURL:(NSURL *)url {
#ifdef DEBUG
    NSLog(@"Request %@", url);
#endif
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
