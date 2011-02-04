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
#import "MainViewController.h"
#import "CalculatorItemCell.h"
#import "CalculatorBarCell.h"
#import "CalculatorViewController.h"


/* The UITableView consists of five different sections:
 *
 *   0 = topCell
 *   1 = CalculatorItemCells
 *   2 = addCell
 *   3 = CalculatorBarCells
 *   4 = middleCell
 *   5 = ScoreListViewCells
 *   6 = bottomCell
 *
 * The ScoreListViewCells are fully handled in the ScoreListViewController.
 */


@interface CalculatorViewController ()

@property (nonatomic, retain) Calculator *calculator;
@property (nonatomic, retain) ScoreListViewController *scoreListViewController;

- (void)redrawAddCell;
- (void)setupItemCell:(CalculatorItemCell *)cell atRow:(NSUInteger)row;
- (void)setupBarCell:(CalculatorBarCell *)cell atRow:(NSUInteger)row;

@end


#pragma mark -


@implementation CalculatorViewController

@synthesize tableView;
@synthesize topCell;
@synthesize addCell;
@synthesize middleCell;
@synthesize bottomCell;
@synthesize middleCellBackgroundView;
@synthesize bottomCellBackgroundView;
@synthesize titleLabel;
@synthesize descriptiveLabel;
@synthesize addLabel;
@synthesize facebookLabel;
@synthesize sourceLabel;
@synthesize chooseLabel;
@synthesize chooseButton;
@synthesize addCellBackgroundView;
@synthesize grayOverlay;
@synthesize slideView;
@synthesize picker;
@synthesize calculator;
@synthesize scoreListViewController;


// Designated initializer.
- (id)initWithTheme:(Theme *)theme {
    if ((self = [super initWithNibName:@"CalculatorView" bundle:nil])) {
        self.calculator = [[[Calculator alloc] initWithTheme:theme] autorelease];

        // Force loading of view.
        [self view];

        // Create Score view controller.
        self.scoreListViewController = [[[ScoreListViewController alloc] init:ScoreListViewControllerTypeCalculator theme:theme challenge:nil tableView:self.tableView section:5] autorelease];
        self.scoreListViewController.backgroundTexture = [UIImage imageNamed:@"gray-fill.png"];
        self.scoreListViewController.backgroundFill = [UIColor colorWithWhite:0.165 alpha:1];
        self.scoreListViewController.unitText = self.calculator.unitText;
    }
    return self;
}


- (IBAction)addToCalculator:(id)sender {
    self.grayOverlay.hidden = NO;
    CGRect newFrame = self.slideView.frame;
    newFrame.origin.y = self.grayOverlay.frame.size.height - newFrame.size.height;
    if ([UIView respondsToSelector:@selector(animateWithDuration:delay:options:animations:completion:)]) {
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.slideView.frame = newFrame;
        } completion:^(BOOL finished){ }];
    } else {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationCurve:UIViewAnimationOptionCurveEaseInOut];
        [UIView setAnimationDuration:0.3];
        self.slideView.frame = newFrame;
        [UIView commitAnimations];
    }
}


- (IBAction)chooseFromPicker:(id)sender {
    self.grayOverlay.hidden = YES;
    CGRect newFrame = self.slideView.frame;
    newFrame.origin.y = self.grayOverlay.frame.size.height;
    if ([UIView respondsToSelector:@selector(animateWithDuration:delay:options:animations:completion:)]) {
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.slideView.frame = newFrame;
        } completion:^(BOOL finished){ }];
    } else {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationCurve:UIViewAnimationOptionCurveEaseInOut];
        [UIView setAnimationDuration:0.3];
        self.slideView.frame = newFrame;
        [UIView commitAnimations];
    }
    [self.calculator addItem:[self.picker selectedRowInComponent:0] for:[self.picker selectedRowInComponent:1]];

    // Save new result and report it to server.
    [[Scores sharedInstance] reportCalculatorResult:self.calculator.themeIdent result:[self.calculator resultValue] count:[self.calculator.userItems count]];

    // Reload table view.
    [self redrawAddCell];
    [self.tableView reloadData];
}


- (IBAction)showFlipView:(id)sender {
    // Show flip view with source information.
    [[MainViewController sharedInstance] showFlipView:self.calculator.sourceURL
                                                title:NSLocalizedString(@"FlipView.Source", @"Source.")
                                      backgroundColor:nil
                                             gradient:[[[Gradient alloc] initWithGradientFrom:0xdfdfdf to:0x9d9d9d] autorelease]];
}


