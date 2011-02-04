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


@interface ThemeListViewCellView: UIView {
    UIColor *fontColor;
    NSString *supertitle;
    NSString *title;
    NSString *subtitle;
    UIImage *buttonImage;
    NSArray *icons;
    CGPoint offset;
}

@property (nonatomic, retain) UIColor *fontColor;
@property (nonatomic, copy) NSString *supertitle;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, retain) UIImage *buttonImage;
@property (nonatomic, copy) NSArray *icons;
@property (nonatomic, assign) CGPoint offset;

@end