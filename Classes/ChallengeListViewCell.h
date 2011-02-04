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

#import "DateRange.h"
#import "Gradient.h"
#import "Challenge.h"


@interface ChallengeListViewCell: UITableViewCell {
    DateRange *individualDateRange;
    DateRange *globalDateRange;
    NSString *title;
    Gradient *gradient;
    UIColor *color;
    UIImage *activeIcon;
    UIImage *doneIcon;
    ChallengeState challengeState;
    NSUInteger challengeNum;
    UIImage *background;
    BOOL drawHighlighted;
}

+ (CGFloat)cellHeight;

@property (nonatomic, retain) DateRange *individualDateRange;
@property (nonatomic, retain) DateRange *globalDateRange;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, retain) Gradient *gradient;
@property (nonatomic, retain) UIColor *color;
@property (nonatomic, retain) UIImage *activeIcon;
@property (nonatomic, retain) UIImage *doneIcon;
@property (nonatomic, assign) ChallengeState challengeState;
@property (nonatomic, assign) NSUInteger challengeNum;

@end
