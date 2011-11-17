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


@protocol ThemeDownloaderProtocol <NSObject>

- (void)themeStateChanged:(Theme *)theme;

@end


#pragma mark -


// Singleton object.
@interface ThemeDownloader: NSObject <NSURLConnectionDataDelegate, NSURLConnectionDelegate> {
    id <ThemeDownloaderProtocol> delegate;
    Theme *downloadingTheme;
    NSMutableArray *downloadQueue;
    NSURLConnection *connection;
    NSFileHandle *tempFileHandle;
    NSString *tempFile;
    NSUInteger tempFileSize;
    UIBackgroundTaskIdentifier backgroundTaskIdentifier;
}

+ (ThemeDownloader *)sharedInstance;

@property (nonatomic, assign) id <ThemeDownloaderProtocol> delegate;

- (void)downloadTheme:(Theme *)theme;
- (void)cancelThemeDownload:(Theme *)theme;
- (void)cancelAllThemeDownloads;

@end
