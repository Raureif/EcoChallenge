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


@interface Gradient ()

@property (nonatomic, assign, readwrite) NSUInteger from;
@property (nonatomic, assign, readwrite) NSUInteger to;
@property (nonatomic, copy, readwrite) NSArray *colors;

static void addRoundedRectToPath(CGContextRef context, CGRect rect, float ovalWidth, float ovalHeight);

@end


#pragma mark -


@implementation Gradient

@synthesize colors;
@synthesize from;
@synthesize to;


- (id)initWithGradientFrom:(NSUInteger)fromColor to:(NSUInteger)toColor {
    if ((self = [super init])) {

        // Initialize parameters.
        self.from = fromColor;
        self.to = toColor;

        // Split color components.
        CGFloat component[6];
        component[0] = ((self.from >> 16) & 0xFF) / 255.0;
        component[1] = ((self.from >> 8 ) & 0xFF) / 255.0;
        component[2] = ((self.from      ) & 0xFF) / 255.0;
        component[3] = ((self.to   >> 16) & 0xFF) / 255.0;
        component[4] = ((self.to   >> 8 ) & 0xFF) / 255.0;
        component[5] = ((self.to        ) & 0xFF) / 255.0;

        // Create color array.
        self.colors = [NSArray arrayWithObjects:
                       (id)[[UIColor colorWithRed:component[0] green:component[1] blue:component[2] alpha:1] CGColor],
                       (id)[[UIColor colorWithRed:component[3] green:component[4] blue:component[5] alpha:1] CGColor],
                       nil];
    }
    return self;
}


- (UIColor *)fromColor {
    return [UIColor colorWithCGColor:(CGColorRef)[self.colors objectAtIndex:0]];
}


- (UIColor *)toColor {
    return [UIColor colorWithCGColor:(CGColorRef)[self.colors objectAtIndex:1]];
}


#pragma mark -
#pragma mark NSCopying protocol


- (id)copyWithZone:(NSZone *)zone {
    return [[[self class] allocWithZone:zone] initWithGradientFrom:self.from to:self.to];
}


#pragma mark -
#pragma mark NSObject


- (BOOL)isEqual:(id)anObject {
    return ([anObject isKindOfClass:[Gradient class]] &&
            self.from == ((Gradient *)anObject).from &&
            self.to == ((Gradient *)anObject).to);
}


- (NSUInteger)hash {
    return self.from;
}


- (void)dealloc {
    self.colors = nil;
    [super dealloc];
}


@end
