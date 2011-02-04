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
#import "Themes.h"
#import "Realtime.h"
#import "ThemeViewController.h"
#import "CalculatorViewController.h"
#import "ChallengeListViewController.h"
#import "ChallengeViewController.h"
#import "FlipViewController.h"
#import "MainViewController.h"


/* This file contains the animations on the main screen and the tab bar navigation. */


@interface MainViewController ()

@property (nonatomic, assign) SlideStartedWith slideStartedWith;
@property (nonatomic, retain) ThemeListViewController *themeListViewController;
@property (nonatomic, retain) AchievementsViewController *achievementsViewController;
@property (nonatomic, retain) UIViewController *tabViewController;
@property (nonatomic, retain) Theme *selectedTheme;
@property (nonatomic, assign) BOOL viewDidLoadForTheFirstTime;
@property (nonatomic, retain) UIButton *helpOverlay;

- (void)hideHelpOverlay:(id)sender;
- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context;
- (void)setTab;

@end


#pragma mark -


@implementation MainViewController

@synthesize contentView;
@synthesize themeTitleLabel;
@synthesize themeButton;
@synthesize calculatorButton;
@synthesize challengesButton;
@synthesize invisibleChallengesButton;
@synthesize themeListOpenButton;
@synthesize achievementsOpenButton;
@synthesize themeListCloseButton;
@synthesize achievementsCloseButton;
@synthesize themeListView;
@synthesize achievementsView;
@synthesize debugView;
@synthesize timeRefLabel;
@synthesize slideStartedWith;
@synthesize themeListViewController;
@synthesize achievementsViewController;
@synthesize tabViewController;
@synthesize selectedTheme;
@synthesize viewDidLoadForTheFirstTime;
@synthesize helpOverlay;


static MainViewController *sharedInstance = nil;


+ (MainViewController *)sharedInstance {
    if (sharedInstance == nil) {
        // Create singleton object.
        sharedInstance = [[MainViewController alloc] init];
    }
    return sharedInstance;
}


- (void)setSelectedTheme:(Theme *)aSelectedTheme {
    if (selectedTheme != aSelectedTheme) {
        [selectedTheme release];
        selectedTheme = [aSelectedTheme retain];
    }

    // Set theme title.
    self.themeTitleLabel.text = [selectedTheme.title uppercaseString];

    // Gradient on theme title text.
    if (UIGraphicsBeginImageContextWithOptions != NULL) {
        UIGraphicsBeginImageContextWithOptions(self.themeTitleLabel.bounds.size, YES, 0);
    } else {
        UIGraphicsBeginImageContext(self.themeTitleLabel.bounds.size);
    }
    drawGradientRect(self.themeTitleLabel.bounds, selectedTheme.gradient);
    self.themeTitleLabel.textColor = [UIColor colorWithPatternImage:UIGraphicsGetImageFromCurrentImageContext()];
    UIGraphicsEndImageContext();

    // Select first tab.
    [self showTheme:self];
}


- (IBAction)showTheme:(id)sender {
    // Tab bar handling. A tab is selected when its button is disabled.
    // This is a trick to get the UIButton to do the right thing.
    self.themeButton.enabled = NO;
    self.calculatorButton.enabled = YES;
    self.challengesButton.enabled = YES;
    [self setTab];
}


- (IBAction)showCalculator:(id)sender {
    // Tab bar handling.
    self.themeButton.enabled = YES;
    self.calculatorButton.enabled = NO;
    self.challengesButton.enabled = YES;
    [self setTab];
}


- (IBAction)showChallenges:(id)sender {
    // Tab bar handling.
    self.themeButton.enabled = YES;
    self.calculatorButton.enabled = YES;
    self.challengesButton.enabled = NO;
    [self setTab];
}


