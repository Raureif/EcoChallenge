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


typedef enum {
    ScoreListViewCellTypeLogin,
    ScoreListViewCellTypeSpoiler,
    ScoreListViewCellTypeWaiting,
    ScoreListViewCellTypeError,
    ScoreListViewCellTypeNoFriends,
    ScoreListViewCellTypeChallengeList,
    ScoreListViewCellTypeChallenge,
    ScoreListViewCellTypeAchievement,
    ScoreListViewCellTypeCalculator
} ScoreListViewCellType;


#pragma mark -


@interface ScoreListViewCell: UITableViewCell <MFMailComposeViewControllerDelegate> {
    ScoreListViewCellType type;
    BOOL roundedCornersOnTop;
    BOOL roundedCornersOnBottom;
    BOOL separatorLine;
    BOOL stripes;
    UIImage *backgroundTexture;
    UIColor *backgroundFill;
    UIImage *photo;
    NSString *name;
    NSArray *values;
    CGFloat sideOffset;
    UIWebView *webView;
    UIButton *button;
    UILabel *label;
    UIActivityIndicatorView *activityIndicatorView;
}

+ (CGFloat)cellHeight;

@property (nonatomic, assign) ScoreListViewCellType type;
@property (nonatomic, assign) BOOL roundedCornersOnTop;
@property (nonatomic, assign) BOOL roundedCornersOnBottom;
@property (nonatomic, assign) BOOL separatorLine;
@property (nonatomic, assign) BOOL stripes;
@property (nonatomic, retain) UIImage *backgroundTexture;
@property (nonatomic, retain) UIColor *backgroundFill;
@property (nonatomic, retain) UIImage *photo;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSArray *values;
@property (nonatomic, assign) CGFloat sideOffset;
@property (nonatomic, retain) UIWebView *webView;

@end
