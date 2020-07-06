//
//  BibFieldIndicator.m
//  Bibliotek
//
//  Created by Steve Brunwasser on 6/7/20.
//  Copyright © 2020 Steve Brunwasser. All rights reserved.
//

#import "BibFieldIndicator.h"
#import "Bibliotek+Internal.h"
#import <objc/runtime.h>
#import <objc/message.h>

static size_t const BibIndicatorCount = 37;
static size_t BibIndicatorInstanceSize;
static void *BibIndicatorBuffer;

@interface _BibFieldIndicator : BibFieldIndicator
@end

__attribute__((always_inline))
static inline size_t BibIndicatorGetCacheIndexForRawValue(char rawValue) {
    if (rawValue == ' ') { return 0; }
    if (rawValue >= '0' && rawValue <= '9') { return (rawValue - '0') + 1; }
    if (rawValue >= 'a' && rawValue <= 'z') { return (rawValue - 'a') + 11; }
    [NSException raise:NSRangeException format:@"Invalid indicator characher '%c'", rawValue];
    return NSNotFound;
}

__attribute__((always_inline))
static inline char BibIndicatorGetRawValueForCacheIndex(size_t index) {
    if (index == 0) { return ' '; }
    if (index >= 1 && index <= 10) { return '0' + (index - 1); }
    if (index >= 11 && index <= 36) { return 'a' + (index - 11); }
    [NSException raise:NSRangeException format:@"Cache index %zu is out of bounds", index];
    return -1;
}

__attribute__((always_inline))
static inline _BibFieldIndicator *BibIndicatorGetCachedInstanceAtIndex(size_t index)  {
    return BibIndicatorBuffer + (index * BibIndicatorInstanceSize);
}

@implementation BibFieldIndicator {
@protected
    char rawValue;
}

@synthesize rawValue = rawValue;

+ (BibFieldIndicator *)blank { return [BibFieldIndicator indicatorWithRawValue:' ']; }

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return (self == [BibFieldIndicator self]) ? BibIndicatorGetCachedInstanceAtIndex(0) : [super allocWithZone:zone];
}

- (instancetype)initWithRawValue:(char)rawValue {
    if (self = [super init]) {
        self->rawValue = rawValue;
    }
    return self;
}

+ (instancetype)indicatorWithRawValue:(char)rawValue {
    if (self == [BibFieldIndicator self]) {
        return [_BibFieldIndicator indicatorWithRawValue:rawValue];
    } else {
        return [[[self alloc] initWithRawValue:rawValue] autorelease];
    }
}

- (instancetype)init {
    return [self initWithRawValue:' '];
}

- (id)copyWithZone:(NSZone *)zone { return self; }

+ (instancetype)objectAtIndexedSubscript:(char)rawValue {
    return [self indicatorWithRawValue:rawValue];
}

#pragma mark - NSCoding

+ (BOOL)supportsSecureCoding { return YES; }

- (instancetype)initWithCoder:(NSCoder *)coder {
    char const rawValue = (char)[coder decodeIntForKey:BibKey(rawValue)];
    return [self initWithRawValue:rawValue];
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeInt:(int)(self->rawValue) forKey:BibKey(rawValue)];
}

#pragma mark - Equality

- (BOOL)isEqualToIndicator:(BibFieldIndicator *)indicator {
    return self == indicator
        || (self->rawValue == indicator->rawValue);
}

- (BOOL)isEqual:(id)object {
    return (self == object)
        || ([object isKindOfClass:[BibFieldIndicator self]] && [self isEqual:object]);
}

- (NSUInteger)hash {
    return (NSUInteger)self->rawValue;
}

#pragma mark - Description

- (NSString *)description {
    return (self->rawValue == ' ') ? @"\u2422" : [NSString stringWithFormat:@"%c", self->rawValue];
}

#if DEBUG
- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"<BibFieldIndicator rawValue='%c', %#04X; '%@'>",
                                      self->rawValue, self->rawValue, [self description]];
}
#endif

@end

#pragma mark -

@implementation _BibFieldIndicator

+ (void)load {
    BibIndicatorInstanceSize = class_getInstanceSize(self);
    BibIndicatorBuffer = calloc(BibIndicatorCount, BibIndicatorInstanceSize);
    for (size_t index = 0; index < BibIndicatorCount; index += 1) {
        BibFieldIndicator *indicator = BibIndicatorGetCachedInstanceAtIndex(index);
        objc_constructInstance(self, indicator);
        struct objc_super _super = { indicator, [NSObject self] };
        ((id(*)(struct objc_super *, SEL))objc_msgSendSuper)(&_super, @selector(init));
        indicator->rawValue = BibIndicatorGetRawValueForCacheIndex(index);
    }
}

- (instancetype)initWithRawValue:(char)rawValue {
    size_t const index = BibIndicatorGetCacheIndexForRawValue((uint8_t)rawValue);
    self = BibIndicatorGetCachedInstanceAtIndex(index);
    NSParameterAssert(self != nil);
    return self;
}

+ (instancetype)indicatorWithRawValue:(char)rawValue {
    size_t const index = BibIndicatorGetCacheIndexForRawValue((uint8_t)rawValue);
    _BibFieldIndicator *indicator = [BibIndicatorGetCachedInstanceAtIndex(index) retain];
    NSParameterAssert(indicator != nil);
    return indicator;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-missing-super-calls"
- (void)dealloc {}
#pragma clang diagnostic pop

- (instancetype)retain { return self; }

- (oneway void)release {}

- (instancetype)autorelease { return self; }

- (NSUInteger)retainCount { return 1; }

@end