- (IBAction)openThemeList:(id)sender {
    // Lock user interface.
    self.view.userInteractionEnabled = NO;

    // The theme list view tops the achievements view.
    self.slideStartedWith = SlideStartedWithThemeList;
    if (self.achievementsViewController == nil) {

        // This will eventually set the FacebookController's, Scores' and FacebookImageDownloader's delegate to nil.
        [self.tabViewController viewWillDisappear:YES];

        // Set autoresizing mask to accommodate a double height status bar.
        self.themeListView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;

        // Create theme list view.
        self.themeListViewController = [[[ThemeListViewController alloc] initWithNibName:@"ThemeListView" bundle:nil] autorelease];
        self.themeListViewController.view.frame = CGRectMake(0, 95, 320, self.view.bounds.size.height - 32);
        [self.themeListView addSubview:self.themeListViewController.view];
        [self.themeListViewController viewWillAppear:YES];

        CGRect themeListViewFrame = self.themeListView.frame;
        themeListViewFrame.origin.y = -63;

        // This method may be called by viewWillAppear, in this case the theme list is shown without animation.
        if (sender == self) {
            // Show theme list view immediately.
            self.themeListView.frame = themeListViewFrame;
            self.themeListOpenButton.alpha = 0;
            self.themeListCloseButton.alpha = (self.selectedTheme ? 1 : 0);
            [self animationDidStop:@"openThemeList" finished:[NSNumber numberWithBool:YES] context:NULL];
        } else {
            // Slide in theme list view.
            if ([UIView respondsToSelector:@selector(animateWithDuration:delay:options:animations:completion:)]) {
                [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                    self.themeListView.frame = themeListViewFrame;
                    self.themeListOpenButton.alpha = 0;
                    self.themeListCloseButton.alpha = (self.selectedTheme ? 1 : 0);
                } completion:^(BOOL finished){
                    [self animationDidStop:@"openThemeList" finished:[NSNumber numberWithBool:finished] context:NULL];
                }];
            } else {
                [UIView beginAnimations:@"openThemeList" context:NULL];
                [UIView setAnimationCurve:UIViewAnimationOptionCurveEaseInOut];
                [UIView setAnimationDuration:0.5];
                [UIView setAnimationDelegate:self];
                [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
                self.themeListView.frame = themeListViewFrame;
                self.themeListOpenButton.alpha = 0;
                self.themeListCloseButton.alpha = (self.selectedTheme ? 1 : 0);
                [UIView commitAnimations];
            }
        }

    } else {

        // Slide out achivements.
        [self closeAchievements:self];
    }
}


- (IBAction)openAchievements:(id)sender {
    // Lock user interface.
    self.view.userInteractionEnabled = NO;

    if (self.themeListViewController == nil) {
        self.slideStartedWith = SlideStartedWithAchievements;

        // This will eventually set the FacebookController's, Scores' and FacebookImageDownloader's delegate to nil.
        [self.tabViewController viewWillDisappear:YES];
    } else {
        [self.themeListViewController viewWillDisappear:YES];
    }

    // Set autoresizing masks to accommodate a double height status bar.
    self.themeListView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    self.achievementsView.autoresizingMask = self.themeListView.autoresizingMask;
    self.achievementsOpenButton.autoresizingMask = self.themeListView.autoresizingMask;
    self.achievementsCloseButton.autoresizingMask = self.themeListView.autoresizingMask;

    // Create achievements view.
    self.achievementsViewController = [[[AchievementsViewController alloc] initWithNibName:@"AchievementsView" bundle:nil] autorelease];
    self.achievementsViewController.view.frame = CGRectMake(0, 0, 320, self.view.bounds.size.height - 32);
    [self.achievementsView addSubview:self.achievementsViewController.view];
    [self.achievementsViewController viewWillAppear:YES];

    // Slide in theme list view and achievements view.
    CGRect themeListViewFrame = self.themeListView.frame;
    themeListViewFrame.origin.y = -63;
    CGRect achievementsButtonFrame = self.achievementsOpenButton.frame;
    achievementsButtonFrame.origin.y = 0;
    CGRect achievementsViewFrame = self.achievementsView.frame;
    achievementsViewFrame.origin.y = 32;
    if ([UIView respondsToSelector:@selector(animateWithDuration:delay:options:animations:completion:)]) {
        [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.themeListView.frame = themeListViewFrame;
            self.achievementsOpenButton.frame = achievementsButtonFrame;
            self.achievementsCloseButton.frame = achievementsButtonFrame;
            self.achievementsView.frame = achievementsViewFrame;
            self.achievementsOpenButton.alpha = 0;
            self.achievementsCloseButton.alpha = 1;
            if (self.slideStartedWith == SlideStartedWithThemeList) {
                self.themeListOpenButton.alpha = 1;
                self.themeListCloseButton.alpha = 0;
            }
        } completion:^(BOOL finished){
            [self animationDidStop:@"openAchievements" finished:[NSNumber numberWithBool:finished] context:NULL];
        }];
    } else {
        [UIView beginAnimations:@"openAchievements" context:NULL];
        [UIView setAnimationCurve:UIViewAnimationOptionCurveEaseInOut];
        [UIView setAnimationDuration:0.5];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
        self.themeListView.frame = themeListViewFrame;
        self.achievementsOpenButton.frame = achievementsButtonFrame;
        self.achievementsCloseButton.frame = achievementsButtonFrame;
        self.achievementsView.frame = achievementsViewFrame;
        self.achievementsOpenButton.alpha = 0;
        self.achievementsCloseButton.alpha = 1;
        if (self.slideStartedWith == SlideStartedWithThemeList) {
            self.themeListOpenButton.alpha = 1;
            self.themeListCloseButton.alpha = 0;
        }
        [UIView commitAnimations];
    }
}


