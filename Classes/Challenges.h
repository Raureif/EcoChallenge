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

#import "Theme.h"


@protocol ChallengesProtocol <NSObject>

- (void)refreshChallengeList:(NSArray *)challengeList;

@end


#pragma mark -


@interface Challenges: NSObject {
    NSArray *allChallenges;
    id <ChallengesProtocol> delegate;
    NSString *themeIdent;
    NSString *badgeFilename;
}

@property (nonatomic, assign) id <ChallengesProtocol> delegate;
@property (nonatomic, readonly) NSTimeInterval accepted;
@property (nonatomic, readonly) NSArray *challenges;
@property (nonatomic, readonly) UIImage *badge;

- (id)initWithTheme:(Theme *)theme;

- (void)acceptChallenge:(BOOL)accepted;

@end

