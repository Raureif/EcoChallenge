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


void drawRoundedRect(CGRect rect, CGFloat radiusTop, CGFloat radiusBottom, UIColor *color) {
    // Draw nice rectangular gradient with rounded border.
    CGContextSaveGState(UIGraphicsGetCurrentContext());
    addRoundedRectToPath(UIGraphicsGetCurrentContext(), rect, radiusTop, radiusBottom);
    CGContextClip(UIGraphicsGetCurrentContext());
    [color set];
    CGContextFillRect(UIGraphicsGetCurrentContext(), rect);
    CGContextRestoreGState(UIGraphicsGetCurrentContext());
}


void drawRoundedGradientRect(CGRect rect, CGFloat radiusTop, CGFloat radiusBottom, Gradient *gradient) {
    // Draw nice rectangular gradient with rounded border.
    CGContextSaveGState(UIGraphicsGetCurrentContext());
    addRoundedRectToPath(UIGraphicsGetCurrentContext(), rect, radiusTop, radiusBottom);
    CGContextClip(UIGraphicsGetCurrentContext());
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGGradientRef gradientRef = CGGradientCreateWithColors(colorSpace, (CFArrayRef)gradient.colors, NULL);
	CGContextDrawLinearGradient(UIGraphicsGetCurrentContext(), gradientRef, rect.origin, CGPointMake(rect.origin.x, rect.origin.y + rect.size.height), 0);
	CGGradientRelease(gradientRef);
    CGColorSpaceRelease(colorSpace);
    CGContextRestoreGState(UIGraphicsGetCurrentContext());
}


void drawGradientRect(CGRect rect, Gradient *gradient) {
    // Draw nice rectangular gradient.
    CGContextSaveGState(UIGraphicsGetCurrentContext());
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGGradientRef gradientRef = CGGradientCreateWithColors(colorSpace, (CFArrayRef)gradient.colors, NULL);
	CGContextDrawLinearGradient(UIGraphicsGetCurrentContext(), gradientRef, rect.origin, CGPointMake(rect.origin.x, rect.origin.y + rect.size.height), 0);
	CGGradientRelease(gradientRef);
    CGColorSpaceRelease(colorSpace);
    CGContextRestoreGState(UIGraphicsGetCurrentContext());
}


CGFloat drawLabel(CGPoint pos, CGFloat width, DrawUtilsFont font, UIColor *color, int lines, NSString *text) {
    return drawShadowedLabelAligned(pos, width, font, color, nil, lines, text, UITextAlignmentLeft);
}


CGFloat drawLabelAligned(CGPoint pos, CGFloat width, DrawUtilsFont font, UIColor *color, int lines, NSString *text, UITextAlignment alignment) {
    return drawShadowedLabelAligned(pos, width, font, color, nil, lines, text, alignment);
}


CGFloat drawShadowedLabel(CGPoint pos, CGFloat width, DrawUtilsFont font, UIColor *color, UIColor *shadowColor, int lines, NSString *text) {
    return drawShadowedLabelAligned(pos, width, font, color, shadowColor, lines, text, UITextAlignmentLeft);
}


CGFloat drawShadowedLabelAligned(CGPoint pos, CGFloat width, DrawUtilsFont font, UIColor *color, UIColor *shadowColor, int lines, NSString *text, UITextAlignment alignment) {
    // Draw aligned label with shadow.
    if (text == nil) return 0;

    // Center text vertically in multiline labels. Truncate label to desired width in single-line labels.
    UIFont *uiFont = selectFont(font);
    CGFloat multiLineHeight;
    if ([uiFont respondsToSelector:@selector(lineHeight)]) {
        multiLineHeight = uiFont.lineHeight * lines;
    } else {
        multiLineHeight = uiFont.leading * lines;
    }
    CGSize bounds = [text sizeWithFont:uiFont constrainedToSize:CGSizeMake(width, multiLineHeight)];
    CGFloat offset = 0;
    if (bounds.height < multiLineHeight) {
        offset = roundf((multiLineHeight - bounds.height) / 2);
    }
    CGContextSaveGState(UIGraphicsGetCurrentContext());

    CGFloat result = bounds.width;
    
    // Right alignment.
    if (alignment == UITextAlignmentRight) {
        pos.x -= bounds.width;
        result = pos.x;
    }
    
    // One line, left alignment. Method sizeWithFont makes the text length too small, resulting in an ellipsis.
    if (lines == 1 && alignment == UITextAlignmentLeft) {
        bounds.width = width;
    }

#if 0
    [[UIColor colorWithWhite:0 alpha:0.5] set];
    CGContextStrokeRect(UIGraphicsGetCurrentContext(), CGRectMake(pos.x, pos.y, width, multiLineHeight + 1));
#endif

    pos.y++;
    if (shadowColor) {
        [shadowColor set];
        if (lines == 1) {
            [text drawInRect:CGRectMake(pos.x, pos.y + offset, bounds.width, bounds.height - offset) withFont:uiFont lineBreakMode:UILineBreakModeTailTruncation alignment:alignment];
        } else {
            [text drawInRect:CGRectMake(pos.x, pos.y + offset, bounds.width, bounds.height - offset) withFont:uiFont lineBreakMode:UILineBreakModeWordWrap alignment:alignment];
        }
    }
    [color set];
    pos.y--;
    if (lines == 1) {
        [text drawInRect:CGRectMake(pos.x, pos.y + offset, bounds.width, bounds.height - offset) withFont:uiFont lineBreakMode:UILineBreakModeTailTruncation alignment:alignment];
    } else {
        [text drawInRect:CGRectMake(pos.x, pos.y + offset, bounds.width, bounds.height - offset) withFont:uiFont];
    }
    CGContextRestoreGState(UIGraphicsGetCurrentContext());

    return result;
}