- (IBAction)closeThemeList:(id)sender {
    // Lock user interface.
    self.view.userInteractionEnabled = NO;

    // To enable the scroll to top functionality the UITableView of the content was hidden.
    if ([self.contentView subviews].count > 0) {
        for (id object in [[[self.contentView subviews] objectAtIndex:0] subviews]) {
            if ([object isKindOfClass:[UIScrollView class]]) {
                [object setHidden:NO];
            }
        }
    }

    [self.themeListViewController viewWillDisappear:YES];
    [self.achievementsViewController viewWillDisappear:YES];
    if (self.themeListViewController == nil) {
        // Tabs are displayed again.
        [self.tabViewController viewWillAppear:YES];
    }
    
    // Show help overlay once.
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"didShowHelp"] == NO) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"didShowHelp"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        self.helpOverlay = [UIButton buttonWithType:UIButtonTypeCustom];
        // Will there be an animation?
        if (self.themeListViewController || self.achievementsViewController) {
            self.helpOverlay.frame = CGRectMake(0, -428, 320, 460);
        } else {    
            self.helpOverlay.frame = self.view.bounds;
        }
        self.helpOverlay.adjustsImageWhenHighlighted = NO;
        self.helpOverlay.contentVerticalAlignment = UIControlContentVerticalAlignmentBottom;
        self.helpOverlay.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleHeight;
        [self.helpOverlay setImage:[UIImage imageNamed:@"tutorialoverlay.png"] forState:UIControlStateNormal];
        [self.helpOverlay addTarget:self action:@selector(hideHelpOverlay:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:self.helpOverlay];
    }
    
    // Slide out theme list and achievements view.
    CGRect themeListViewFrame = self.themeListView.frame;
    themeListViewFrame.origin.y = self.view.bounds.size.height - 95;
    CGRect achievementsButtonFrame = self.achievementsOpenButton.frame;
    achievementsButtonFrame.origin.y = self.view.bounds.size.height - 32;
    CGRect achievementsViewFrame = self.achievementsView.frame;
    achievementsViewFrame.origin.y = self.view.bounds.size.height;
    if ([UIView respondsToSelector:@selector(animateWithDuration:delay:options:animations:completion:)]) {
        [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.themeListView.frame = themeListViewFrame;
            self.achievementsOpenButton.frame = achievementsButtonFrame;
            self.achievementsCloseButton.frame = achievementsButtonFrame;
            self.achievementsView.frame = achievementsViewFrame;
            self.helpOverlay.frame = self.view.bounds;
            self.themeListOpenButton.alpha = 1;
            self.themeListCloseButton.alpha = 0;
            self.achievementsOpenButton.alpha = 1;
            self.achievementsCloseButton.alpha = 0;
        } completion:^(BOOL finished){
            [self animationDidStop:@"closeThemeList" finished:[NSNumber numberWithBool:finished] context:NULL];
        }];
    } else {
        [UIView beginAnimations:@"closeThemeList" context:NULL];
        [UIView setAnimationCurve:UIViewAnimationOptionCurveEaseInOut];
        [UIView setAnimationDuration:0.5];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
        self.themeListView.frame = themeListViewFrame;
        self.achievementsOpenButton.frame = achievementsButtonFrame;
        self.achievementsCloseButton.frame = achievementsButtonFrame;
        self.achievementsView.frame = achievementsViewFrame;
        self.helpOverlay.frame = self.view.bounds;
        self.themeListOpenButton.alpha = 1;
        self.themeListCloseButton.alpha = 0;
        self.achievementsOpenButton.alpha = 1;
        self.achievementsCloseButton.alpha = 0;
        [UIView commitAnimations];
    }
}


