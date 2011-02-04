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

#import "CupView.h"


@implementation CupView

@synthesize progress;


- (void)setProgress:(float)aProgress {
    if (progress != aProgress) {
        progress = aProgress;
        [self setNeedsDisplay];
    }
}


#pragma mark -
#pragma mark UIView


- (void)drawRect:(CGRect)rect {
    // Draw cup with pie chart progress.
    [[UIImage imageNamed:@"cup-ring.png"] drawInRect:CGRectMake(0, 0, 41, 41)];
    CGContextSaveGState(UIGraphicsGetCurrentContext());
    CGContextMoveToPoint(UIGraphicsGetCurrentContext(), 20, 20);
    CGContextAddArc(UIGraphicsGetCurrentContext(), 20, 20, 20, -90.0 * M_PI / 180, (360.0 * self.progress - 90) * M_PI / 180, 0);
    CGContextClosePath(UIGraphicsGetCurrentContext());
    CGContextClip(UIGraphicsGetCurrentContext());
    [[UIImage imageNamed:@"cup-fill.png"] drawInRect:CGRectMake(0, 0, 41, 41)];
    CGContextRestoreGState(UIGraphicsGetCurrentContext());
    [[UIImage imageNamed:@"cup-cup.png"] drawInRect:CGRectMake(0, 0, 41, 41)];
}


@end
