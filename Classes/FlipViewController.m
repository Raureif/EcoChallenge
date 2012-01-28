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
#import "FlipViewController.h"


@interface FlipViewController ()

@property (nonatomic, retain) NSURL *url;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, retain) UIColor *backgroundColor;
@property (nonatomic, retain) Gradient *gradient;
@property (nonatomic, assign) UIViewController *parentViewController;  // Weak reference.
@property (nonatomic, assign) BOOL isShown;

@end


#pragma mark -

@implementation FlipViewController

@synthesize titleLabel;
@synthesize headerView;
@synthesize webView;
@synthesize cornerView;
@synthesize url;
@synthesize title;
@synthesize backgroundColor;
@synthesize gradient;
@synthesize parentViewController;
@synthesize isShown;


// Designated initializer.
- (id)initWithURL:(NSURL *)anUrl title:(NSString *)aTitle backgroundColor:(UIColor *)aBackgroundColor gradient:(Gradient *)aGradient {
    if ((self = [super initWithNibName:@"FlipView" bundle:nil])) {
        self.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        self.url = anUrl;
        self.title = aTitle;
        self.backgroundColor = aBackgroundColor;
        self.gradient = aGradient;
    }
    return self;
}


- (void)show:(UIViewController *)aParentViewController {
    NSAssert(self.isShown == NO, @"FlipView is already shown.");

    // *** This code will not be executed on iOS 5.
    
    // Retain ourself until WebKit has loaded its content and our view is displayed modally.
    [self retain];
    // Force loading of view. WebKit will start loading its content.
    [self view];
    // Save weak reference to parent view controller.
    self.parentViewController = aParentViewController;
}


- (IBAction)close:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
    self.parentViewController.view.userInteractionEnabled = YES;
    self.parentViewController = nil;
}


#pragma mark -
#pragma mark UIWebView delegate


- (void)webViewDidFinishLoad:(UIWebView *)webView {
    if ([[[UIDevice currentDevice] systemVersion] compare:@"5.0" options:NSNumericSearch] != NSOrderedAscending) {
        self.webView.hidden = NO;
    } else if (self.isShown == NO) {
        self.isShown = YES;
        // Show flip view after WebKit has loaded its content.
        [self.parentViewController presentModalViewController:self animated:YES];
        [self release]; // c.f. method show.
        self.webView.hidden = NO;
    }
}


- (BOOL)webView:(UIWebView *)aWebView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    // Load external link in Safari.
    if ([request.URL.scheme isEqualToString:@"http"]) {
        [[UIApplication sharedApplication] openURL:request.URL];
        return NO;
    } else {
        return YES;
    }
}


#pragma mark -
#pragma mark UIViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // There are two different cases when the FlipView is shown:
    // - With pattern background and challenge color gradient.
    // - With black background and gray gradient.
    if (self.backgroundColor) {
        self.view.backgroundColor = self.backgroundColor;
    } else {
        self.cornerView.hidden = YES;
        self.titleLabel.textColor = [UIColor colorWithWhite:0.2 alpha:1];
        self.titleLabel.shadowColor = [UIColor colorWithWhite:1 alpha:0.5];
    }

    self.titleLabel.text = self.title;
    self.webView.opaque = NO;
    self.webView.hidden = YES;
    self.webView.backgroundColor = [UIColor colorWithWhite:0.4 alpha:1];
    self.webView.dataDetectorTypes = UIDataDetectorTypeNone;
    [self.webView loadRequest:[NSURLRequest requestWithURL:self.url]];

    // Create header background. Beware of mirrored Quartz 2D coordinate system.
    CGRect rect = CGRectMake(0, 0, self.headerView.bounds.size.width, self.headerView.bounds.size.height);
    if (UIGraphicsBeginImageContextWithOptions != NULL) {
        UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    } else {
        UIGraphicsBeginImageContext(rect.size);
    }
    drawRoundedGradientRect(rect, 8, 0, self.gradient);
    self.headerView.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    // Use fancy fonts.
    self.titleLabel.font = selectFont(Camingo_Bold_20);
}


- (void)viewDidUnload {
    self.titleLabel = nil;
    self.headerView = nil;
    self.webView.delegate = nil;
    self.webView = nil;
    self.cornerView = nil;
    [super viewDidUnload];
}


#pragma mark -
#pragma mark NSObject


- (void)dealloc {
    [self viewDidUnload];
    self.url = nil;
    self.title = nil;
    self.backgroundColor = nil;
    self.gradient = nil;
    self.parentViewController = nil;
    [super dealloc];
}


@end
