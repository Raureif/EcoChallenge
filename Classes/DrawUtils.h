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


typedef enum {
    Rooney_14,
    Rooney_16,
    Rooney_17,
    Rooney_Bold_14,
    Rooney_Bold_15,
    Rooney_Bold_17,
    Rooney_Bold_18,
    Rooney_Bold_24,
    Rooney_Italic_14,
    Rooney_Italic_17,
    Rooney_Italic_20,
    Rooney_Italic_24,
    Camingo_12,
    Camingo_14,
    Camingo_15,
    Camingo_17,
    Camingo_Bold_14,
    Camingo_Bold_15,
    Camingo_Bold_17,
    Camingo_Bold_20,
    Camingo_Italic_14
} DrawUtilsFont;


#pragma mark -


extern void drawRoundedRect(CGRect rect, CGFloat radiusTop, CGFloat radiusBottom, UIColor *color);
extern void drawRoundedGradientRect(CGRect rect, CGFloat radiusTop, CGFloat radiusBottom, Gradient *gradient);
extern void drawGradientRect(CGRect rect, Gradient *gradient);
extern CGFloat drawLabel(CGPoint pos, CGFloat width, DrawUtilsFont font, UIColor *color, int lines, NSString *text);
extern CGFloat drawLabelAligned(CGPoint pos, CGFloat width, DrawUtilsFont font, UIColor *color, int lines, NSString *text, UITextAlignment alignment);
extern CGFloat drawShadowedLabel(CGPoint pos, CGFloat width, DrawUtilsFont font, UIColor *color, UIColor *shadowColor, int lines, NSString *text);
extern CGFloat drawShadowedLabelAligned(CGPoint pos, CGFloat width, DrawUtilsFont font, UIColor *color, UIColor *shadowColor, int lines, NSString *text, UITextAlignment alignment);
extern UIImage *makeRoundedImage(UIImage *image, CGFloat radius);
extern void addRoundedRectToPath(CGContextRef context, CGRect rect, float radiusTop, float radiusBottom);
extern UIFont *selectFont(DrawUtilsFont font);
