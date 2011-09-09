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
#import "MoviePlayer.h"
#import "Realtime.h"
#import "DrawUtils.h"
#import "MainViewController.h"
#import "ThemeViewController.h"


/* The UITableView consists of five different sections:
 *
 *   0 = topCell
 *   1 = ThemeViewCells
 *   2 = bottomCell
 */


@interface ThemeViewController ()

@property (nonatomic, retain) DateRange *dateRange;
@property (nonatomic, copy) NSString *backgroundImagePath;
@property (nonatomic, assign) NSUInteger backgroundHeight;
@property (nonatomic, retain) NSURL *sourceURL;
@property (nonatomic, copy) NSArray *imagemap;
@property (nonatomic, copy) NSArray *stripes;

- (void)touchOnImagemap:(id)sender;
- (void)clockDidChange:(NSNotification *)notification;

@end


#pragma mark -


@implementation ThemeViewController

@synthesize tableView;
@synthesize topCell;
@synthesize bottomCell;
@synthesize bottomCellBackgroundView;
@synthesize sourceLabel;
@synthesize backgroundImageView;
@synthesize currentWeekView;
@synthesize currentWeekLabel;
@synthesize dateRange;
@synthesize backgroundImagePath;
@synthesize backgroundHeight;
@synthesize sourceURL;
@synthesize imagemap;
@synthesize stripes;