UIImage *makeRoundedImage(UIImage *image, CGFloat radius) {
    // Create image with rounded corners.
    CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
    if (UIGraphicsBeginImageContextWithOptions != NULL) {
        UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    } else {
        UIGraphicsBeginImageContext(rect.size);
    }
    addRoundedRectToPath(UIGraphicsGetCurrentContext(), rect, radius, radius);
    CGContextClip(UIGraphicsGetCurrentContext());
    [image drawInRect:rect];
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}


// This method has been adapted from Apple's Quartz Programming Guide for QuickDraw Developers.
void addRoundedRectToPath(CGContextRef context, CGRect rect, float radiusTop, float radiusBottom) {
    if (radiusTop == 0 && radiusBottom == 0) {
        CGContextAddRect(context, rect);
    } else {

        float radius = MAX(radiusTop, radiusBottom);
        float fw = CGRectGetWidth(rect) / radius;
        float fh = CGRectGetHeight(rect) / radius;

        CGContextSaveGState(context);
        CGContextTranslateCTM(context, CGRectGetMinX(rect), CGRectGetMinY(rect));
        CGContextScaleCTM(context, radius, radius);

        if (radiusBottom == 0) {
            CGContextMoveToPoint(context, fw, fh);
            CGContextAddLineToPoint(context, 0, fh);
        } else {
            CGContextMoveToPoint(context, fw, fh / 2);
            CGContextAddArcToPoint(context, fw, fh, fw / 2, fh, 1);
            CGContextAddArcToPoint(context, 0, fh, 0, fh / 2, 1);
        }

        if (radiusTop == 0) {
            CGContextAddLineToPoint(context, 0, 0);
            CGContextAddLineToPoint(context, fw, 0);
        } else {
            CGContextAddArcToPoint(context, 0, 0, fw / 2, 0, 1);
            CGContextAddArcToPoint(context, fw, 0, fw, fh / 2, 1);
        }

        CGContextClosePath(context);
        CGContextRestoreGState(context);
    }
}


UIFont *selectFont(DrawUtilsFont font) {
    // Select requested font or a fallback font.

    NSString *fontName, *fallbackFontName;
    NSUInteger fontSize;

    switch (font) {
        case Rooney_14:
        case Rooney_16:
        case Rooney_17:
            fontName = @"RooneyEco-Regular";
            fallbackFontName = @"Georgia";
            break;
        case Rooney_Bold_14:
        case Rooney_Bold_15:
        case Rooney_Bold_17:
        case Rooney_Bold_18:
        case Rooney_Bold_24:
            fontName = @"RooneyEco-Bold";
            fallbackFontName = @"Georgia-Bold";
            break;
        case Rooney_Italic_14:
        case Rooney_Italic_17:
        case Rooney_Italic_20:
        case Rooney_Italic_24:
            fontName = @"RooneyEco-RegularItalic";
            fallbackFontName = @"Georgia-Italic";
            break;
        case Camingo_12:
        case Camingo_14:
        case Camingo_15:
        case Camingo_17:
            fontName = @"CamingoEco-Regular";
            fallbackFontName = @"HelveticaNeue";
            break;
        case Camingo_Bold_14:
        case Camingo_Bold_15:
        case Camingo_Bold_17:
        case Camingo_Bold_20:
            fontName = @"CamingoEco-ExtraBold";
            fallbackFontName = @"HelveticaNeue-Bold";
            break;
        case Camingo_Italic_14:
            fontName = @"CamingoEco-RegularItalic";
            fallbackFontName = @"Helvetica-Oblique";
            break;
        default:
            NSCAssert(NO, @"Unknown font.");
            return nil;
    }

    switch (font) {
        case Camingo_12:
            fontSize = 12;
            break;
        case Rooney_14:
        case Rooney_Bold_14:
        case Rooney_Italic_14:
        case Camingo_14:
        case Camingo_Bold_14:
        case Camingo_Italic_14:
            fontSize = 14;
            break;
        case Rooney_Bold_15:
        case Camingo_15:
        case Camingo_Bold_15:
            fontSize = 15;
            break;
        case Rooney_16:
            fontSize = 16;
            break;
        case Rooney_17:
        case Rooney_Bold_17:
        case Rooney_Italic_17:
        case Camingo_17:
        case Camingo_Bold_17:
            fontSize = 17;
            break;
        case Rooney_Bold_18:
            fontSize = 18;
            break;
        case Rooney_Italic_20:
        case Camingo_Bold_20:
            fontSize = 20;
            break;
        case Rooney_Bold_24:
        case Rooney_Italic_24:
            fontSize = 24;
            break;
        default:
            NSCAssert(NO, @"Unknown font.");
            return nil;
    }

    UIFont *uiFont = [UIFont fontWithName:fontName size:fontSize];
    if (uiFont == nil) {
        uiFont = [UIFont fontWithName:fallbackFontName size:fontSize];
    }
    return uiFont;
}
