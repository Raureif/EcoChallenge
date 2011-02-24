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

#import "Themes.h"
#import "ThemeDownloader.h"
#import "FacebookController.h"


@interface ThemeListViewController: UIViewController <UITableViewDataSource, UITableViewDelegate, MFMailComposeViewControllerDelegate, ThemesProtocol, ThemeDownloaderProtocol, FacebookProtocol> {
    UITableView *tableView;
    UITableViewCell *topCell;
    UITableViewCell *creditsCell0;
    UITableViewCell *creditsCell1;
    UITableViewCell *creditsCell2;
    UITableViewCell *creditsCell3;
    UIView *backgroundView;
    UILabel *aboutLabel;
    UILabel *fhpLabel;
    UILabel *mwfkLabel;
    UILabel *raureifLabel;
    UILabel *managementLabel1;
    UILabel *managementLabel2;
    UILabel *thanksLabel1;
    UILabel *thanksLabel2;
    UILabel *fontsLabel1;
    UILabel *fontsLabel2;
    UILabel *thirdPartyLabel1;
    UILabel *thirdPartyLabel2;
    UILabel *licenseLabel;
    UILabel *facebookLabel1;
    UILabel *facebookLabel2;
    UILabel *facebookLabel3;
    UILabel *tutorialLabel1;
    UILabel *tutorialLabel2;
    UILabel *sendIdLabel1;
    UILabel *sendIdLabel2;
    UIButton *facebookButton;
    UISwitch *tutorialSwitch;
    UIView *debugView;
    NSArray *privateThemes;
}

@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) IBOutlet UITableViewCell *topCell;
@property (nonatomic, retain) IBOutlet UITableViewCell *creditsCell0;
@property (nonatomic, retain) IBOutlet UITableViewCell *creditsCell1;
@property (nonatomic, retain) IBOutlet UITableViewCell *creditsCell2;
@property (nonatomic, retain) IBOutlet UITableViewCell *creditsCell3;
@property (nonatomic, retain) IBOutlet UIView *backgroundView;
@property (nonatomic, retain) IBOutlet UILabel *aboutLabel;
@property (nonatomic, retain) IBOutlet UILabel *fhpLabel;
@property (nonatomic, retain) IBOutlet UILabel *mwfkLabel;
@property (nonatomic, retain) IBOutlet UILabel *raureifLabel;
@property (nonatomic, retain) IBOutlet UILabel *managementLabel1;
@property (nonatomic, retain) IBOutlet UILabel *managementLabel2;
@property (nonatomic, retain) IBOutlet UILabel *fontsLabel1;
@property (nonatomic, retain) IBOutlet UILabel *fontsLabel2;
@property (nonatomic, retain) IBOutlet UILabel *thanksLabel1;
@property (nonatomic, retain) IBOutlet UILabel *thanksLabel2;
@property (nonatomic, retain) IBOutlet UILabel *thirdPartyLabel1;
@property (nonatomic, retain) IBOutlet UILabel *thirdPartyLabel2;
@property (nonatomic, retain) IBOutlet UILabel *licenseLabel;
@property (nonatomic, retain) IBOutlet UILabel *facebookLabel1;
@property (nonatomic, retain) IBOutlet UILabel *facebookLabel2;
@property (nonatomic, retain) IBOutlet UILabel *facebookLabel3;
@property (nonatomic, retain) IBOutlet UILabel *tutorialLabel1;
@property (nonatomic, retain) IBOutlet UILabel *tutorialLabel2;
@property (nonatomic, retain) IBOutlet UILabel *sendIdLabel1;
@property (nonatomic, retain) IBOutlet UILabel *sendIdLabel2;
@property (nonatomic, retain) IBOutlet UIButton *facebookButton;
@property (nonatomic, retain) IBOutlet UISwitch *tutorialSwitch;
@property (nonatomic, retain) IBOutlet UIView *debugView;

- (IBAction)checkForUpdatesNow:(id)sender;
- (IBAction)showHomepage:(id)sender;
- (IBAction)showLicence:(id)sender;
- (IBAction)showSourceCode:(id)sender;
- (IBAction)facebookConnect:(id)sender;
- (IBAction)changeTutorialSetting:(id)sender;
- (IBAction)sendId:(id)sender;

@end