// Designated initializer.
- (id)initWithTheme:(Theme *)theme {
    if ((self = [super initWithNibName:@"ThemeView" bundle:nil])) {

        NSAssert(theme && theme.dictionaryPath, @"Invalid state.");

        // Save theme information.
        self.dateRange = theme.dateRange;

        // Register for clock change events.
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clockDidChange:) name:EcoChallengeClockDidChangeNotification object:nil];

        // Read file Theme.plist.
        NSDictionary *themeDict = [[NSDictionary dictionaryWithContentsOfFile:theme.dictionaryPath] objectForKey:@"theme"];
        if ([themeDict isKindOfClass:[NSDictionary class]]) {

            id object = [themeDict objectForKey:@"backgroundImage"];
            if ([object isKindOfClass:[NSString class]]) {
                self.backgroundImagePath = [[theme.dictionaryPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:object];
            }

            object = [themeDict objectForKey:@"backgroundHeight"];
            if ([object isKindOfClass:[NSNumber class]]) {
                self.backgroundHeight = [object unsignedIntValue];
            } else {
                self.backgroundHeight = 132;
            }

            object = [themeDict objectForKey:@"sourceHTML"];
            if ([object isKindOfClass:[NSString class]]) {
                self.sourceURL = [NSURL fileURLWithPath:[[theme.dictionaryPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:object]];
            }

            // Read stripes.
            NSArray *stripesArray = [themeDict objectForKey:@"stripes"];
            if ([stripesArray isKindOfClass:[NSArray class]]) {
                NSMutableArray *mutableStripes = [NSMutableArray arrayWithCapacity:[stripesArray count]];
                for (object in stripesArray) {
                    if ([object isKindOfClass:[NSString class]]) {
                        NSString *imagePath = [[theme.dictionaryPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:object];
                        UIImage *image = [[UIImage alloc] initWithContentsOfFile:imagePath];
                        NSUInteger height = image.size.height;
                        [image release];
                        if (height > 0) {
                            [mutableStripes addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                       imagePath,                               @"imagePath",
                                                       [NSNumber numberWithUnsignedInt:height], @"height",
                                                       nil]];
                        }
                    }
                }
                self.stripes = mutableStripes;
            }

            // Read image map.
            NSArray *imagemapArray = [themeDict objectForKey:@"imagemap"];
            if ([imagemapArray isKindOfClass:[NSArray class]]) {
                NSMutableArray *mutableImagemap = [NSMutableArray arrayWithCapacity:[imagemapArray count]];
                for (NSDictionary *imagemapDict in imagemapArray) {
                    if ([imagemapDict isKindOfClass:[NSDictionary class]]) {
                        NSUInteger x, y, width, height;
                        NSString *normalImagePath, *highlightImagePath;
                        NSString *title = @"";
                        NSURL *link;
                        NSInteger stripeIndex = -1;

                        object = [imagemapDict objectForKey:@"x"];
                        if ([object isKindOfClass:[NSNumber class]]) {
                            x = [object unsignedIntValue];
                        } else {
                            continue;
                        }

                        object = [imagemapDict objectForKey:@"y"];
                        if ([object isKindOfClass:[NSNumber class]]) {
                            y = [object unsignedIntValue];
                        } else {
                            continue;
                        }

                        object = [imagemapDict objectForKey:@"normalImage"];
                        if ([object isKindOfClass:[NSString class]]) {
                            normalImagePath = [[theme.dictionaryPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:object];
                        } else {
                            continue;
                        }
                        UIImage *image = [[UIImage alloc] initWithContentsOfFile:normalImagePath];
                        CGSize size = image.size;
                        [image release];
                        width = size.width;
                        height = size.height;
                        if (width == 0 || height == 0) {
                            continue;
                        }

                        object = [imagemapDict objectForKey:@"highlightImage"];
                        if ([object isKindOfClass:[NSString class]]) {
                            highlightImagePath = [[theme.dictionaryPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:object];
                        } else {
                            continue;
                        }
                        image = [[UIImage alloc] initWithContentsOfFile:highlightImagePath];
                        size = image.size;
                        [image release];
                        if (width != size.width || height != size.height) {
                            continue;
                        }

                        object = [imagemapDict objectForKey:@"link"];
                        if ([object isKindOfClass:[NSString class]]) {
                            if ([object rangeOfString:@"://"].location != NSNotFound) {
                                link = [NSURL URLWithString:object];
                            } else {
                                link = [NSURL fileURLWithPath:[[theme.dictionaryPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:object]];
                            }
                        } else {
                            continue;
                        }

                        if ([link isFileURL]) {
                            object = [imagemapDict objectForKey:@"title"];
                            if ([object isKindOfClass:[NSString class]]) {
                                title = object;
                            } else {
                                continue;
                            }
                        }

                        // Find out which stripe contains the button image and adjust the y coordinate accordingly.
                        NSUInteger stripeY = 0;
                        for (NSUInteger i = 0; i < [self.stripes count]; i++) {
                            NSUInteger stripeHeight = [[[self.stripes objectAtIndex:i] objectForKey:@"height"] unsignedIntValue];
                            if (y <= stripeY + stripeHeight) {
                                y -= stripeY;
                                stripeIndex = i;
                                break;
                            }
                            stripeY += stripeHeight;
                        }
                        if (stripeIndex == -1) {
                            continue;
                        }

                        [mutableImagemap addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                    [NSNumber numberWithUnsignedInt:stripeIndex], @"stripe",
                                                    [NSNumber numberWithUnsignedInt:x],           @"x",
                                                    [NSNumber numberWithUnsignedInt:y],           @"y",
                                                    [NSNumber numberWithUnsignedInt:width],       @"width",
                                                    [NSNumber numberWithUnsignedInt:height],      @"height",
                                                    normalImagePath,                              @"normalImagePath",
                                                    highlightImagePath,                           @"highlightImagePath",
                                                    title,                                        @"title",
                                                    link,                                         @"link",
                                                    nil]];
                    }
                }
                self.imagemap = mutableImagemap;
            }
        }
    }
    return self;
}


- (IBAction)showFlipView:(id)sender {
    // Show flip view with source information.
    [[MainViewController sharedInstance] showFlipView:self.sourceURL
                                                title:NSLocalizedString(@"FlipView.Source", @"Source.")
                                      backgroundColor:nil
                                             gradient:[[[Gradient alloc] initWithGradientFrom:0xdfdfdf to:0x9d9d9d] autorelease]];
}


- (void)touchOnImagemap:(id)sender {
    NSURL *link = [[self.imagemap objectAtIndex:[sender tag]] objectForKey:@"link"];
    
    if ([[[link path] pathExtension] isEqualToString:@"m4v"] || [[[link path] pathExtension] isEqualToString:@"mp4"]) {
        [[MoviePlayer sharedInstance] play:link];
    } else if ([link isFileURL]) {
        // Show flip view with further information.
        [[MainViewController sharedInstance] showFlipView:link
                                                    title:[[self.imagemap objectAtIndex:[sender tag]] objectForKey:@"title"]
                                          backgroundColor:nil
                                                 gradient:[[[Gradient alloc] initWithGradientFrom:0xdfdfdf to:0x9d9d9d] autorelease]];
    } else {
        // Open external URL.
        [[UIApplication sharedApplication] openURL:link];
    }
}


- (void)clockDidChange:(NSNotification *)notification {
    NSTimeInterval timeRef = [Realtime sharedInstance].timeRef;

    // Test if our theme is the most recent theme.
    self.currentWeekView.hidden = !(timeRef >= [self.dateRange.from timeIntervalSince1970] &&
                                    timeRef < [self.dateRange.to timeIntervalSince1970] + 24 * 60 * 60);
}


#pragma mark -
#pragma mark UITableView data source


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *const CellIdentifier = @"ThemeViewCell";

    switch (indexPath.section) {
        case 0:
            return self.topCell;
        case 1: {
            // Try to re-use ThemeViewCell object.
            ThemeViewCell *cell = (ThemeViewCell *)[self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil) {
                cell = [[[ThemeViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
            }
            // Initialize cell.
            cell.backgroundImage = [UIImage imageWithContentsOfFile:[[self.stripes objectAtIndex:indexPath.row] objectForKey:@"imagePath"]];
            // Add imagemap buttons
            NSMutableArray *buttons = [NSMutableArray arrayWithCapacity:[self.imagemap count]];
            for (NSUInteger i = 0; i < [self.imagemap count]; i++) {
                NSDictionary *buttonDict = [self.imagemap objectAtIndex:i];
                if ([[buttonDict objectForKey:@"stripe"] unsignedIntValue] == indexPath.row) {
                    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
                    button.frame = CGRectMake([[buttonDict objectForKey:@"x"] unsignedIntValue],
                                              [[buttonDict objectForKey:@"y"] unsignedIntValue],
                                              [[buttonDict objectForKey:@"width"] unsignedIntValue],
                                              [[buttonDict objectForKey:@"height"] unsignedIntValue]);
                    button.tag = i;
                    [button setImage:[UIImage imageWithContentsOfFile:[buttonDict objectForKey:@"normalImagePath"]] forState:UIControlStateNormal];
                    [button setImage:[UIImage imageWithContentsOfFile:[buttonDict objectForKey:@"highlightImagePath"]] forState:UIControlStateHighlighted];
                    [button addTarget:self action:@selector(touchOnImagemap:) forControlEvents:UIControlEventTouchUpInside];
                    [buttons addObject:button];
                }
            }
            cell.buttons = buttons;
            return cell;
        }
        case 2:
            return self.bottomCell;
        default:
            NSAssert(NO, @"Unexpected switch case.");
            return nil;
    }
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
        case 2:
            return 1;
        case 1:
            return [self.stripes count];
        default:
            NSAssert(NO, @"Unexpected switch case.");
            return 0;
    }
}


#pragma mark -
#pragma mark UITableView delegate


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0:
            return self.topCell.bounds.size.height;
        case 1:
            return [[[self.stripes objectAtIndex:indexPath.row] objectForKey:@"height"] unsignedIntValue];
        case 2:
            return self.bottomCell.bounds.size.height;
        default:
            NSAssert(NO, @"Unexpected switch case.");
            return 0;
    }
}


#pragma mark -
#pragma mark UIViewController


- (void)viewDidLoad {
    [super viewDidLoad];

    // Background fill pattern.
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background-stripes.png"]];
    self.bottomCellBackgroundView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"gray-fill.png"]];

    // Fill in content.
    self.backgroundImageView.image = [UIImage imageWithContentsOfFile:self.backgroundImagePath];

    // Use fancy fonts.
    self.sourceLabel.font = selectFont(Rooney_Italic_14);
    self.currentWeekLabel.font = selectFont(Rooney_Bold_15);

    // Localize.
    self.sourceLabel.text = NSLocalizedString(@"FlipView.Sources", @"Sources.");
    self.currentWeekLabel.text = NSLocalizedString(@"Theme.CurrentWeek", @"Theme of the week.");

    // Set top cell height.
    CGRect newFrame = self.topCell.frame;
    newFrame.size.height = self.backgroundHeight;
    self.topCell.frame = newFrame;

    // Resize theme of the week box to fit text width.
    newFrame = self.currentWeekView.frame;
    newFrame.size.width = [self.currentWeekLabel.text sizeWithFont:self.currentWeekLabel.font constrainedToSize:CGSizeMake(self.currentWeekLabel.frame.size.width, MAXFLOAT) lineBreakMode:UILineBreakModeTailTruncation].width + 10;
    self.currentWeekView.frame = newFrame;

    // Show or hide theme of the week box.
    [self clockDidChange:nil];
}


- (void)viewDidUnload {
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
    self.tableView = nil;
    self.topCell = nil;
    self.bottomCell = nil;
    self.bottomCellBackgroundView = nil;
    self.sourceLabel = nil;
    self.backgroundImageView = nil;
    self.currentWeekView = nil;
    self.currentWeekLabel = nil;
    [super viewDidUnload];
}


#pragma mark -
#pragma mark NSObject


- (void)dealloc {
    [self viewDidUnload];
    self.dateRange = nil;
    self.backgroundImagePath = nil;
    self.sourceURL = nil;
    self.imagemap = nil;
    self.stripes = nil;
    [super dealloc];
}


@end