- (void)redrawAddCell {
    // Create add cell background.
    CGRect rect = CGRectMake(0, 0, self.addCellBackgroundView.bounds.size.width, self.addCellBackgroundView.bounds.size.height);
    if (UIGraphicsBeginImageContextWithOptions != NULL) {
        UIGraphicsBeginImageContextWithOptions(rect.size, YES, 0);
    } else {
        UIGraphicsBeginImageContext(rect.size);
    }
    UIImage *background = [UIImage imageNamed:@"gray-fill.png"];
    CGContextDrawTiledImage(UIGraphicsGetCurrentContext(),
                            CGRectMake(0, 0, background.size.width, background.size.height),
                            background.CGImage);
    rect.origin.x += 10;
    rect.size.width -= 20;
    rect.size.height -= 16;
    if ([self.calculator.userItems count] > 0) {
        drawRoundedRect(rect, 0, 8, [UIColor colorWithWhite:1 alpha:0.2]);
    } else {
        drawRoundedRect(rect, 8, 8, [UIColor colorWithWhite:1 alpha:0.2]);
    }
    self.addCellBackgroundView.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    // Set add cell label.
    if ([self.calculator.userItems count] > 0) {
        self.addLabel.text = NSLocalizedString(@"Calculator.Add", @"Add to calculator.");
    } else {
        self.addLabel.text = NSLocalizedString(@"Calculator.Start", @"Start calculator.");
    }
}


- (void)setupItemCell:(CalculatorItemCell *)cell atRow:(NSUInteger)row {
    NSDictionary *userItem = [self.calculator.userItems objectAtIndex:row];
    cell.icon = [UIImage imageWithContentsOfFile:[userItem objectForKey:@"icon"]];
    cell.what = [userItem objectForKey:@"what"];
    cell.how = [userItem objectForKey:@"how"];
    cell.count = [self.calculator calculateCountFromWhatValue:[[userItem objectForKey:@"average"] unsignedIntValue]
                                                  andRowValue:[[userItem objectForKey:@"count"] unsignedIntValue]];
    cell.unit = self.calculator.unitText;

    if ([self.calculator.userItems count] == 1) {
        cell.roundedCornersOnTop = YES;
        cell.roundedCornersOnBottom = YES;
        cell.separatorLine = NO;
    } else if (row == 0) {
        cell.roundedCornersOnTop = YES;
        cell.roundedCornersOnBottom = NO;
        cell.separatorLine = YES;
    } else if (row == [self.calculator.userItems count] - 1) {
        cell.roundedCornersOnTop = NO;
        cell.roundedCornersOnBottom = YES;
        cell.separatorLine = NO;
    } else {
        cell.roundedCornersOnTop = NO;
        cell.roundedCornersOnBottom = NO;
        cell.separatorLine = YES;
    }
}


- (void)setupBarCell:(CalculatorBarCell *)cell atRow:(NSUInteger)row {
    // Calculate bar chart values.
    NSUInteger result = [self.calculator resultValue];
    NSUInteger average = [self.calculator averageValue];

    // Initialize cell.
    if (row == 0) {
        cell.label = self.calculator.resultText;
        cell.count = result;
        if (result <= average) {
            cell.percent = (float)result / (float)average;
        } else {
            cell.percent = 1.0;
        }
    } else {
        cell.label = self.calculator.averageText;
        cell.count = average;
        if (result <= average) {
            cell.percent = 1.0;
        } else {
            cell.percent = (float)average / (float)result;
        }
    }
    cell.unit = self.calculator.unitText;
    cell.gradient = self.calculator.themeGradient;

    if ([self.calculator.userItems count] == 0 || self.calculator.noAverage) {
        cell.roundedCornersOnTop = YES;
        cell.roundedCornersOnBottom = YES;
        cell.separatorLine = NO;
    } else if (row == 0) {
        cell.roundedCornersOnTop = YES;
        cell.roundedCornersOnBottom = NO;
        cell.separatorLine = YES;
    } else {
        cell.roundedCornersOnTop = NO;
        cell.roundedCornersOnBottom = YES;
        cell.separatorLine = NO;
    }
}


