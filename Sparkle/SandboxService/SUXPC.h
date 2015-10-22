//
//  SUXPC.h
//  Sparkle
//
//  Created by Whitney Young on 3/19/12.
//  Copyright (c) 2012 FadingRed. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SUXPC : NSObject

+ (void)launchTaskWithLaunchPath:(NSString *)path arguments:(NSArray *)arguments;

@end
