//
//  BibBibliographicRecord.h
//  Bibliotek
//
//  Created by Steve Brunwasser on 2/25/19.
//  Copyright © 2019 Steve Brunwasser. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BibRecord.h"
#import "BibRecordConstants.h"

@class BibDDClassificationCallNumber;
@class BibLCClassificationCallNumber;

@protocol BibClassificationCallNumber;

NS_ASSUME_NONNULL_BEGIN

/// http://www.loc.gov/marc/bibliographic/
NS_SWIFT_NAME(BibliographicRecord)
@interface BibBibliographicRecord : BibRecord

@property (nonatomic, copy, readonly) NSArray<BibDDClassificationCallNumber *> *ddcCallNumbers;

@property (nonatomic, copy, readonly) NSArray<BibLCClassificationCallNumber *> *lccCallNumbers;

@end

NS_ASSUME_NONNULL_END
