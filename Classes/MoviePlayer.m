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

#import "MainViewController.h"
#import "MoviePlayer.h"


@interface MoviePlayer ()

@property (nonatomic, retain) MPMoviePlayerController *moviePlayerController;

- (void)moviePlaybackDidFinish:(NSNotification *)notification;
- (void)moviePlayerLoadStateDidChange:(NSNotification *)notification;

@end


#pragma mark -


@implementation MoviePlayer

@synthesize moviePlayerController;


static MoviePlayer *sharedInstance = nil;


+ (MoviePlayer *)sharedInstance {
    if (sharedInstance == nil) {
        // Create singleton object.
        sharedInstance = [[MoviePlayer alloc] init];
    }
    return sharedInstance;
}


- (void)play:(NSURL *)url {
    // Register for movie player event.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlaybackDidFinish:) name:MPMoviePlayerPlaybackDidFinishNotification object:nil]; 
    if ([[[UIDevice currentDevice] systemVersion] compare:@"3.2" options:NSNumericSearch] != NSOrderedAscending) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlaybackDidFinish:) name:MPMoviePlayerWillExitFullscreenNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayerLoadStateDidChange:) name:MPMoviePlayerLoadStateDidChangeNotification object:nil];
    }
    
    // Show modal view.
    [[MainViewController sharedInstance] presentModalViewController:self animated:NO];
    
    // Rotate to landscape.
    [UIApplication sharedApplication].statusBarOrientation = UIInterfaceOrientationLandscapeRight;
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleBlackTranslucent;
    self.view.bounds = CGRectMake(0, 0, 480, 320);
    self.view.center = CGPointMake(160, 240);
    self.view.transform = CGAffineTransformMakeRotation(M_PI / 2);
    
    // Create movie player controller.
    self.moviePlayerController = [[[MPMoviePlayerController alloc] initWithContentURL:url] autorelease];
    if ([self.moviePlayerController respondsToSelector:@selector(view)]) {
        self.moviePlayerController.view.frame = CGRectMake(0, 0, 480, 320);
        [self.view addSubview:moviePlayerController.view];
    }
    if ([self.moviePlayerController respondsToSelector:@selector(setFullscreen:)]) {
        moviePlayerController.fullscreen = YES;
    }
    if ([self.moviePlayerController respondsToSelector:@selector(setControlStyle:)]) {
        moviePlayerController.controlStyle = MPMovieControlStyleNone;
    }    
    [moviePlayerController play];
}


- (void)moviePlaybackDidFinish:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
    if ([[[UIDevice currentDevice] systemVersion] compare:@"3.2" options:NSNumericSearch] != NSOrderedAscending) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerWillExitFullscreenNotification object:nil];
    }
    if ([self.moviePlayerController respondsToSelector:@selector(pause)]) {
        [self.moviePlayerController pause];
    }
    if ([self.moviePlayerController respondsToSelector:@selector(stop)]) {
        [self.moviePlayerController stop];
    }
    if ([self.moviePlayerController respondsToSelector:@selector(view)]) {
        [self.moviePlayerController.view removeFromSuperview];
    }
    self.moviePlayerController = nil;
    [UIApplication sharedApplication].statusBarOrientation = UIInterfaceOrientationPortrait;
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleBlackOpaque;
    [UIApplication sharedApplication].statusBarHidden = NO;
    [self dismissModalViewControllerAnimated:NO];
}


- (void)moviePlayerLoadStateDidChange:(NSNotification *)notification {
    // Initially no controls are shown. But we enable them afterwards.
    moviePlayerController.controlStyle = MPMovieControlStyleFullscreen;
}


#pragma mark -
#pragma mark NSObject


+ (id)allocWithZone:(NSZone *)zone {
    if (sharedInstance == nil) {
        sharedInstance = [super allocWithZone:zone];
        return sharedInstance;
    }
    return nil;
}


- (id)copyWithZone:(NSZone *)zone {
    return self;
}


- (id)retain {
    return self;
}


- (NSUInteger)retainCount {
    // Object cannot be released.
    return NSUIntegerMax;
}


- (void)release {
    // Do nothing.
}


- (id)autorelease {
    return self;
}


@end
