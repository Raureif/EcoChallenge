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
#import "ThemeListViewCellView.h"


@implementation ThemeListViewCellView

@synthesize fontColor;
@synthesize supertitle;
@synthesize title;
@synthesize subtitle;
@synthesize buttonImage;
@synthesize icons;
@synthesize offset;


- (void)setFontColor:(UIColor *)aFontColor {
    if (fontColor != aFontColor) {
        [fontColor release];
        fontColor = [aFontColor retain];
        [self setNeedsDisplay];
    }
}


- (void)setSupertitle:(NSString *)aSupertitle {
    if (supertitle != aSupertitle) {
        [supertitle release];
        supertitle = [aSupertitle copy];
        [self setNeedsDisplay];
    }
}


- (void)setTitle:(NSString *)aTitle {
    if (title != aTitle) {
        [title release];
        title = [aTitle copy];
        [self setNeedsDisplay];
    }
}


- (void)setSubtitle:(NSString *)aSubtitle {
    if (subtitle != aSubtitle) {
        [subtitle release];
        subtitle = [aSubtitle copy];
        [self setNeedsDisplay];
    }
}


- (void)setButtonImage:(UIImage *)aButtonImage {
    if (buttonImage != aButtonImage) {
        [buttonImage release];
        buttonImage = [aButtonImage retain];
        [self setNeedsDisplay];
    }
}


- (void)setIcons:(NSArray *)aIcons {
    if (icons != aIcons) {
        [icons release];
        icons = [aIcons copy];
        [self setNeedsDisplay];
    }
}


- (void)setOffset:(CGPoint)aOffset {
    if (CGPointEqualToPoint(offset, aOffset) == NO) {
        offset = aOffset;
        [self setNeedsDisplay];
    }
}


#pragma mark -
#pragma mark UIView


- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.opaque = NO;
    }
    return self;
}


- (void)drawRect:(CGRect)rect {
    UIColor *shadowColor = [UIColor colorWithWhite:0 alpha:0.5];

    // Draw supertitle string.
    CGFloat topOffset = self.offset.y + 5;
    drawShadowedLabel(CGPointMake(self.offset.x + 12, topOffset), 256,
                      Camingo_14, self.fontColor, shadowColor, 1, self.supertitle);

    // Draw button image.
    topOffset += 10;
    [self.buttonImage drawInRect:CGRectMake(self.offset.x + 268, topOffset, self.buttonImage.size.width, self.buttonImage.size.height)];

    // Draw title string.
    topOffset += 7;
    drawShadowedLabel(CGPointMake(self.offset.x + 12, topOffset), 256,
                      Rooney_Italic_24, self.fontColor, shadowColor, 1, self.title);

    // Draw icons.
    topOffset += 34;
    CGFloat sideOffset = self.offset.x + 10;
    for (NSUInteger i = 0; i < self.icons.count; i++) {
        UIImage *image = [self.icons objectAtIndex:i];
        [image drawInRect:CGRectMake(sideOffset, topOffset, image.size.width, image.size.height)];
        sideOffset += image.size.width + 1;
    }

    // Draw subtitle string.
    if (self.subtitle.length > 0) {
        if (self.icons.count == 0) {
            // Leave room for progress bar.
            sideOffset = self.offset.x + 145;
        }
        drawShadowedLabel(CGPointMake(sideOffset + 4, topOffset), self.bounds.size.width - sideOffset - self.offset.x - 2,
                          Camingo_Bold_14, self.fontColor, shadowColor, 1, self.subtitle);
    }
}


#pragma mark -
#pragma mark NSObject


- (void)dealloc {
    self.fontColor = nil;
    self.supertitle = nil;
    self.title = nil;
    self.subtitle = nil;
    self.buttonImage = nil;
    self.icons = nil;
    [super dealloc];
}


@end
