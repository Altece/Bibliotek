//
//  BibLCCallNumber.m
//  Bibliotek
//
//  Created by Steve Brunwasser on 5/25/20.
//  Copyright © 2020 Steve Brunwasser. All rights reserved.
//

#import "BibLCCallNumber.h"
#import "BibLCCallNumber+Internal.h"
#import "bibtype.h"

@implementation BibLCCallNumber {
    bib_lc_calln_t _rawCallNumber;
    bib_lc_callnum_t _calln;
}

@synthesize stringValue = _stringValue;

- (instancetype)initWithString:(NSString *)string
{
    if (self = [super init]) {
        NSCharacterSet *const whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
        NSString *const trimmed = [string stringByTrimmingCharactersInSet:whitespace];
        if (!bib_lc_callnum_init(&_calln, [trimmed cStringUsingEncoding:NSASCIIStringEncoding])) {
            return nil;
        }
    }
    return self;
}

+ (instancetype)callNumberWithString:(NSString *)string
{
    return [[BibLCCallNumber alloc] initWithString:string];
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (void)dealloc
{
    bib_lc_callnum_deinit(&_calln);
}

- (NSString *)description {
    return [self stringValue];
}

- (NSString *)stringValue
{
    if (_stringValue == nil) {
        NSMutableString *const string = [NSMutableString new];
        [string appendFormat:@"%s%s", _calln.caption.letters, _calln.caption.integer];
        if (_calln.caption.decimal[0] != '\0') {
            [string appendFormat:@".%s", _calln.caption.decimal];
        }
        if (_calln.caption.date[0] != '\0') {
            [string appendFormat:@" %s", _calln.caption.date];
        }
        if (_calln.caption.ordinal.number[0] != '\0') {
            [string appendFormat:@" %s", _calln.caption.ordinal.number];
            if (_calln.caption.ordinal.suffix[0] != '\0') {
                [string appendFormat:@"%s", _calln.caption.ordinal.suffix];
            }
        }
        for (size_t index = 0; (index < 3) && (_calln.cutters[index].number[0] != '\0'); index += 1) {
            if (index == 0) {
                [string appendString:@"."];
            } else {
                [string appendString:@" "];
            }
            [string appendFormat:@"%s", _calln.cutters[index].number];
            if (_calln.cutters[index].suffix[0] != '\0') {
                [string appendFormat:@"%s", _calln.cutters[index].suffix];
            }
            if (_calln.cutters[index].date[0] != '\0') {
                [string appendFormat:@" %s", _calln.cutters[index].date];
            }
        }
        for (size_t index = 0; index < _calln.special_count; index += 1) {
            switch (_calln.special[index].spec) {
                case bib_lc_special_spec_date:
                    [string appendFormat:@" %s", _calln.special[index].value.date];
                    break;
                case bib_lc_special_spec_suffix:
                    [string appendFormat:@"%s", _calln.special[index].value.suffix];
                    break;
                case bib_lc_special_spec_ordinal:
                    [string appendFormat:@" %s%s", _calln.special[index].value.ordinal.number,
                                                   _calln.special[index].value.ordinal.suffix];
                    break;
                case bib_lc_special_spec_workmark:
                    [string appendFormat:@"%s", _calln.special[index].value.workmark];
                    break;
                case bib_lc_special_spec_datespan:
                    [string appendFormat:@"%s-%s", _calln.special[index].value.datespan.date,
                                                   _calln.special[index].value.datespan.span];
                    break;
            }
        }
        _stringValue = [string copy];
    }
    return _stringValue;
}

- (NSComparisonResult)compare:(BibLCCallNumber *)other
{
    switch ([self compareWithCallNumber:other forSpecialization:NO]) {
        case BibClassificationOrderedDescending: return NSOrderedDescending;
        case BibClassificationOrderedSame: return NSOrderedSame;
        case BibClassificationOrderedAscending: return NSOrderedAscending;
        case BibClassificationOrderedSpecifying: return NSOrderedAscending;
    }
}

- (BibClassificationComparisonResult)compareWithCallNumber:(BibLCCallNumber *)other
{
    return [self compareWithCallNumber:other forSpecialization:YES];
}

- (BibClassificationComparisonResult)compareWithCallNumber:(BibLCCallNumber *)other forSpecialization:(BOOL)specialize
{
    if (other == nil) {
        return BibClassificationOrderedDescending;
    }

    bib_lc_calln_t const *const leftn = &_rawCallNumber;
    bib_lc_calln_t const *const rightn = &(other->_rawCallNumber);

    string_specialized_comparison_result_t result = string_specialized_ordered_same;
    result = string_specialized_compare(result, leftn->alphabetic_segment, rightn->alphabetic_segment);
    if (result == string_specialized_ordered_ascending) { return BibClassificationOrderedAscending; }
    if (result == string_specialized_ordered_descending) { return BibClassificationOrderedDescending; }
    if (!specialize && result == BibClassificationOrderedSpecifying) { return BibClassificationOrderedAscending; }

    if (result == string_specialized_ordered_specifying && (leftn->whole_number[0] != '\0')) { return BibClassificationOrderedAscending; }
    int const leftNum = atoi(leftn->whole_number);
    int const rightNum = atoi(rightn->whole_number);
    if (leftNum != rightNum) { return (leftNum < rightNum) ? BibClassificationOrderedAscending : BibClassificationOrderedDescending; }

    result = string_specialized_compare(result, leftn->decimal_number, rightn->decimal_number);
    if (!specialize && result == BibClassificationOrderedSpecifying) { return BibClassificationOrderedAscending; }
    result = string_specialized_compare(result, leftn->date_or_other_number, rightn->date_or_other_number);
    if (!specialize && result == BibClassificationOrderedSpecifying) { return BibClassificationOrderedAscending; }
    result = string_specialized_compare(result, leftn->first_cutter_number, rightn->first_cutter_number);
    if (!specialize && result == BibClassificationOrderedSpecifying) { return BibClassificationOrderedAscending; }
    result = string_specialized_compare(result, leftn->date_or_other_number_after_first_cutter, rightn->date_or_other_number_after_first_cutter);
    if (!specialize && result == BibClassificationOrderedSpecifying) { return BibClassificationOrderedAscending; }
    result = string_specialized_compare(result, leftn->second_cutter_number, rightn->second_cutter_number);
    if (!specialize && result == BibClassificationOrderedSpecifying) { return BibClassificationOrderedAscending; }

    switch (result) {
        case BibClassificationOrderedAscending: return BibClassificationOrderedAscending;
        case BibClassificationOrderedDescending: return BibClassificationOrderedDescending;
        case BibClassificationOrderedSpecifying: if (!specialize) { return BibClassificationOrderedAscending; }
        case BibClassificationOrderedSame: break;
    }

    size_t const remaining_count = MIN(leftn->remaing_segments_length, rightn->remaing_segments_length);
    for (size_t index = 0; index < remaining_count; index += 1) {
        result = string_specialized_compare(result, leftn->remaing_segments[index], rightn->remaing_segments[index]);
        if (result == string_specialized_ordered_ascending) { return BibClassificationOrderedAscending; }
        if (result == string_specialized_ordered_descending) { return BibClassificationOrderedDescending; }
        if (!specialize && result == string_specialized_ordered_specifying) { return BibClassificationOrderedAscending; }
    }
    if (leftn->remaing_segments_length < rightn->remaing_segments_length) {
        return (specialize) ? BibClassificationOrderedSpecifying : BibClassificationOrderedAscending;
    }
    if (leftn->remaing_segments_length > rightn->remaing_segments_length) {
        return BibClassificationOrderedDescending;
    }
    switch (result) {
        case BibClassificationOrderedSame: return BibClassificationOrderedSame;
        case BibClassificationOrderedSpecifying: return BibClassificationOrderedSpecifying;
        case BibClassificationOrderedAscending: return BibClassificationOrderedAscending;
        case BibClassificationOrderedDescending: return BibClassificationOrderedDescending;
    }
}

- (BOOL)includesCallNumber:(BibLCCallNumber *)callNumber
{
    switch ([self compareWithCallNumber:callNumber forSpecialization:YES]) {
        case BibClassificationOrderedSpecifying:
        case BibClassificationOrderedSame:
            return YES;

        default:
            return NO;
    }
}

- (BOOL)isEqualToCallNumber:(BibLCCallNumber *)other
{
    return self == other || [self compareWithCallNumber:other forSpecialization:NO] == BibClassificationOrderedSame;
}

- (BOOL)isEqual:(id)object
{
    return self == object
        || ([object isKindOfClass:[BibLCCallNumber self]] && [self isEqualToCallNumber:object]);
}

- (NSUInteger)hash
{
    return [[self stringValue] hash];
}

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;

}

+ (instancetype)new
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

@end
