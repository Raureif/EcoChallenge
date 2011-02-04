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
#import "DateRange.h"


@interface ThemeViewController: UIViewController <UITableViewDataSource, UITableViewDelegate> {
    UITableView *tableView;
    UITableViewCell *topCell;
    UITableViewCell *bottomCell;
    UIView *bottomCellBackgroundView;
    UILabel *sourceLabel;
    UIImageView *backgroundImageView;
    UIView *currentWeekView;
    UILabel *currentWeekLabel;
    DateRange *dateRange;
    NSString *backgroundImagePath;
    NSUInteger backgroundHeight;
    NSURL *sourceURL;
    NSArray *imagemap;
    NSArray *stripes;
}

@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) IBOutlet UITableViewCell *topCell;
@property (nonatomic, retain) IBOutlet UITableViewCell *bottomCell;
@property (nonatomic, retain) IBOutlet UIView *bottomCellBackgroundView;
@property (nonatomic, retain) IBOutlet UILabel *sourceLabel;
@property (nonatomic, retain) IBOutlet UIImageView *backgroundImageView;
@property (nonatomic, retain) IBOutlet UIView *currentWeekView;
@property (nonatomic, retain) IBOutlet UILabel *currentWeekLabel;

- (id)initWithTheme:(Theme *)theme;

- (IBAction)showFlipView:(id)sender;

@end