#pragma mark -
#pragma mark UITableView data source


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *const CalculatorItemCellIdentifier = @"CalculatorItemCell";
    static NSString *const CalculatorBarCellIdentifier = @"CalculatorBarCell";

    switch (indexPath.section) {
        case 0:
            return self.topCell;
        case 1: {
            // Try to re-use CalculatorItemCell object.
            CalculatorItemCell *cell = (CalculatorItemCell *)[self.tableView dequeueReusableCellWithIdentifier:CalculatorItemCellIdentifier];
            if (cell == nil) {
                cell = [[[CalculatorItemCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CalculatorItemCellIdentifier] autorelease];
            }
            // Initialize cell.
            [self setupItemCell:cell atRow:indexPath.row];
            return cell;
        }
        case 2:
            return self.addCell;
        case 3: {
            // Try to re-use CalculatorBarCell object.
            CalculatorBarCell *cell = (CalculatorBarCell *)[self.tableView dequeueReusableCellWithIdentifier:CalculatorBarCellIdentifier];
            if (cell == nil) {
                cell = [[[CalculatorBarCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CalculatorBarCellIdentifier] autorelease];
            }
            // Initialize cell.
            [self setupBarCell:cell atRow:indexPath.row];
            return cell;
        }
        case 4:
            return self.middleCell;
        case 5:
            return [self.scoreListViewController cellForRowAtIndexPath:indexPath];
        case 6:
            return self.bottomCell;
        default:
            NSAssert(NO, @"Unexpected switch case.");
            return nil;
    }
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 7;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
        case 2:
        case 4:
        case 6:
            return 1;
        case 1:
            return [self.calculator.userItems count];
        case 3:
            return (([self.calculator.userItems count] == 0 || self.calculator.noAverage) ? 1 : 2);
        case 5:
            return [self.scoreListViewController numberOfRowsInSection];
        default:
            NSAssert(NO, @"Unexpected switch case.");
            return 0;
    }
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return (indexPath.section == 1);
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1) {
        [self.calculator removeItem:indexPath.row];
        [self redrawAddCell];
        if ([self.calculator.userItems count] > 0) {
            // Remove item cell.
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationBottom];
            // Adjust corners of first and last cell.
            [self setupItemCell:(CalculatorItemCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]] atRow:0];
            [self setupItemCell:(CalculatorItemCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:([self.calculator.userItems count] - 1) inSection:1]] atRow:([self.calculator.userItems count] - 1)];
        } else if (self.calculator.noAverage == NO) {
            // Remove item cell and second bar chart cell.
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObjects:indexPath, [NSIndexPath indexPathForRow:1 inSection:3], nil] withRowAnimation:UITableViewRowAnimationBottom];
        } else {
            // Only remove item cell.
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationBottom];
        }
        // Re-calculate bar charts.
        [self setupBarCell:(CalculatorBarCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:3]] atRow:0];
        [self setupBarCell:(CalculatorBarCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:3]] atRow:1];
    }
}


- (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    [[self.tableView cellForRowAtIndexPath:indexPath] setNeedsDisplay];
}


- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    [[self.tableView cellForRowAtIndexPath:indexPath] setNeedsDisplay];
}


#pragma mark -
#pragma mark UITableView delegate


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0:
            return self.topCell.bounds.size.height;
        case 1:
            return [CalculatorItemCell cellHeight];
        case 2:
            return self.addCell.bounds.size.height;
        case 3:
            return [CalculatorBarCell cellHeight];
        case 4:
            return self.middleCell.bounds.size.height;
        case 5:
            return [self.scoreListViewController heightForRowAtIndexPath:indexPath];
        case 6:
            return self.bottomCell.bounds.size.height;
        default:
            NSAssert(NO, @"Unexpected switch case.");
            return 0;
    }
}


#pragma mark -
#pragma mark UIScrollView delegate


- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    [self.scoreListViewController scrollViewDidEndDragging:decelerate];
}


- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self.scoreListViewController scrollViewDidEndDecelerating];
}


#pragma mark -
#pragma mark UIPickerView data source


- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 2;
}


- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if (component == 0) {
        return [self.calculator.whatItems count];
    } else {
        return [self.calculator.howItems count];
    }
}


#pragma mark -
#pragma mark UIPickerView delegate


- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if (component == 0) {
        return [[self.calculator.whatItems objectAtIndex:row] objectForKey:@"what"];
    } else {
        return [[self.calculator.howItems objectAtIndex:row] objectForKey:@"how"];
    }
}


