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

#import "ThemeViewCell.h"


@implementation ThemeViewCell

@synthesize backgroundImage;
@synthesize buttons;


- (void)setBackgroundImage:(UIImage *)aBackgroundImage {
    if (backgroundImage != aBackgroundImage) {
        [backgroundImage release];
        backgroundImage = [aBackgroundImage retain];
        [self setNeedsDisplay];
    }
}


- (void)setButtons:(NSArray *)aButtons {
    if (buttons != aButtons) {
        for (UIButton *button in buttons) {
            [button removeFromSuperview];
        }
        [buttons release];
        buttons = [aButtons copy];
        for (UIButton *button in buttons) {
            [self addSubview:button];
        }        
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
    // Draw background image.
    [self.backgroundImage drawInRect:CGRectMake(0, 0, self.backgroundImage.size.width, self.backgroundImage.size.height)];
}


#pragma mark -
#pragma mark NSObject


- (void)dealloc {
    self.backgroundImage = nil;
    self.buttons = nil;
    [super dealloc];
}


@end