- (IBAction)closeAchievements:(id)sender {
    // Lock user interface.
    self.view.userInteractionEnabled = NO;

    if (self.slideStartedWith == SlideStartedWithThemeList) {

        [self.achievementsViewController viewWillDisappear:YES];

        // Create theme list view.
        self.themeListViewController = [[[ThemeListViewController alloc] initWithNibName:@"ThemeListView" bundle:nil] autorelease];
        self.themeListViewController.view.frame = CGRectMake(0, 95, 320, self.view.bounds.size.height - 32);
        [self.themeListView addSubview:self.themeListViewController.view];
        [self.themeListViewController viewWillAppear:YES];

        // Show theme list view behind achievements view.
        CGRect themeListViewFrame = self.themeListView.frame;
        themeListViewFrame.origin.y = -63;
        self.themeListView.frame = themeListViewFrame;

        // Slide out achievements view.
        CGRect achievementsButtonFrame = self.achievementsOpenButton.frame;
        achievementsButtonFrame.origin.y = self.view.bounds.size.height - 32;
        CGRect achievementsViewFrame = self.achievementsView.frame;
        achievementsViewFrame.origin.y = self.view.bounds.size.height;
        if ([UIView respondsToSelector:@selector(animateWithDuration:delay:options:animations:completion:)]) {
            [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                self.achievementsOpenButton.frame = achievementsButtonFrame;
                self.achievementsCloseButton.frame = achievementsButtonFrame;
                self.achievementsView.frame = achievementsViewFrame;
                self.achievementsOpenButton.alpha = 1;
                self.achievementsCloseButton.alpha = 0;
                self.themeListOpenButton.alpha = 0;
                self.themeListCloseButton.alpha = (self.selectedTheme ? 1 : 0);
            } completion:^(BOOL finished){
                [self animationDidStop:@"closeAchievements" finished:[NSNumber numberWithBool:finished] context:NULL];
            }];
        } else {
            [UIView beginAnimations:@"closeAchievements" context:NULL];
            [UIView setAnimationCurve:UIViewAnimationOptionCurveEaseInOut];
            [UIView setAnimationDuration:0.5];
            [UIView setAnimationDelegate:self];
            [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
            self.achievementsOpenButton.frame = achievementsButtonFrame;
            self.achievementsCloseButton.frame = achievementsButtonFrame;
            self.achievementsView.frame = achievementsViewFrame;
            self.achievementsOpenButton.alpha = 1;
            self.achievementsCloseButton.alpha = 0;
            self.themeListOpenButton.alpha = 0;
            self.themeListCloseButton.alpha = (self.selectedTheme ? 1 : 0);
            [UIView commitAnimations];
        }

    } else {

        // Slide out theme list and achivements.
        self.slideStartedWith = SlideStartedWithThemeList;
        [self closeThemeList:self];

    }
}


