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

#import "SpinView.h"


@implementation SpinView

@synthesize value;


- (void)setValue:(NSUInteger)aValue {
    if (value != aValue) {
        value = aValue;
        [self setNeedsDisplay];
    }
}


#pragma mark -
#pragma mark UIView


- (void)drawRect:(CGRect)rect {
    // Draw two-digit spin view.
    [[UIImage imageNamed:@"challenge-select-counter-bgr@2x.png"] drawInRect:CGRectMake(0, 0, 67, 38)];
    [[UIColor whiteColor] set];
    [[NSString stringWithFormat:@"%u", value / 10] drawAtPoint:CGPointMake(12, 3) forWidth:20 withFont:[UIFont fontWithName:@"HelveticaNeue-Bold" size:24] lineBreakMode:UILineBreakModeClip];
    [[NSString stringWithFormat:@"%u", value % 10] drawAtPoint:CGPointMake(41, 3) forWidth:20 withFont:[UIFont fontWithName:@"HelveticaNeue-Bold" size:24] lineBreakMode:UILineBreakModeClip];
}


@end
