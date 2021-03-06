//
//  BibConnectionEndpoint.m
//  Bibliotek
//
//  Created by Steve Brunwasser on 8/7/18.
//  Copyright © 2018 Steve Brunwasser. All rights reserved.
//

#import "BibConnectionEndpoint.h"

NSString *const kDefaultHost = @"localhost";
NSInteger const kDefaultPort = 210;
NSString *const kDefaultDatabase = @"Default";

@implementation BibConnectionEndpoint {
@protected
    NSString *_host;
    NSInteger _port;
    NSString *_database;
    NSString *_name;
    NSString *_catalog;
}

@synthesize host = _host;
@synthesize port = _port;
@synthesize database = _database;
@synthesize name = _name;
@synthesize catalog = _catalog;

- (instancetype)init {
    return [self initWithHost:kDefaultHost port:kDefaultPort database:kDefaultDatabase];
}

- (instancetype)initWithHost:(NSString *)host {
    return [self initWithHost:host port:kDefaultPort database:kDefaultDatabase];
}

- (instancetype)initWithHost:(NSString *)host port:(NSInteger)port {
    return [self initWithHost:host port:port database:kDefaultDatabase];
}

- (instancetype)initWithHost:(NSString *)host database:(NSString *)database {
    return [self initWithHost:host port:kDefaultPort database:database];
}

- (instancetype)initWithHost:(NSString *)host port:(NSInteger)port database:(NSString *)database {
    if (self = [super init]) {
        _host = [host copy];
        _port = port;
        _database = [database copy];
    }
    return self;
}

- (instancetype)initWithEndpoint:(BibConnectionEndpoint *)endpoint {
    return [self initWithHost:[endpoint host] port:[endpoint port] database:[endpoint database]];
}

- (id)copyWithZone:(NSZone *)zone {
    return [[BibConnectionEndpoint allocWithZone:zone] initWithEndpoint:self];
}

- (id)mutableCopyWithZone:(NSZone *)zone {
    return [[BibMutableConnectionEndpoint allocWithZone:zone] initWithEndpoint:self];
}

+ (BOOL)supportsSecureCoding { return YES; }

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        _host = [aDecoder decodeObjectForKey:@"host"];
        _port = [aDecoder decodeIntegerForKey:@"port"];
        _database = [aDecoder decodeObjectForKey:@"database"];
        _name = [aDecoder decodeObjectForKey:@"name"];
        _catalog = [aDecoder decodeObjectForKey:@"catalog"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_host forKey:@"host"];
    [aCoder encodeInteger:_port forKey:@"port"];
    [aCoder encodeObject:_database forKey:@"database"];
    [aCoder encodeObject:_name forKey:@"name"];
    [aCoder encodeObject:_catalog forKey:@"catalog"];
}

- (NSString *)description {
    if (_name) {
        return [NSString stringWithFormat:@"%@ <%@:%ld/%@>", _name, _host, (long)_port, _database];
    }
    return [NSString stringWithFormat:@"%@:%ld/%@", _host, (long)_port, _database];
}

@end

@implementation BibMutableConnectionEndpoint

@dynamic host;
- (void)setHost:(NSString *)host {
    NSString *const key = NSStringFromSelector(@selector(host));
    [self willChangeValueForKey:key];
    _host = [host copy];
    [self didChangeValueForKey:key];
}

@dynamic port;
- (void)setPort:(NSInteger)port {
    NSString *const key = NSStringFromSelector(@selector(port));
    [self willChangeValueForKey:key];
    _port = port;
    [self didChangeValueForKey:key];
}

@dynamic database;
- (void)setDatabase:(NSString *)database {
    NSString *const key = NSStringFromSelector(@selector(database));
    [self willChangeValueForKey:key];
    _database = [database copy];
    [self didChangeValueForKey:key];
}

@dynamic name;
- (void)setName:(NSString *)name {
    NSString *const key = NSStringFromSelector(@selector(name));
    [self willChangeValueForKey:key];
    _name = [name copy];
    [self didChangeValueForKey:key];
}

@dynamic catalog;
- (void)setCatalog:(NSString *)catalog {
    NSString *const key = NSStringFromSelector(@selector(catalog));
    [self willChangeValueForKey:key];
    _catalog = [catalog copy];
    [self didChangeValueForKey:key];
}

@end