- (void)slideInChallengeView:(Challenges *)challenges challenge:(Challenge *)challenge {
    // Lock user interface.
    self.view.userInteractionEnabled = NO;

    // This will eventually set the FacebookController's, Scores' and FacebookImageDownloader's delegate to nil.
    [self.tabViewController viewWillDisappear:YES];

    CGRect outFrame = self.tabViewController.view.frame;
    outFrame.origin.x = - self.contentView.bounds.size.width;

    CGRect inFrame = self.tabViewController.view.frame;
    inFrame.origin.x = + self.contentView.bounds.size.width;

    ChallengeViewController *challengeViewController = [[ChallengeViewController alloc] initWithTheme:self.selectedTheme challenges:challenges challenge:challenge];
    challengeViewController.view.frame = inFrame;
    [self.contentView addSubview:challengeViewController.view];
    [challengeViewController viewWillAppear:YES];

    if ([UIView respondsToSelector:@selector(animateWithDuration:delay:options:animations:completion:)]) {
        [UIView animateWithDuration:0.4 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            challengeViewController.view.frame = self.contentView.bounds;
            self.tabViewController.view.frame = outFrame;
        } completion:^(BOOL finished){
            [self animationDidStop:@"slideInChallengeView" finished:[NSNumber numberWithBool:finished] context:challengeViewController];
        }];
    } else {
        [UIView beginAnimations:@"slideInChallengeView" context:challengeViewController];
        [UIView setAnimationCurve:UIViewAnimationOptionCurveEaseInOut];
        [UIView setAnimationDuration:0.4];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
        challengeViewController.view.frame = self.contentView.bounds;
        self.tabViewController.view.frame = outFrame;
        [UIView commitAnimations];
    }

    // Enable invisible button on tab bar so the user can return to the challenges list view.
    self.invisibleChallengesButton.hidden = NO;
}


- (IBAction)slideOutChallengeView:(id)sender {
    // Lock user interface.
    self.view.userInteractionEnabled = NO;

    // This will eventually set the FacebookController's, Scores' and FacebookImageDownloader's delegate to nil.
    [self.tabViewController viewWillDisappear:YES];

    CGRect outFrame = self.tabViewController.view.frame;
    outFrame.origin.x = + self.contentView.bounds.size.width;

    CGRect inFrame = self.tabViewController.view.frame;
    inFrame.origin.x = - self.contentView.bounds.size.width;

    ChallengeListViewController *challengeListViewController = [[ChallengeListViewController alloc] initWithTheme:self.selectedTheme];
    challengeListViewController.view.frame = inFrame;
    [self.contentView addSubview:challengeListViewController.view];
    [challengeListViewController viewWillAppear:YES];

    if ([UIView respondsToSelector:@selector(animateWithDuration:delay:options:animations:completion:)]) {
        [UIView animateWithDuration:0.4 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            challengeListViewController.view.frame = self.contentView.bounds;
            self.tabViewController.view.frame = outFrame;
        } completion:^(BOOL finished){
            [self animationDidStop:@"slideOutChallengeView" finished:[NSNumber numberWithBool:finished] context:challengeListViewController];
        }];
    } else {
        [UIView beginAnimations:@"slideOutChallengeView" context:challengeListViewController];
        [UIView setAnimationCurve:UIViewAnimationOptionCurveEaseInOut];
        [UIView setAnimationDuration:0.4];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
        challengeListViewController.view.frame = self.contentView.bounds;
        self.tabViewController.view.frame = outFrame;
        [UIView commitAnimations];
    }
    self.invisibleChallengesButton.hidden = YES;
}


