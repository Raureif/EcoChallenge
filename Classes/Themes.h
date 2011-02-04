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


@protocol ThemesProtocol <NSObject>

- (void)refreshThemeList:(NSArray *)themeList;

@end


#pragma mark -


// Singleton object.
@interface Themes: NSObject {
    NSArray *allThemes;
    id <ThemesProtocol> delegate;
    NSInteger version;
    NSURLConnection *connection;
    NSMutableData *responseData;
}

+ (Themes *)sharedInstance;

@property (nonatomic, assign) id <ThemesProtocol> delegate;
@property (nonatomic, readonly) NSArray *themes;

// Usually the update check is performed automatically. With this method the update check is enforced.
- (void)checkForUpdatesNow;

@end

