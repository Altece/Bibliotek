//
//  BibRecord.Private.h
//  Bibliotek
//
//  Created by Steve Brunwasser on 5/15/18.
//  Copyright © 2018 Steve Brunwasser. All rights reserved.
//

#import "BibRecord.h"
#import <yaz/zoom.h>

NS_ASSUME_NONNULL_BEGIN

@interface BibRecord ()

@property(nonatomic, readonly, assign) ZOOM_record zoomRecord;

- (instancetype)initWithZoomRecord:(ZOOM_record)zoomRecord;

@end

NS_ASSUME_NONNULL_END
