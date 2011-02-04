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

#import "DrawUtils.h"
#import "CalculatorItemCell.h"


@implementation CalculatorItemCell

@synthesize roundedCornersOnTop;
@synthesize roundedCornersOnBottom;
@synthesize separatorLine;
@synthesize icon;
@synthesize what;
@synthesize how;
@synthesize count;
@synthesize unit;


#define SIDE_OFFSET  10


+ (CGFloat)cellHeight {
    return 41;
}


- (void)setRoundedCornersOnTop:(BOOL)aRoundedCornersOnTop {
    if (roundedCornersOnTop != aRoundedCornersOnTop) {
        roundedCornersOnTop = aRoundedCornersOnTop;
        [self setNeedsDisplay];
    }
}


- (void)setRoundedCornersOnBottom:(BOOL)aRoundedCornersOnBottom {
    if (roundedCornersOnBottom != aRoundedCornersOnBottom) {
        roundedCornersOnBottom = aRoundedCornersOnBottom;
        [self setNeedsDisplay];
    }
}


- (void)setSeparatorLine:(BOOL)aDividerLine {
    if (separatorLine != aDividerLine) {
        separatorLine = aDividerLine;
        [self setNeedsDisplay];
    }
}


- (void)setIcon:(UIImage *)anIcon {
    if (icon != anIcon) {
        [icon release];
        icon = [anIcon retain];
        [self setNeedsDisplay];
    }
}


- (void)setWhat:(NSString *)aWhat {
    if (what != aWhat) {
        [what release];
        what = [aWhat copy];
        [self setNeedsDisplay];
    }
}


- (void)setHow:(NSString *)aHow {
    if (how != aHow) {
        [how release];
        how = [aHow copy];
        [self setNeedsDisplay];
    }
}


- (void)setCount:(NSUInteger)aCount {
    if (count != aCount) {
        count = aCount;
        [self setNeedsDisplay];
    }
}


- (void)setUnit:(NSString *)aUnit {
    if (unit != aUnit) {
        [unit release];
        unit = [aUnit copy];
        [self setNeedsDisplay];
    }
}


#pragma mark -
#pragma mark UITableViewCell


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}


#pragma mark -
#pragma mark UIView


- (void)drawRect:(CGRect)rect {
    // Draw tiled background.
    UIImage *backgroundTexture = [UIImage imageNamed:@"gray-fill.png"];
    CGContextDrawTiledImage(UIGraphicsGetCurrentContext(),
                            CGRectMake(0, 0, backgroundTexture.size.width, backgroundTexture.size.height),
                            backgroundTexture.CGImage);

    // Draw box with rounded corners.
    CGRect box = CGRectMake(SIDE_OFFSET, 0, self.bounds.size.width - 2 * SIDE_OFFSET, self.bounds.size.height - 1);

    if (self.roundedCornersOnTop == NO) {
        // Simply draw box outside of the drawing rectangle to get right angled corners.
        box.origin.y -= 8;
        box.size.height += 8;
    }

    if (self.roundedCornersOnBottom == NO) {
        // Simply draw box outside of the drawing rectangle to get right angled corners.
        box.size.height += 8;
    } else {
        // Draw attached gray area.
        [[UIColor colorWithWhite:1 alpha:0.2] set];
        CGContextFillRect(UIGraphicsGetCurrentContext(), CGRectMake(box.origin.x, box.origin.y + 8, box.size.width, box.size.height - 7));
        // Draw shadow.
        box.origin.y += 1;
        drawRoundedRect(box, 8, 8, [UIColor colorWithWhite:0 alpha:0.25]);
        box.size.height -= 1;
    }

    // Draw white background.
    drawRoundedRect(box, 8, 8, [UIColor colorWithWhite:1 alpha:1]);

    // Draw separator line.
    if (self.separatorLine) {
        [[UIColor colorWithWhite:0.8 alpha:1] set];
        CGContextMoveToPoint(UIGraphicsGetCurrentContext(), box.origin.x, self.bounds.size.height);
        CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), box.origin.x + box.size.width, self.bounds.size.height);
        CGContextStrokePath(UIGraphicsGetCurrentContext());
    }

    if (self.editing) {
        // Draw striped background.
        [[UIImage imageNamed:@"calculator-delete-bgr.png"] drawInRect:CGRectMake(0, 0, 320, 40)];
    }

    // Draw icon.
    [self.icon drawInRect:CGRectMake(SIDE_OFFSET + 1, 0, self.icon.size.width, self.icon.size.height)];

    // Draw how string.
    drawLabel(CGPointMake(SIDE_OFFSET + 130, 13), 88, Camingo_14, (self.editing ? [UIColor colorWithWhite:0.2 alpha:1] : [UIColor colorWithWhite:0.4 alpha:1]), 1, self.how);

    // Draw unit string.
    CGFloat offset = drawLabelAligned(CGPointMake(self.bounds.size.width - SIDE_OFFSET - 7, 13), 80, Camingo_14, [UIColor colorWithWhite:0.4 alpha:1], 1, self.unit, UITextAlignmentRight);

    // Draw what string.
    drawLabel(CGPointMake(SIDE_OFFSET + 40, 13), 88, Camingo_Bold_14, [UIColor colorWithWhite:0.2 alpha:1], 1, self.what);

    if (self.editing == NO) {
        // Draw count string.
        NSNumberFormatter *formatter = [[[NSNumberFormatter alloc] init] autorelease];
        // Remove the next line as soon as the application becomes localized.
        formatter.locale = [[[NSLocale alloc] initWithLocaleIdentifier:@"de_DE"] autorelease];
        [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
        drawLabelAligned(CGPointMake(offset - 2, 7), 80, Camingo_Bold_20, [UIColor colorWithWhite:0.2 alpha:1], 1, [formatter stringForObjectValue:[NSNumber numberWithUnsignedInt:self.count]], UITextAlignmentRight);
    }
}


#pragma mark -
#pragma mark NSObject


- (void)dealloc {
    self.icon = nil;
    self.what = nil;
    self.how = nil;
    self.unit = nil;
    [super dealloc];
}


@end
