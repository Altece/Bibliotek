//
//  NSCharacterSet+BibLowercaseAlphanumericCharacterSet.h
//  Bibliotek
//
//  Created by Steve Brunwasser on 1/24/19.
//  Copyright © 2019 Steve Brunwasser. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSCharacterSet (BibLowercaseAlphanumericCharacterSet)

@property (class, nonatomic, strong, readonly) NSCharacterSet *bib_lowercaseAlphanumericCharacterSet;

@end

NS_ASSUME_NONNULL_END
