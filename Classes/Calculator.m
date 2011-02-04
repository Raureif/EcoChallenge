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

#import "Calculator.h"


@interface Calculator ()

@property (nonatomic, copy, readwrite) NSString *title;
@property (nonatomic, copy, readwrite) NSString *descriptionText;
@property (nonatomic, copy, readwrite) NSString *unitText;
@property (nonatomic, copy, readwrite) NSString *resultText;
@property (nonatomic, copy, readwrite) NSString *averageText;
@property (nonatomic, copy, readwrite) NSString *chooseText;
@property (nonatomic, retain, readwrite) NSURL *sourceURL;
@property (nonatomic, copy, readwrite) NSString *themeIdent;
@property (nonatomic, retain, readwrite) Gradient *themeGradient;
@property (nonatomic, retain, readwrite) UIColor *themeColor;
@property (nonatomic, copy, readwrite) NSArray *userItems;
@property (nonatomic, copy, readwrite) NSArray *whatItems;
@property (nonatomic, copy, readwrite) NSArray *howItems;
@property (nonatomic, copy, readwrite) NSString *resultJS;
@property (nonatomic, copy, readwrite) NSString *averageJS;
@property (nonatomic, copy, readwrite) NSString *rowJS;
@property (nonatomic, assign, readwrite) NSUInteger whatWheelPos;
@property (nonatomic, assign, readwrite) NSUInteger howWheelPos;
@property (nonatomic, assign, readwrite) BOOL noAverage;
@property (nonatomic, copy) NSString *calculatorFilename;
@property (nonatomic, retain) UIWebView *webView;

- (NSInteger)evaluateJS:(NSString *)javascript;

@end


#pragma mark -


@implementation Calculator

@synthesize title;
@synthesize descriptionText;
@synthesize unitText;
@synthesize resultText;
@synthesize averageText;
@synthesize chooseText;
@synthesize sourceURL;
@synthesize themeIdent;
@synthesize themeGradient;
@synthesize themeColor;
@synthesize userItems;
@synthesize whatItems;
@synthesize howItems;
@synthesize resultJS;
@synthesize averageJS;
@synthesize rowJS;
@synthesize whatWheelPos;
@synthesize howWheelPos;
@synthesize noAverage;
@synthesize calculatorFilename;
@synthesize webView;


