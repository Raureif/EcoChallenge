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

#import "Gradient.h"


@interface CalculatorBarCell: UITableViewCell {
    BOOL roundedCornersOnTop;
    BOOL roundedCornersOnBottom;
    BOOL separatorLine;
    NSString *label;
    float percent;
    NSUInteger count;
    NSString *unit;
    Gradient *gradient;
}

+ (CGFloat)cellHeight;

@property (nonatomic, assign) BOOL roundedCornersOnTop;
@property (nonatomic, assign) BOOL roundedCornersOnBottom;
@property (nonatomic, assign) BOOL separatorLine;
@property (nonatomic, copy) NSString *label;
@property (nonatomic, assign) float percent;
@property (nonatomic, assign) NSUInteger count;
@property (nonatomic, copy) NSString *unit;
@property (nonatomic, retain) Gradient *gradient;

@end
