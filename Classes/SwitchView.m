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
#import "SwitchView.h"


@interface SwitchView ()

@property (nonatomic, retain) UIView *clipView;
@property (nonatomic, retain) UIImageView *slideView;
@property (nonatomic, retain) UIImageView *thumbView;
@property (nonatomic, retain) UIImageView *borderView;

- (void)setup;
- (void)touchUpInside:(id)sender;

@end


#pragma mark -


@implementation SwitchView

@synthesize on;
@synthesize clipView;
@synthesize slideView;
@synthesize thumbView;
@synthesize borderView;
@synthesize backgroundFill;


- (void)setOn:(BOOL)state {
    [self setOn:state animated:NO];
}


- (void)setOn:(BOOL)state animated:(BOOL)animated {
    on = state;

    CGRect slideViewFrame = self.slideView.frame;
    slideViewFrame.origin.x = (self.on ? 0 : - 104 + self.thumbView.bounds.size.width);
    CGRect thumbViewFrame = self.thumbView.frame;
    thumbViewFrame.origin.x = (self.on ? 104 - self.thumbView.bounds.size.width : 0);

    if (animated) {
        if ([UIView respondsToSelector:@selector(animateWithDuration:animations:)]) {
            [UIView animateWithDuration:0.1 animations:^{
                self.slideView.frame = slideViewFrame;
                self.thumbView.frame = thumbViewFrame;
            }];
        } else {
            [UIView beginAnimations:nil context:NULL];
            [UIView setAnimationDuration:0.1];
            self.slideView.frame = slideViewFrame;
            self.thumbView.frame = thumbViewFrame;
            [UIView commitAnimations];
        }
    } else {
        self.slideView.frame = slideViewFrame;
        self.thumbView.frame = thumbViewFrame;
    }
}


- (void)touchUpInside:(id)sender {
    [self setOn:!(self.on) animated:YES];
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}


- (void)setup {
    // Set fixed frame.
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, 104, 38);
    self.backgroundColor = [UIColor clearColor];
    self.opaque = NO;

    // It is really strange, but using UIView instead of UIImageView here does absorb touch events.
    self.clipView = [[[UIImageView alloc] initWithFrame:CGRectMake(8, 5, 88, 27)] autorelease];
    self.clipView.clipsToBounds = YES;
    [self addSubview:self.clipView];

    self.slideView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"switch-slider.png"]] autorelease];
    self.slideView.frame = CGRectMake(0, 0, 148, 28);
    [self.clipView addSubview:self.slideView];

    self.borderView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"switch-frame.png"]] autorelease];
    self.borderView.frame = CGRectMake(0, 0, 104, 37);
    [self addSubview:self.borderView];

    self.thumbView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"switch-handle-default.png"]] autorelease];
    self.thumbView.frame = CGRectMake(0, 0, 51, 37);
    [self addSubview:self.thumbView];

    [self addTarget:self action:@selector(touchUpInside:) forControlEvents:UIControlEventTouchUpInside];

    // Set default state.
    [self setOn:NO];
}


#pragma mark -
#pragma mark NSCoding protocol


- (id)initWithCoder:(NSCoder *)decoder {
    if ((self = [super initWithCoder:decoder])) {
        [self setup];
    }
    return self;
}


#pragma mark -
#pragma mark UIView


- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        [self setup];
    }
    return self;
}


- (void)drawRect:(CGRect)rect {
    // Draw box with rounded corners.
    CGRect box = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height - 1);
    drawRoundedRect(box, 8, 8, [UIColor colorWithWhite:0 alpha:0.25]);
    box.origin.y += 1;
    drawRoundedRect(box, 8, 8, self.backgroundFill);
    drawRoundedRect(box, 8, 8, [UIColor colorWithWhite:1 alpha:0.25]);
    box.size.height -= 1;
    drawRoundedRect(box, 8, 8, self.backgroundFill);
}


#pragma mark -
#pragma mark NSObject


- (void)dealloc {
    self.clipView = nil;
    self.slideView = nil;
    self.thumbView = nil;
    self.borderView = nil;
    self.backgroundFill = nil;
    [super dealloc];
}


@end
