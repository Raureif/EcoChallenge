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
#import "Gradient.h"


@interface Calculator: NSObject {
    NSString *title;
    NSString *descriptionText;
    NSString *unitText;
    NSString *resultText;
    NSString *averageText;
    NSString *chooseText;
    NSURL *sourceURL;
    NSString *themeIdent;
    Gradient *themeGradient;
    UIColor *themeColor;
    NSArray *userItems;
    NSArray *whatItems;
    NSArray *howItems;
    NSString *resultJS;
    NSString *averageJS;
    NSString *rowJS;
    NSUInteger whatWheelPos;
    NSUInteger howWheelPos;
    BOOL noAverage;
    NSString *calculatorFilename;
    UIWebView *webView;
}

@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, copy, readonly) NSString *descriptionText;
@property (nonatomic, copy, readonly) NSString *unitText;
@property (nonatomic, copy, readonly) NSString *resultText;
@property (nonatomic, copy, readonly) NSString *averageText;
@property (nonatomic, copy, readonly) NSString *chooseText;
@property (nonatomic, retain, readonly) NSURL *sourceURL;
@property (nonatomic, copy, readonly) NSString *themeIdent;
@property (nonatomic, retain, readonly) Gradient *themeGradient;
@property (nonatomic, retain, readonly) UIColor *themeColor;
@property (nonatomic, copy, readonly) NSArray *userItems;
@property (nonatomic, copy, readonly) NSArray *whatItems;
@property (nonatomic, copy, readonly) NSArray *howItems;
@property (nonatomic, copy, readonly) NSString *resultJS;
@property (nonatomic, copy, readonly) NSString *averageJS;
@property (nonatomic, copy, readonly) NSString *rowJS;
@property (nonatomic, assign, readonly) NSUInteger whatWheelPos;
@property (nonatomic, assign, readonly) NSUInteger howWheelPos;
@property (nonatomic, assign, readonly) BOOL noAverage;

- (id)initWithTheme:(Theme *)theme;
- (void)addItem:(NSUInteger)whatIndex for:(NSUInteger)howIndex;
- (void)removeItem:(NSUInteger)index;
- (NSInteger)resultValue;
- (NSInteger)averageValue;
- (NSInteger)calculateCountFromWhatValue:(NSInteger)whatValue andRowValue:(NSInteger)howValue;

@end

