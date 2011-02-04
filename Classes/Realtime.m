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

#import "Realtime.h"


NSString *const EcoChallengeClockDidChangeNotficiation = @"EcoChallengeClockDidChangeNotficiation";


#pragma mark -


@interface Realtime ()

@property (nonatomic, retain) NSTimer *timer;
@property (nonatomic, assign) NSTimeInterval simulatedTimeRef;

- (void)timerCallback;
- (void)applicationWillEnterForeground:(NSNotification *)notification;
- (void)applicationDidEnterBackground:(NSNotification *)notification;
- (void)systemClockDidChange:(NSNotification *)notification;

@end


#pragma mark -


@implementation Realtime

@synthesize isSimulating;
@synthesize timer;
@synthesize simulatedTimeRef;

static Realtime *sharedInstance = nil;


+ (Realtime *)sharedInstance {
    if (sharedInstance == nil) {

        // Create singleton object.
        sharedInstance = [[Realtime alloc] init];

        // Register for iOS multitasking events.
        if ([[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)] && [UIDevice currentDevice].multitaskingSupported) {
            [[NSNotificationCenter defaultCenter] addObserver:sharedInstance selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:sharedInstance selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:sharedInstance selector:@selector(systemClockDidChange:) name:NSSystemClockDidChangeNotification object:nil];
        }

        // Start timer.
        sharedInstance.timer = [NSTimer scheduledTimerWithTimeInterval:(5 * 60) target:sharedInstance selector:@selector(timerCallback) userInfo:nil repeats:YES];
        
#if defined(SANDBOX) && !defined(DEBUG)
        // Start simuation immediately.
        [sharedInstance simulateOneDay];
#endif
    }
    return sharedInstance;
}


- (void)setIsSimulating:(BOOL)aIsSimulating {
    if (isSimulating != aIsSimulating) {
        isSimulating = aIsSimulating;
        [self timerCallback];
    }
}


- (NSDate *)date {
    if (self.isSimulating) {
        return [NSDate dateWithTimeIntervalSince1970:self.simulatedTimeRef];
    } else {
        return [NSDate date];
    }
}


- (NSTimeInterval)timeRef {
    if (self.isSimulating) {
        return self.simulatedTimeRef;
    } else {
        return [[NSDate date] timeIntervalSince1970];
    }
}


- (void)simulateOneDay {
    if (isSimulating) {
        self.simulatedTimeRef = self.timeRef + 24 * 60 * 60;
    } else {
        // Start simulation with date 2011-03-10.
        self.simulatedTimeRef = 1299754800;
    }
    isSimulating = YES;
    [self timerCallback];
}


- (void)timerCallback {
    [[NSNotificationCenter defaultCenter] postNotificationName:EcoChallengeClockDidChangeNotficiation object:self.date];
}


- (void)applicationWillEnterForeground:(NSNotification *)notification {
    // Broadcast notification immediately.
    [self timerCallback];
    // Re-start timer.
    self.timer = [NSTimer scheduledTimerWithTimeInterval:(5 * 60) target:self selector:@selector(timerCallback) userInfo:nil repeats:YES];
}


- (void)applicationDidEnterBackground:(NSNotification *)notification {
    // Stop timer.
    [self.timer invalidate];
    self.timer = nil;
}


- (void)systemClockDidChange:(NSNotification *)notification {
    // Broadcast notification immediately.
    [self timerCallback];
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