- (id)initWithTheme:(Theme *)theme {
    if ((self = [super init])) {

        NSAssert(theme && theme.dictionaryPath, @"Invalid state.");
        
        // Read file Theme.plist.
        NSDictionary *themeDict = [NSDictionary dictionaryWithContentsOfFile:theme.dictionaryPath];

        // Read background color.
        self.themeColor = [UIColor blackColor];
        id object = [themeDict objectForKey:@"backgroundColor"];
        if ([object isKindOfClass:[NSNumber class]]) {
            NSUInteger intValue = [object unsignedIntValue];
            self.themeColor = [UIColor colorWithRed:((intValue >> 16) & 0xFF) / 255.0
                                              green:((intValue >>  8) & 0xFF) / 255.0
                                               blue:((intValue      ) & 0xFF) / 255.0
                                              alpha:1];
        }

        // Read calculator dictionary.
        NSDictionary *calculatorDict = [themeDict objectForKey:@"calculator"];
        if ([calculatorDict isKindOfClass:[NSDictionary class]]) {

            object = [calculatorDict objectForKey:@"title"];
            if ([object isKindOfClass:[NSString class]]) {
                self.title = object;
            }

            object = [calculatorDict objectForKey:@"description"];
            if ([object isKindOfClass:[NSString class]]) {
                self.descriptionText = object;
            }

            object = [calculatorDict objectForKey:@"unit"];
            if ([object isKindOfClass:[NSString class]]) {
                self.unitText = object;
            }
            
            object = [calculatorDict objectForKey:@"result"];
            if ([object isKindOfClass:[NSString class]]) {
                self.resultText = object;
            }            

            object = [calculatorDict objectForKey:@"average"];
            if ([object isKindOfClass:[NSString class]]) {
                self.averageText = object;
            }

            object = [calculatorDict objectForKey:@"choose"];
            if ([object isKindOfClass:[NSString class]]) {
                self.chooseText = object;
            }
            
            object = [calculatorDict objectForKey:@"sourceHTML"];
            if ([object isKindOfClass:[NSString class]]) {
                self.sourceURL = [NSURL fileURLWithPath:[[theme.dictionaryPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:object]];
            }

            NSArray *whatArray = [calculatorDict objectForKey:@"what"];
            if ([whatArray isKindOfClass:[NSArray class]]) {
                NSMutableArray *mutableWhatItems = [NSMutableArray arrayWithCapacity:[whatArray count]];
                for (NSDictionary *element in whatArray) {
                    if ([element isKindOfClass:[NSDictionary class]]) {
                        NSString *what = [element objectForKey:@"what"];
                        NSString *icon = [element objectForKey:@"icon"];
                        NSNumber *average = [element objectForKey:@"average"];
                        if ([what isKindOfClass:[NSString class]] && [icon isKindOfClass:[NSString class]] && [average isKindOfClass:[NSNumber class]]) {
                            [mutableWhatItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                         what,                                                                                           @"what",
                                                         [[theme.dictionaryPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:icon], @"icon",
                                                         average,                                                                                        @"average",
                                                         nil]];
                        }
                    }
                }
                self.whatItems = mutableWhatItems;
            }

            NSArray *howArray = [calculatorDict objectForKey:@"how"];
            if ([howArray isKindOfClass:[NSArray class]]) {
                NSMutableArray *mutableHowItems = [NSMutableArray arrayWithCapacity:[howArray count]];
                for (NSDictionary *element in howArray) {
                    if ([element isKindOfClass:[NSDictionary class]]) {
                        NSString *how = [element objectForKey:@"how"];
                        NSNumber *count = [element objectForKey:@"count"];
                        if ([how isKindOfClass:[NSString class]] && [count isKindOfClass:[NSNumber class]]) {
                            [mutableHowItems addObject:element];
                        }
                    }
                }
                self.howItems = mutableHowItems;
            }
        }
        
        object = [calculatorDict objectForKey:@"resultJS"];
        if ([object isKindOfClass:[NSString class]]) {
            self.resultJS = object;
        }

        object = [calculatorDict objectForKey:@"averageJS"];
        if ([object isKindOfClass:[NSString class]]) {
            self.averageJS = object;
        }

        object = [calculatorDict objectForKey:@"rowJS"];
        if ([object isKindOfClass:[NSString class]]) {
            self.rowJS = object;
        }
        
        object = [calculatorDict objectForKey:@"whatWheelPos"];
        if ([object isKindOfClass:[NSNumber class]]) {
            self.whatWheelPos = [object unsignedIntValue] - 1;
        }
        self.whatWheelPos = MIN(self.whatWheelPos, [self.whatItems count]);
        
        object = [calculatorDict objectForKey:@"howWheelPos"];
        if ([object isKindOfClass:[NSNumber class]]) {
            self.howWheelPos = [object unsignedIntValue] - 1;
        }
        self.howWheelPos = MIN(self.howWheelPos, [self.howItems count]);
                                   
        object = [calculatorDict objectForKey:@"noAverage"];
        if ([object isKindOfClass:[NSNumber class]]) {
            self.noAverage = [object boolValue];
        }
        
        // Save theme ident and gradient.
        self.themeIdent = theme.ident;
        self.themeGradient = theme.gradient;

        // Create filename.
        self.calculatorFilename = [[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]
                                    stringByAppendingPathComponent:@"Calculators"]
                                   stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist", theme.ident]];

        // Read user items from flash memory.
        self.userItems = [NSArray arrayWithContentsOfFile:self.calculatorFilename];
        if (self.userItems == nil) {
            self.userItems = [NSArray array];
        }
        
        // Create WebKit object for JavaScript execution. JavaScriptCore is private API. 
        self.webView = [[[UIWebView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)] autorelease];
    }
    return self;
}


- (void)addItem:(NSUInteger)whatIndex for:(NSUInteger)howIndex {
    // Combine data to one item.
    NSMutableDictionary *combinedData = [[[self.whatItems objectAtIndex:whatIndex] mutableCopy] autorelease];
    [combinedData addEntriesFromDictionary:[self.howItems objectAtIndex:howIndex]];
    // Add item to user items.
    NSMutableArray *mutableUserItems = [[self.userItems mutableCopy] autorelease];
    [mutableUserItems addObject:combinedData];
    self.userItems = mutableUserItems;
    // Save to file.
    [[NSFileManager defaultManager] createDirectoryAtPath:[self.calculatorFilename stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:NULL];
    [mutableUserItems writeToFile:self.calculatorFilename atomically:YES];
}


- (void)removeItem:(NSUInteger)index {
    // Remove item from user items.
    NSMutableArray *mutableUserItems = [[self.userItems mutableCopy] autorelease];
    [mutableUserItems removeObjectAtIndex:index];
    self.userItems = mutableUserItems;
    // Save to file.
    [[NSFileManager defaultManager] createDirectoryAtPath:[self.calculatorFilename stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:NULL];
    [mutableUserItems writeToFile:self.calculatorFilename atomically:YES];
}


- (NSInteger)resultValue {
    return (self.resultJS ? [self evaluateJS:self.resultJS] : 0);
}


- (NSInteger)averageValue {
    return (self.averageJS ? [self evaluateJS:self.averageJS] : 0);
}
                               

- (NSInteger)calculateCountFromWhatValue:(NSInteger)whatValue andRowValue:(NSInteger)howValue {
    // Fallback.
    if (self.rowJS == nil) {
        return howValue;
    }
    
    // Use JavaScript for calculation.
    NSString *js = [NSString stringWithFormat:@"value1 = %d; value2 = %d; %@", whatValue, howValue, self.rowJS];
    return [[self.webView stringByEvaluatingJavaScriptFromString:js] intValue];
}


- (NSInteger)evaluateJS:(NSString *)javascript {
    // Create JavaScript array with result values.
    NSMutableString *js = [NSMutableString stringWithCapacity:8192];
    if ([self.userItems count] == 1) {
        [js appendFormat:@"values1 = new Array(1); values1[0] = %@;", [[self.userItems objectAtIndex:0] objectForKey:@"count"]];
    } else {
        [js appendString:@"values1 = new Array("];
        for (NSUInteger i = 0; i < [self.userItems count]; i++) {
            NSDictionary *userItem = [self.userItems objectAtIndex:i];
            if (i == 0) {
                [js appendFormat:@"%@", [userItem objectForKey:@"count"]];
            } else {
                [js appendFormat:@", %@", [userItem objectForKey:@"count"]];
            }
        }   
        [js appendString:@"); "];
    }
    
    // Create JavaScript array with average values.
    if ([self.userItems count] == 1) {
        [js appendFormat:@"values2 = new Array(1); values2[0] = %@;", [[self.userItems objectAtIndex:0] objectForKey:@"average"]];
    } else {
        [js appendString:@"values2 = new Array("];
        for (NSUInteger i = 0; i < [self.userItems count]; i++) {
            NSDictionary *userItem = [self.userItems objectAtIndex:i];
            if (i == 0) {
                [js appendFormat:@"%@", [userItem objectForKey:@"average"]];
            } else {
                [js appendFormat:@", %@", [userItem objectForKey:@"average"]];
            }
        }    
        [js appendString:@"); "];
    }
    
    // Use JavaScript for calculation.
    [js appendString:javascript];
    return [[self.webView stringByEvaluatingJavaScriptFromString:js] intValue];
}


#pragma mark -
#pragma mark NSObject


- (void)dealloc {
    self.title = nil;
    self.descriptionText = nil;
    self.unitText = nil;
    self.resultText = nil;
    self.averageText = nil;
    self.chooseText = nil;
    self.sourceURL = nil;
    self.themeIdent = nil;
    self.themeGradient = nil;
    self.themeColor = nil;
    self.userItems = nil;
    self.whatItems = nil;
    self.howItems = nil;
    self.resultJS = nil;
    self.averageJS = nil;
    self.rowJS = nil;
    self.calculatorFilename = nil;
    self.webView = nil;
    [super dealloc];
}


@end
