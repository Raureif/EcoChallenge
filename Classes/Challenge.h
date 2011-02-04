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


typedef enum {
    ChallengeStateReady,
    ChallengeStateRunning,
    ChallengeStateDone,
    ChallengeStateExpired,
    ChallengeStateTeaser
} ChallengeState;


typedef enum {
    ChallengeQuestionTypeSwitch,
    ChallengeQuestionTypeMultibutton,
    ChallengeQuestionTypeSpin
} ChallengeQuestionType;


#pragma mark -


@interface Challenge: NSObject {
    ChallengeState state;
    DateRange *individualDateRange;
    NSString *ident;
    NSUInteger challengeNum;
    DateRange *globalDateRange;
    NSString *title;
    UIImage *activeIcon;
    UIImage *doneIcon;
    NSString *themeDirectory;
    Gradient *themeGradient;
    UIColor *themeColor;
    NSString *descriptionText;
    NSString *question;
    ChallengeQuestionType questionType;
    NSString *recommendation;
    NSURL *recommendationURL;
    NSString *statsText;
    NSArray *multibutton;
    NSUInteger spinAccomplished;
    NSUInteger spinMax;
    NSString *headerImagePath;
}

@property (nonatomic, assign) ChallengeState state;
@property (nonatomic, retain) DateRange *individualDateRange;
@property (nonatomic, copy) NSString *ident;
@property (nonatomic, assign) NSUInteger challengeNum;
@property (nonatomic, retain, readonly) DateRange *globalDateRange;
@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, retain, readonly) UIImage *activeIcon;
@property (nonatomic, retain, readonly) UIImage *doneIcon;
@property (nonatomic, copy, readonly) NSString *themeDirectory;
@property (nonatomic, retain, readonly) Gradient *themeGradient;
@property (nonatomic, retain, readonly) UIColor *themeColor;
@property (nonatomic, readonly) UIImage *headerImage;
@property (nonatomic, copy, readonly) NSString *descriptionText;
@property (nonatomic, copy, readonly) NSString *question;
@property (nonatomic, assign, readonly) ChallengeQuestionType questionType;
@property (nonatomic, copy, readonly) NSString *recommendation;
@property (nonatomic, retain, readonly) NSURL *recommendationURL;
@property (nonatomic, copy, readonly) NSString *statsText;
@property (nonatomic, copy, readonly) NSArray *multibutton;
@property (nonatomic, assign, readonly) NSUInteger spinAccomplished;
@property (nonatomic, assign, readonly) NSUInteger spinMax;

- (id)initWithDictionary:(NSDictionary *)dictionary themeDirectory:(NSString *)directory gradient:(Gradient *)gradient color:(UIColor *)color;
- (NSComparisonResult)compare:(Challenge *)aChallenge;

@end
