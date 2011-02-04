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
#import "ChallengeRecommendationCell.h"


@interface ChallengeRecommendationCell ()

@property (nonatomic, assign) BOOL drawHighlighted;

@end


#pragma mark -


@implementation ChallengeRecommendationCell

@synthesize recommendation;
@synthesize backgroundTexture;
@synthesize drawHighlighted;


#define SIDE_OFFSET    10


- (void)setRecommendation:(NSString *)aRecommendation {
    if (recommendation != aRecommendation) {
        [recommendation release];
        recommendation = [aRecommendation copy];
        [self setNeedsDisplay];
    }
}


- (void)setBackgroundTexture:(UIImage *)aBackgroundTexture {
    if (backgroundTexture != aBackgroundTexture) {
        [backgroundTexture release];
        backgroundTexture = [aBackgroundTexture retain];
        [self setNeedsDisplay];
    }
}


#pragma mark -
#pragma mark UITableViewCell


- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    // Overwrite but do not call super method. This prevents the drawing of a blue background.

    // Set flag.
    self.drawHighlighted = highlighted;

    // Redraw.
    [self setNeedsDisplay];
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    // Overwrite but do not call super method. This prevents the drawing of a blue background.
}


#pragma mark -
#pragma mark UIView


- (void)drawRect:(CGRect)rect {
    // Draw tiled background.
    CGContextDrawTiledImage(UIGraphicsGetCurrentContext(),
                            CGRectMake(0, 0, self.backgroundTexture.size.width, self.backgroundTexture.size.height),
                            self.backgroundTexture.CGImage);

    // Draw highlight background.
    if (self.drawHighlighted) {
        [[UIColor colorWithWhite:1 alpha:0.33] set];
        CGContextFillRect(UIGraphicsGetCurrentContext(), CGRectMake(SIDE_OFFSET + 4, 2, self.bounds.size.width - 2 * SIDE_OFFSET - 8, 38));
    }

    // Draw tip label.
    if (self.drawHighlighted) {
        drawLabel(CGPointMake(SIDE_OFFSET + 12, 9), 50, Camingo_Bold_17,
                  [UIColor blackColor], 1, [NSString stringWithFormat:@"%@:", NSLocalizedString(@"Challenge.Tip", @"Tip.")]);
    } else {
        drawShadowedLabel(CGPointMake(SIDE_OFFSET + 12, 9), 50, Camingo_Bold_17,
                          [UIColor whiteColor], [UIColor colorWithWhite:0 alpha:0.5], 1, [NSString stringWithFormat:@"%@:", NSLocalizedString(@"Challenge.Tip", @"Tip.")]);
    }

    // Draw recommendation label.
    DrawUtilsFont font;
    if ([UIFont fontWithName:@"RooneyEco-Bold" size:17]) {
        font = Rooney_Bold_17;
    } else {
        // Do not use Georgia here because it is not baseline-aligned to the tip label.
        font = Camingo_Bold_17;
    }
    drawShadowedLabel(CGPointMake(SIDE_OFFSET + 58, 9), 214, font,
                      (self.drawHighlighted ? [UIColor blackColor] : [UIColor whiteColor]),
                      (self.drawHighlighted ? nil : [UIColor colorWithWhite:0 alpha:0.5]),
                      1, self.recommendation);

    // Draw arrow.
    if (self.drawHighlighted) {
        [[UIImage imageNamed:@"arrow-fwd-highlight.png"] drawInRect:CGRectMake(283, 12, 15, 19)];
    } else {
        [[UIImage imageNamed:@"arrow-fwd-default.png"] drawInRect:CGRectMake(283, 12, 15, 19)];
    }

    // Draw dotted lines.
    UIImage *dottedLine = [UIImage imageNamed:@"line-dotted.png"];
    [dottedLine drawInRect:CGRectMake(16, 0, 288, 1)];
    [dottedLine drawInRect:CGRectMake(16, 41, 288, 1)];
}


#pragma mark -
#pragma mark NSObject


- (void)dealloc {
    self.recommendation = nil;
    self.backgroundTexture = nil;
    [super dealloc];
}


@end