- (void)hideHelpOverlay:(id)sender {
    // Lock user interface.
    self.view.userInteractionEnabled = NO;

    if ([UIView respondsToSelector:@selector(animateWithDuration:delay:options:animations:completion:)]) {
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.helpOverlay.alpha = 0;
        } completion:^(BOOL finished){
            [self animationDidStop:@"hideHelpOverlay" finished:[NSNumber numberWithBool:finished] context:NULL];
        }];
    } else {
        [UIView beginAnimations:@"hideHelpOverlay" context:NULL];
        [UIView setAnimationCurve:UIViewAnimationOptionCurveEaseInOut];
        [UIView setAnimationDuration:0.4];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
        self.helpOverlay.alpha = 0;
        [UIView commitAnimations];
    }
}


- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
    // Unlock user interface.
    self.view.userInteractionEnabled = YES;

    if ([animationID isEqualToString:@"openThemeList"] || [animationID isEqualToString:@"openAchievements"]) {
        // To enable the scroll to top functionality the UITableView of the content is set to hidden.
        if ([self.contentView subviews].count > 0) {
            for (id object in [[[self.contentView subviews] objectAtIndex:0] subviews]) {
                if ([object isKindOfClass:[UIScrollView class]]) {
                    [object setHidden:YES];
                }
            }
        }
    }
    if ([animationID isEqualToString:@"closeThemeList"] || [animationID isEqualToString:@"openAchievements"]) {
        // Delete theme list view.
        [self.themeListViewController.view removeFromSuperview];
        self.themeListViewController = nil;
    }
    if ([animationID isEqualToString:@"closeThemeList"] || [animationID isEqualToString:@"closeAchievements"]) {
        // Delete achievements view.
        [self.achievementsViewController.view removeFromSuperview];
        self.achievementsViewController = nil;
    }
    if ([animationID isEqualToString:@"closeThemeList"]) {
        self.themeListView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    }
    if ([animationID isEqualToString:@"closeAchievements"]) {
        self.achievementsView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
        self.achievementsOpenButton.autoresizingMask = self.achievementsView.autoresizingMask;
        self.achievementsCloseButton.autoresizingMask = self.achievementsView.autoresizingMask;
    }
    if ([animationID isEqualToString:@"slideInChallengeView"] || [animationID isEqualToString:@"slideOutChallengeView"]) {
        // Replace slided out view.
        self.tabViewController = (UIViewController *)context;
        // Release over-retained object.
        [(UIViewController *)context release];
    }
    if ([animationID isEqualToString:@"hideHelpOverlay"]) {
        [self.helpOverlay removeFromSuperview];
        self.helpOverlay = nil;
    }
}


- (void)setTab {
    // Set tab shadow.
    CGSize onShadowOffset = CGSizeMake(0, -1);
    CGSize offShadowOffset = CGSizeMake(0, 1);
    self.themeButton.titleLabel.shadowOffset = (self.themeButton.enabled ? offShadowOffset : onShadowOffset);
    self.calculatorButton.titleLabel.shadowOffset = (self.calculatorButton.enabled ? offShadowOffset : onShadowOffset);
    self.challengesButton.titleLabel.shadowOffset = (self.challengesButton.enabled ? offShadowOffset : onShadowOffset);

    // Set tab font weight.
    UIFont *onFont = selectFont(Camingo_Bold_15);
    UIFont *offFont = selectFont(Camingo_15);
    self.themeButton.titleLabel.font = (self.themeButton.enabled ? offFont : onFont);
    self.calculatorButton.titleLabel.font = (self.calculatorButton.enabled ? offFont : onFont);
    self.challengesButton.titleLabel.font = (self.challengesButton.enabled ? offFont : onFont);

    // Remove old tab content.
    [self.tabViewController viewWillDisappear:NO];
    [self.tabViewController.view removeFromSuperview];
    self.tabViewController = nil;

    // Load new tab content.
    if (self.themeButton.enabled == NO) {
        self.tabViewController = [[[ThemeViewController alloc] initWithTheme:self.selectedTheme] autorelease];
    } else if (self.calculatorButton.enabled == NO) {
        self.tabViewController = [[[CalculatorViewController alloc] initWithTheme:self.selectedTheme] autorelease];
    } else if (self.challengesButton.enabled == NO) {
        self.tabViewController = [[[ChallengeListViewController alloc] initWithTheme:self.selectedTheme] autorelease];
    }
    self.tabViewController.view.frame = self.contentView.bounds;
    [self.contentView addSubview:self.tabViewController.view];
    [self.tabViewController viewWillAppear:NO];
    self.invisibleChallengesButton.hidden = YES;
}