#pragma mark -
#pragma mark UIViewController


- (void)viewDidLoad {
    [super viewDidLoad];

    // Background fill pattern.
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background-stripes.png"]];
    self.middleCellBackgroundView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"gray-fill.png"]];
    self.bottomCellBackgroundView.backgroundColor = self.middleCellBackgroundView.backgroundColor;

    // Use fancy fonts.
    self.titleLabel.font = selectFont(Rooney_Italic_20);
    self.descriptiveLabel.font = selectFont(Rooney_14);
    self.addLabel.font = selectFont(Camingo_Bold_17);
    self.facebookLabel.font = selectFont(Camingo_14);
    self.sourceLabel.font = selectFont(Rooney_Italic_14);
    self.chooseLabel.font = selectFont(Camingo_Italic_14);

    // Fill in content.
    self.titleLabel.textColor = self.calculator.themeColor;
    self.titleLabel.text = self.calculator.title;
    self.descriptiveLabel.text = self.calculator.descriptionText;
    self.chooseLabel.text = self.calculator.chooseText;

    // Localize.
    self.facebookLabel.text = NSLocalizedString(@"Facebook.FriendsResults", @"Results of friends.");
    self.sourceLabel.text = NSLocalizedString(@"FlipView.Sources", @"Sources.");
    [self.chooseButton setTitle:NSLocalizedString(@"Calculator.Finish", @"Finish.") forState:UIControlStateNormal];
    [self.chooseButton setTitle:NSLocalizedString(@"Calculator.Finish", @"Finish.") forState:UIControlStateHighlighted];

    // Resize title label to fit text height.
    CGSize size = [self.titleLabel.text sizeWithFont:self.titleLabel.font constrainedToSize:CGSizeMake(self.titleLabel.frame.size.width, MAXFLOAT) lineBreakMode:UILineBreakModeWordWrap];
    CGRect newFrame = self.titleLabel.frame;
    newFrame.size.height = size.height;
    self.titleLabel.frame = newFrame;

    // Resize description label to fit text height.
    size = [self.descriptiveLabel.text sizeWithFont:self.descriptiveLabel.font constrainedToSize:CGSizeMake(self.descriptiveLabel.frame.size.width, MAXFLOAT) lineBreakMode:UILineBreakModeWordWrap];
    newFrame = self.descriptiveLabel.frame;
    newFrame.size.height = size.height;
    newFrame.origin.y = self.titleLabel.frame.origin.y + self.titleLabel.frame.size.height + 10;
    self.descriptiveLabel.frame = newFrame;

    // Rotate picker to start position.
    [self.picker selectRow:self.calculator.whatWheelPos inComponent:0 animated:NO];
    [self.picker selectRow:self.calculator.howWheelPos inComponent:1 animated:NO];

    [self redrawAddCell];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.scoreListViewController viewWillAppear:animated];

    // This is so strange... when setting titleLabel.font on iOS 4 the non-related UITableView will
    // be loaded. Therefore we cannot set the font in method viewDidLoad, as the table view must
    // not be loaded before the ScoreListViewController.
    self.chooseButton.titleLabel.font = selectFont(Camingo_Bold_14);
}


- (void)viewWillDisappear:(BOOL)animated {
    [self.scoreListViewController viewWillDisappear:animated];
    [super viewWillDisappear:animated];
}


- (void)viewDidUnload {
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
    self.tableView = nil;
    self.topCell = nil;
    self.addCell = nil;
    self.middleCell = nil;
    self.bottomCell = nil;
    self.middleCellBackgroundView = nil;
    self.bottomCellBackgroundView = nil;
    self.titleLabel = nil;
    self.descriptiveLabel = nil;
    self.addLabel = nil;
    self.facebookLabel = nil;
    self.sourceLabel = nil;
    self.chooseLabel = nil;
    self.chooseButton = nil;
    self.addCellBackgroundView = nil;
    self.grayOverlay = nil;
    self.slideView = nil;
    self.picker.delegate = nil;
    self.picker.dataSource = nil;
    self.picker = nil;
    [super viewDidUnload];
}


#pragma mark -
#pragma mark NSObject


- (void)dealloc {
    [self viewDidUnload];
    self.calculator = nil;
    self.scoreListViewController = nil;
    [super dealloc];
}


@end
