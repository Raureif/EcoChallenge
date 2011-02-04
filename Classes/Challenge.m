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

#import "Challenge.h"


@interface Challenge ()

@property (nonatomic, retain, readwrite) DateRange *globalDateRange;
@property (nonatomic, copy, readwrite) NSString *title;
@property (nonatomic, retain, readwrite) UIImage *activeIcon;
@property (nonatomic, retain, readwrite) UIImage *doneIcon;
@property (nonatomic, copy, readwrite) NSString *themeDirectory;
@property (nonatomic, retain, readwrite) Gradient *themeGradient;
@property (nonatomic, retain, readwrite) UIColor *themeColor;
@property (nonatomic, copy, readwrite) NSString *descriptionText;
@property (nonatomic, copy, readwrite) NSString *question;
@property (nonatomic, assign, readwrite) ChallengeQuestionType questionType;
@property (nonatomic, copy, readwrite) NSString *recommendation;
@property (nonatomic, retain, readwrite) NSURL *recommendationURL;
@property (nonatomic, copy, readwrite) NSString *statsText;
@property (nonatomic, copy, readwrite) NSArray *multibutton;
@property (nonatomic, assign, readwrite) NSUInteger spinAccomplished;
@property (nonatomic, assign, readwrite) NSUInteger spinMax;
@property (nonatomic, copy) NSString *headerImagePath;

@end


#pragma mark -


@implementation Challenge

@synthesize state;
@synthesize individualDateRange;
@synthesize ident;
@synthesize challengeNum;
@synthesize globalDateRange;
@synthesize title;
@synthesize activeIcon;
@synthesize doneIcon;
@synthesize themeDirectory;
@synthesize themeGradient;
@synthesize themeColor;
@synthesize descriptionText;
@synthesize question;
@synthesize questionType;
@synthesize recommendation;
@synthesize recommendationURL;
@synthesize statsText;
@synthesize multibutton;
@synthesize spinAccomplished;
@synthesize spinMax;
@synthesize headerImagePath;


- (UIImage *)headerImage {
    return [UIImage imageWithContentsOfFile:self.headerImagePath];
}


