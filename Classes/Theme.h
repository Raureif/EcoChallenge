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
    ThemeStateReady,
    ThemeStateTeaser,
    ThemeStateOnServer,
    ThemeStateDownloading,
    ThemeStateDownloadFailed
} ThemeState;


#pragma mark -


@interface Theme: NSObject {
    NSError *error;
    float progress;
    ThemeState state;
    NSString *ident;
    NSString *path;
    DateRange *dateRange;
    NSString *title;
    Gradient *gradient;
    NSURL *url;
    BOOL isTeaser;
    BOOL isDownloading;
    NSInteger version;
}

@property (nonatomic, retain) NSError *error;
@property (nonatomic, assign) float progress;
@property (nonatomic, readonly) ThemeState state;
@property (nonatomic, copy, readonly) NSString *ident;
@property (nonatomic, copy, readonly) NSString *path;
@property (nonatomic, retain, readonly) DateRange *dateRange;
@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, retain, readonly) Gradient *gradient;
@property (nonatomic, retain, readonly) NSURL *url;
@property (nonatomic, readonly) NSString *dictionaryPath;

- (void)setIsTeaser:(BOOL)aIsTeaser;
- (void)setIsDownloading:(BOOL)aIsDownloading;
- (id)initWithDictionary:(NSDictionary *)dictionary;
- (NSComparisonResult)compare:(Theme *)aTheme;

@end
