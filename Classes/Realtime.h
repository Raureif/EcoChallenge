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


extern NSString *const EcoChallengeClockDidChangeNotification;


#pragma mark -


/* Every five minutes, or when the application returns from background mode,
 * this objects broadcasts a notification which lets the theme and challenge lists
 * evaluate the status of their items.
 * This object also provides access to the current system time or a simulated time.
 */


// Singleton object.
@interface Realtime: NSObject {
    BOOL isSimulating;
    NSTimer *timer;
    NSTimeInterval simulatedTimeRef;
}

+ (Realtime *)sharedInstance;

@property (nonatomic, assign) BOOL isSimulating;
@property (nonatomic, readonly) NSDate *date;
@property (nonatomic, readonly) NSTimeInterval timeRef;

- (void)simulateOneDay;

@end

