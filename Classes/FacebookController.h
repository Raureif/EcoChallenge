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

#import "FBConnect.h"


@protocol FacebookProtocol <NSObject>

- (void)newFacebookStatus:(BOOL)isLoggedIn
                    error:(BOOL)cannotDownloadFriends
                 progress:(BOOL)isDownloadingFriends
                  friends:(NSDictionary *)friends;

@end


#pragma mark -


// Singleton object.
@interface FacebookController: NSObject <FBSessionDelegate, FBRequestDelegate> {
    id <FacebookProtocol> delegate;
    NSDictionary *friends;
    BOOL cannotDownloadFriends;
    BOOL isDownloadingFriends;
    Facebook *facebook;
    NSString *cacheFile;
}

+ (FacebookController *)sharedInstance;

@property (nonatomic, assign) id <FacebookProtocol> delegate;
@property (nonatomic, copy, readonly) NSDictionary *friends;
@property (nonatomic, assign, readonly) BOOL cannotDownloadFriends;
@property (nonatomic, assign, readonly) BOOL isDownloadingFriends;
@property (nonatomic, readonly) BOOL isLoggedIn;
@property (nonatomic, readonly) NSString *facebookID;

- (BOOL)handleOpenURL:(NSURL *)url;
- (void)login;
- (void)logout;

@end
