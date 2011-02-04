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

#import "Calculator.h"
#import "ScoreListViewController.h"


@interface CalculatorViewController: UIViewController <UITableViewDataSource, UITableViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate> {
    UITableView *tableView;
    UITableViewCell *topCell;
    UITableViewCell *addCell;
    UITableViewCell *middleCell;
    UITableViewCell *bottomCell;
    UIView *middleCellBackgroundView;
    UIView *bottomCellBackgroundView;
    UILabel *titleLabel;
    UILabel *descriptiveLabel;
    UILabel *addLabel;
    UILabel *facebookLabel;
    UILabel *sourceLabel;
    UILabel *chooseLabel;
    UIButton *chooseButton;
    UIImageView *addCellBackgroundView;
    UIView *grayOverlay;
    UIView *slideView;
    UIPickerView *picker;
    Calculator *calculator;
    ScoreListViewController *scoreListViewController;
}

@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) IBOutlet UITableViewCell *topCell;
@property (nonatomic, retain) IBOutlet UITableViewCell *addCell;
@property (nonatomic, retain) IBOutlet UITableViewCell *middleCell;
@property (nonatomic, retain) IBOutlet UITableViewCell *bottomCell;
@property (nonatomic, retain) IBOutlet UIView *middleCellBackgroundView;
@property (nonatomic, retain) IBOutlet UIView *bottomCellBackgroundView;
@property (nonatomic, retain) IBOutlet UILabel *titleLabel;
@property (nonatomic, retain) IBOutlet UILabel *descriptiveLabel;
@property (nonatomic, retain) IBOutlet UILabel *addLabel;
@property (nonatomic, retain) IBOutlet UILabel *facebookLabel;
@property (nonatomic, retain) IBOutlet UILabel *sourceLabel;
@property (nonatomic, retain) IBOutlet UILabel *chooseLabel;
@property (nonatomic, retain) IBOutlet UIButton *chooseButton;
@property (nonatomic, retain) IBOutlet UIImageView *addCellBackgroundView;
@property (nonatomic, retain) IBOutlet UIView *grayOverlay;
@property (nonatomic, retain) IBOutlet UIView *slideView;
@property (nonatomic, retain) IBOutlet UIPickerView *picker;

- (id)initWithTheme:(Theme *)theme;

- (IBAction)addToCalculator:(id)sender;
- (IBAction)chooseFromPicker:(id)sender;
- (IBAction)showFlipView:(id)sender;

@end
