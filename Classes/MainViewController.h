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

#import "Theme.h"
#import "ThemeListViewController.h"
#import "Challenge.h"
#import "Challenges.h"
#import "AchievementsViewController.h"


typedef enum {
    SlideStartedWithThemeList,
    SlideStartedWithAchievements
} SlideStartedWith;


#pragma mark -


// Singleton object.
@interface MainViewController: UIViewController {
    UIView *contentView;
    UILabel *themeTitleLabel;
    UIButton *themeButton;
    UIButton *calculatorButton;
    UIButton *challengesButton;
    UIButton *invisibleChallengesButton;
    UIButton *themeListOpenButton;
    UIButton *achievementsOpenButton;
    UIButton *themeListCloseButton;
    UIButton *achievementsCloseButton;
    UIView *themeListView;
    UIView *achievementsView;
    UIView *debugView;
    UILabel *timeRefLabel;
    SlideStartedWith slideStartedWith;
    ThemeListViewController *themeListViewController;
    AchievementsViewController *achievementsViewController;
    UIViewController *tabViewController;
    Theme *selectedTheme;
    BOOL viewDidLoadForTheFirstTime;
    UIButton *helpOverlay;
}

+ (MainViewController *)sharedInstance;

@property (nonatomic, retain) IBOutlet UIView *contentView;
@property (nonatomic, retain) IBOutlet UILabel *themeTitleLabel;
@property (nonatomic, retain) IBOutlet UIButton *themeButton;
@property (nonatomic, retain) IBOutlet UIButton *calculatorButton;
@property (nonatomic, retain) IBOutlet UIButton *challengesButton;
@property (nonatomic, retain) IBOutlet UIButton *invisibleChallengesButton;
@property (nonatomic, retain) IBOutlet UIButton *themeListOpenButton;
@property (nonatomic, retain) IBOutlet UIButton *achievementsOpenButton;
@property (nonatomic, retain) IBOutlet UIButton *themeListCloseButton;
@property (nonatomic, retain) IBOutlet UIButton *achievementsCloseButton;
@property (nonatomic, retain) IBOutlet UIView *themeListView;
@property (nonatomic, retain) IBOutlet UIView *achievementsView;
@property (nonatomic, retain) IBOutlet UIView *debugView;
@property (nonatomic, retain) IBOutlet UILabel *timeRefLabel;

- (IBAction)showTheme:(id)sender;
- (IBAction)showCalculator:(id)sender;
- (IBAction)showChallenges:(id)sender;
- (IBAction)openThemeList:(id)sender;
- (IBAction)openAchievements:(id)sender;
- (IBAction)closeThemeList:(id)sender;
- (IBAction)closeAchievements:(id)sender;
- (IBAction)slideOutChallengeView:(id)sender;
- (IBAction)simulateOneDay:(id)sender;

- (void)didSelectTheme:(Theme *)theme;
- (void)slideInChallengeView:(Challenges *)challenges challenge:(Challenge *)challenge;
- (void)showFlipView:(NSURL *)url title:(NSString *)title backgroundColor:(UIColor *)backgroundColor gradient:(Gradient *)gradient;

@end