// Designated initializer.
- (id)initWithDictionary:(NSDictionary *)dictionary themeDirectory:(NSString *)directory gradient:(Gradient *)gradient color:(UIColor *)color {
    if ((self = [super init])) {

        // Store parameters.
        self.themeDirectory = directory;
        self.themeGradient = gradient;
        self.themeColor = color;

        // Create date formatter.
        NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
        NSLocale *locale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"] autorelease];
        [dateFormatter setLocale:locale];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"Europe/Berlin"]];
        [dateFormatter setDateFormat:@"yyyy-MM-dd"];

        // Initialize parameters from dictionary.

        id object = [dictionary objectForKey:@"fromDate"];
        if ([object isKindOfClass:[NSString class]]) {
            NSDate *fromDate = [dateFormatter dateFromString:object];
            object = [dictionary objectForKey:@"toDate"];
            if ([object isKindOfClass:[NSString class]]) {
                NSDate *toDate = [dateFormatter dateFromString:object];
                self.globalDateRange = [[[DateRange alloc] initWithRangeFrom:fromDate to:toDate] autorelease];
            }
        }

        object = [dictionary objectForKey:@"title"];
        if ([object isKindOfClass:[NSString class]]) {
            self.title = object;
        }

        object = [dictionary objectForKey:@"activeIcon"];
        if ([object isKindOfClass:[NSString class]]) {
            self.activeIcon = [UIImage imageWithContentsOfFile:[self.themeDirectory stringByAppendingPathComponent:object]];
        }

        object = [dictionary objectForKey:@"doneIcon"];
        if ([object isKindOfClass:[NSString class]]) {
            self.doneIcon = [UIImage imageWithContentsOfFile:[self.themeDirectory stringByAppendingPathComponent:object]];
        }

        object = [dictionary objectForKey:@"headerImage"];
        if ([object isKindOfClass:[NSString class]]) {
            self.headerImagePath = [self.themeDirectory stringByAppendingPathComponent:object];
        }

        object = [dictionary objectForKey:@"description"];
        if ([object isKindOfClass:[NSString class]]) {
            self.descriptionText = object;
        }

        object = [dictionary objectForKey:@"question"];
        if ([object isKindOfClass:[NSString class]]) {
            self.question = object;
        }

        self.questionType = -1;
        object = [dictionary objectForKey:@"questionType"];
        if ([object isKindOfClass:[NSString class]]) {
            if ([object isEqualToString:@"switch"]) {
                self.questionType = ChallengeQuestionTypeSwitch;
            } else if ([object isEqualToString:@"multibutton"]) {
                self.questionType = ChallengeQuestionTypeMultibutton;
            } else if ([object isEqualToString:@"spin"]) {
                self.questionType = ChallengeQuestionTypeSpin;
            }
        }

        if (self.questionType == ChallengeQuestionTypeMultibutton) {
            object = [dictionary objectForKey:@"multibutton"];
            if ([object isKindOfClass:[NSArray class]] && [object count] > 0 && [object count] <= 6) {
                BOOL erroneous = NO;
                NSMutableArray *mutableMultibutton = [NSMutableArray arrayWithCapacity:[object count]];
                for (NSDictionary *item in object) {
                    NSString *activeIconFile = [item objectForKey:@"activeIcon"];
                    NSString *inactiveIconFile = [item objectForKey:@"inactiveIcon"];
                    NSString *doneIconFile = [item objectForKey:@"doneIcon"];
                    if (activeIconFile == nil || inactiveIconFile == nil || doneIconFile == nil) {
                        erroneous = YES;
                        break;
                    }
                    UIImage *activeButtonIcon = [UIImage imageWithContentsOfFile:[self.themeDirectory stringByAppendingPathComponent:activeIconFile]];
                    UIImage *inactiveButtonIcon = [UIImage imageWithContentsOfFile:[self.themeDirectory stringByAppendingPathComponent:inactiveIconFile]];
                    UIImage *doneButtonIcon = [UIImage imageWithContentsOfFile:[self.themeDirectory stringByAppendingPathComponent:doneIconFile]];
                    if (activeButtonIcon == nil || inactiveButtonIcon == nil || doneButtonIcon == nil) {
                        erroneous = YES;
                        break;
                    }
                    [mutableMultibutton addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                   activeButtonIcon,   @"activeIcon",
                                                   inactiveButtonIcon, @"inactiveIcon",
                                                   doneButtonIcon,     @"doneIcon",
                                                   nil]];
                }
                if (erroneous == NO) {
                    self.multibutton = mutableMultibutton;
                }
            }
        }

        if (self.questionType == ChallengeQuestionTypeSpin) {
            self.spinMax = 100;
            self.spinAccomplished = 100;
            object = [dictionary objectForKey:@"spinMax"];
            if ([object isKindOfClass:[NSNumber class]] && [object intValue] > 0 && [object unsignedIntValue] <= 99) {
                self.spinMax = [object unsignedIntValue];
            }
            object = [dictionary objectForKey:@"spinAccomplished"];
            if ([object isKindOfClass:[NSNumber class]] && [object intValue] > 0 && [object unsignedIntValue] <= self.spinMax) {
                self.spinAccomplished = [object unsignedIntValue];
            }
        }

        object = [dictionary objectForKey:@"recommendation"];
        if ([object isKindOfClass:[NSString class]]) {
            self.recommendation = object;
        }

        object = [dictionary objectForKey:@"recommendationHTML"];
        if ([object isKindOfClass:[NSString class]]) {
            self.recommendationURL = [NSURL fileURLWithPath:[self.themeDirectory stringByAppendingPathComponent:object]];
        }

        object = [dictionary objectForKey:@"stats"];
        if ([object isKindOfClass:[NSString class]]) {
            // Remove trailing dot.
            if ([object characterAtIndex:([object length] - 1)] == '.') {
                self.statsText = [object substringToIndex:[object length] - 1];
            } else {
                self.statsText = object;
            }
        }

        // Validate parameters.
        if (self.themeDirectory.length == 0 || self.themeGradient == nil || self.themeColor == nil ||
            self.globalDateRange == nil || self.title.length == 0 || self.activeIcon == nil || self.doneIcon == nil ||
            self.headerImagePath.length == 0 || self.headerImage == nil || self.descriptionText.length == 0 ||
            self.question.length == 0 || self.questionType == -1 || self.recommendation.length == 0 ||
            self.recommendationURL == nil || self.statsText.length == 0 ||
            (self.questionType == ChallengeQuestionTypeMultibutton && self.multibutton == nil) ||
            (self.questionType == ChallengeQuestionTypeSpin && (self.spinAccomplished == 100 || self.spinMax == 100))) {
            [self release];
            self = nil;
        }
    }
    return self;
}


- (NSComparisonResult)compare:(Challenge *)aChallenge {
    // Challenges are sorted by start date in ascending order
    return [self.globalDateRange.from compare:aChallenge.globalDateRange.from];
}


#pragma mark -
#pragma mark NSObject


- (NSString *)description {
    return [NSString stringWithFormat:@"%@: %@ (%@)", self.globalDateRange, self.title, self.ident];
}


- (void)dealloc {
    self.individualDateRange = nil;
    self.ident = nil;
    self.globalDateRange = nil;
    self.title = nil;
    self.activeIcon = nil;
    self.doneIcon = nil;
    self.themeDirectory = nil;
    self.themeGradient = nil;
    self.themeColor = nil;
    self.descriptionText = nil;
    self.question = nil;
    self.recommendation = nil;
    self.recommendationURL = nil;
    self.statsText = nil;
    self.multibutton = nil;
    self.headerImagePath = nil;
    [super dealloc];
}


@end
