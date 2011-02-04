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

#import "DateRange.h"
#import "Gradient.h"
#import "ThemeListViewCellView.h"
#import "Theme.h"


@interface ThemeListViewCell: UITableViewCell {
    DateRange *dateRange;
    NSString *title;
    NSError *error;
    Gradient *gradient;
    BOOL isExpired;
    NSArray *challenges;
    float progress;
    ThemeState themeState;
    ThemeListViewCellView *themeListViewCellView;
    NSTimer *timer;
    UIProgressView *progressView;
    UIActivityIndicatorView *activityIndicatorView;
    BOOL drawHighlighted;
}

+ (CGFloat)cellHeightForThemeState:(ThemeState)themeState;

@property (nonatomic, retain) DateRange *dateRange;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, retain) NSError *error;
@property (nonatomic, retain) Gradient *gradient;
@property (nonatomic, assign) BOOL isExpired;
@property (nonatomic, copy) NSArray *challenges;
@property (nonatomic, assign) float progress;
@property (nonatomic, assign) ThemeState themeState;

- (void)setThemeState:(ThemeState)aThemeState animated:(BOOL)animated;

@end
