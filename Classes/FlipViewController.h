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


@interface FlipViewController: UIViewController <UIWebViewDelegate> {
    UILabel *titleLabel;
    UIImageView *headerView;
    UIWebView *webView;
    UIImageView *cornerView;
    NSURL *url;
    NSString *title;
    UIColor *backgroundColor;
    Gradient *gradient;
    UIViewController *parentViewController;
    BOOL isShown;
}

@property (nonatomic, retain) IBOutlet UILabel *titleLabel;
@property (nonatomic, retain) IBOutlet UIImageView *headerView;
@property (nonatomic, retain) IBOutlet UIWebView *webView;
@property (nonatomic, retain) IBOutlet UIImageView *cornerView;

- (id)initWithURL:(NSURL *)anUrl title:(NSString *)aTitle backgroundColor:(UIColor *)aBackgroundColor gradient:(Gradient *)aGradient;
- (void)show:(UIViewController *)aParentViewController;

- (IBAction)close:(id)sender;

@end
