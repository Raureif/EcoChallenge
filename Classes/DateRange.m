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


@interface DateRange ()

@property (nonatomic, retain, readwrite) NSDate *from;
@property (nonatomic, retain, readwrite) NSDate *to;

@end


#pragma mark -


@implementation DateRange

@synthesize from;
@synthesize to;


- (id)initWithRangeFrom:(NSDate *)fromDate to:(NSDate *)toDate {
    if ((self = [super init])) {

        // Initialize parameters.
        self.from = fromDate;
        self.to = toDate;

        // Validate parameters.
        if (self.from == nil || self.to == nil || [[self.from laterDate:self.to] isEqual:self.from]) {
            [self release];
            self = nil;
        }
    }
    return self;
}


#pragma mark -
#pragma mark NSCopying protocol


- (id)copyWithZone:(NSZone *)zone {
    return [[[self class] allocWithZone:zone] initWithRangeFrom:self.from to:self.to];
}


#pragma mark -
#pragma mark NSObject


- (NSString *)description {
    NSInteger fromYear = [[NSCalendar currentCalendar] components:NSYearCalendarUnit fromDate:self.from].year;
    NSInteger toYear = [[NSCalendar currentCalendar] components:NSYearCalendarUnit fromDate:self.to].year;
    
    NSDateFormatter *fromFormatter = [[[NSDateFormatter alloc] init] autorelease];
    NSDateFormatter *toFormatter = [[[NSDateFormatter alloc] init] autorelease];

    if ([NSDateFormatter respondsToSelector:@selector(dateFormatFromTemplate:options:locale:)]) {
        // Use current locale for date.
        NSString *fromFormat = [NSDateFormatter dateFormatFromTemplate:(fromYear == toYear ? @"Md" : @"yMd") options:0 locale:[NSLocale currentLocale]];
        NSString *toFormat = [NSDateFormatter dateFormatFromTemplate:@"yMd" options:0 locale:[NSLocale currentLocale]];
        [fromFormatter setDateFormat:fromFormat];
        [toFormatter setDateFormat:toFormat];
    } else {
        // Fallback for iOS 3.
        [fromFormatter setDateFormat:(fromYear == toYear ? NSLocalizedString(@"iOS3.VeryShortDateFormat", @"day.month.") : NSLocalizedString(@"iOS3.ShortDateFormat", @"day.month.year"))];
        [toFormatter setDateFormat:NSLocalizedString(@"iOS3.ShortDateFormat", @"day.month.year")];
    }
    
    return [NSString stringWithFormat:NSLocalizedString(@"DateRange", @"From start date to end date."), [fromFormatter stringFromDate:self.from], [toFormatter stringFromDate:self.to]];
}


- (BOOL)isEqual:(id)anObject {
    return ([anObject isKindOfClass:[DateRange class]] &&
            [self.from isEqualToDate:((DateRange *)anObject).from] &&
            [self.to isEqualToDate:((DateRange *)anObject).to]);
}


- (NSUInteger)hash {
    return [self.from timeIntervalSince1970];
}


- (void)dealloc {
    self.from = nil;
    self.to = nil;
    [super dealloc];
}


@end