- (void)showFlipView:(NSURL *)url title:(NSString *)title backgroundColor:(UIColor *)backgroundColor gradient:(Gradient *)gradient {
    // Test if URL points to an existing file.
    if ([url isFileURL] && [[NSFileManager defaultManager] fileExistsAtPath:[url path]]) {
        // Show flip view.
        FlipViewController *flipViewController = [[FlipViewController alloc] initWithURL:url title:title backgroundColor:backgroundColor gradient:gradient];
        self.view.userInteractionEnabled = NO;
        [flipViewController show:self];
        [flipViewController release];
    }
}


- (IBAction)simulateOneDay:(id)sender {
    // For debugging only: Forward clock.
    [[Realtime sharedInstance] simulateOneDay];
    // Show (simulated) time.
    NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
    [formatter setDateFormat:@"d.M."];
    self.timeRefLabel.text = [formatter stringFromDate:[Realtime sharedInstance].date];
}


- (void)didSelectTheme:(Theme *)theme {
    self.selectedTheme = theme;

    // Close theme list.
    [self closeThemeList:self];
}


#pragma mark -
#pragma mark UIViewController


- (void)viewDidLoad {
    [super viewDidLoad];

#ifdef DEBUG
    self.debugView.hidden = NO;
#endif

    // Use fancy fonts.
    self.themeTitleLabel.font = selectFont(Rooney_Bold_18);

    // Localize.
    for (int i = 0; i < 3; i++) {
        UIControlState state = (i == 0 ? UIControlStateNormal : (i == 1 ? UIControlStateHighlighted : UIControlStateDisabled));
        [self.themeButton setTitle:NSLocalizedString(@"Tab.Theme", @"Theme") forState:state];
        [self.calculatorButton setTitle:NSLocalizedString(@"Tab.Calculator", @"Calculator") forState:state];
        [self.challengesButton setTitle:NSLocalizedString(@"Tab.Challenges", @"Challenges") forState:state];
    }

    // Only execute at application startup.
    if (self.viewDidLoadForTheFirstTime == NO) {
        self.viewDidLoadForTheFirstTime = YES;

        // Select the first available theme.
        for (Theme *theme in [Themes sharedInstance].themes) {
            if (theme.state == ThemeStateReady) {
                self.selectedTheme = theme;
                break;
            }
        }

        // Otherwise show the theme list.
        if (self.selectedTheme == nil) {
            [self openThemeList:self];
        } else {
            [self didSelectTheme:self.selectedTheme];
        }

    } else {
        [self didSelectTheme:self.selectedTheme];
    }
}


- (void)viewDidUnload {
    self.contentView = nil;
    self.themeTitleLabel = nil;
    self.themeButton = nil;
    self.calculatorButton = nil;
    self.challengesButton = nil;
    self.invisibleChallengesButton = nil;
    self.themeListOpenButton = nil;
    self.achievementsOpenButton = nil;
    self.themeListCloseButton = nil;
    self.achievementsCloseButton = nil;
    self.themeListView = nil;
    self.achievementsView = nil;
    self.debugView = nil;
    self.timeRefLabel = nil;
    [super viewDidUnload];
}


#pragma mark -
#pragma mark NSObject


+ (id)allocWithZone:(NSZone *)zone {
    if (sharedInstance == nil) {
        sharedInstance = [super allocWithZone:zone];
        return sharedInstance;
    }
    return nil;
}


- (id)copyWithZone:(NSZone *)zone {
    return self;
}


- (id)retain {
    return self;
}


- (NSUInteger)retainCount {
    // Object cannot be released.
    return NSUIntegerMax;
}


- (void)release {
    // Do nothing.
}


- (id)autorelease {
    return self;
}


@end
