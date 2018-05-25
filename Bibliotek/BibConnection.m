//
//  BibConnection.m
//  Bibliotek
//
//  Created by Steve Brunwasser on 5/14/18.
//  Copyright © 2018 Steve Brunwasser. All rights reserved.
//

#import "BibConnection.h"
#import "BibConnection.Private.h"
#import "BibFetchRequest.h"
#import "BibFetchRequest.Private.h"
#import "BibOptions.h"
#import "BibOptions.Private.h"
#import "BibRecord.h"
#import "BibRecord.Private.h"
#import <yaz/zoom.h>

@implementation BibConnection {
    ZOOM_connection _connection;
    BibOptions *_Nullable _options;
}

@synthesize zoomConnection = _connection;

#pragma mark - Initializers

- (instancetype)initWithHost:(NSString *)host error:(NSError **)error {
    return [self initWithHost:host port:0 options:nil error:error];
}

- (instancetype)initWithHost:(NSString *)host port:(int)port error:(NSError **)error {
    return [self initWithHost:host port:port options:nil error:error];
}

- (instancetype)initWithHost:(NSString *)host options:(BibOptions *)options error:(inout NSError **)error {
    return [self initWithHost:host port:0 options:options error: error];
}

- (instancetype)initWithHost:(NSString *)host port:(int)port options:(BibOptions *)options error:(inout NSError **)error {
    if (self = [super init]) {
        _host = [host copy];
        _port = port;
        _options = [options copy];
        char const *const rawHost = [_host UTF8String];
        if (_options == nil) {
            _connection = ZOOM_connection_new(rawHost, port);;
        } else {
            _connection = ZOOM_connection_create(_options.zoomOptions);
            ZOOM_connection_connect(_connection, rawHost, port);
        }
        char const *name = NULL;
        char const *info = NULL;
        int code = ZOOM_connection_error(_connection, &name, &info);
        if (code != 0) {
            if (error != NULL) {
                NSDictionary *userInfo = @{ BibConnectionErrorName : @(name),
                                            BibConnectionErrorInfo : @(info) };
                *error = [NSError errorWithDomain:BibConnectionErrorDomain code:code userInfo:userInfo];
            }
            return nil;
        }
    }
    return self;
}

- (void)dealloc {
    ZOOM_connection_destroy(_connection);
}

#pragma mark - Search

- (NSArray<BibRecord *> *)fetchRecordsWithRequest:(BibFetchRequest *)request {
    ZOOM_resultset resultSet = ZOOM_connection_search(_connection, request.zoomQuery);
    NSMutableArray *array = [NSMutableArray new];
    size_t const count = ZOOM_resultset_size(resultSet);
    ZOOM_record *buffer = calloc(count, sizeof(ZOOM_record));
    ZOOM_resultset_records(resultSet, buffer, 0, count);
    for (int i = 0; i < count; i += 1) {
        ZOOM_record const record = buffer[i];
        if (record == nil) { break; }
        [array addObject:[[BibRecord alloc] initWithZoomRecord:record]];
    }
    free(buffer);
    ZOOM_resultset_destroy(resultSet);
    return [array copy];
}

@end

#pragma mark - Error Domain

NSErrorDomain const BibConnectionErrorDomain = @"BibConnectionErrorDomain";

NSErrorUserInfoKey const BibConnectionErrorName = @"BibConnectionErrorName";
NSErrorUserInfoKey const BibConnectionErrorInfo = @"BibConnectionErrorInfo";