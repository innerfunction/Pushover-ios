//
//  Q.m
//  Q
//
//  Created by Julian Goacher on 29/09/2015.
//  Copyright (c) 2015 InnerFunction. All rights reserved.
//

#import "Q.h"

@interface QPromise()

- (id)initWithValue:(id)value;
- (id)initWithError:(id)error;

@end

@interface DeferredSet : NSObject {
    NSMutableArray *_values;
    NSInteger _count;
    NSInteger _resolvedCount;
}

@property (nonatomic, strong) QPromise *promise;

- (id)initWithCount:(NSInteger)count;
- (QThen)thenForIndex:(NSInteger)index;
- (void)reject:(id)error;

@end

@implementation QPromise

- (id)init {
    self = [super init];
    if (self) {
        _value = nil;
        _error = nil;
        _resolved = NO;
        _rejected = NO;
        _nextPromise = nil;
        _deferredValue = nil;
    }
    return self;
}

- (id)initWithValue:(id)value {
    self = [self init];
    if (self) {
        [self resolve:value];
    }
    return self;
}

- (id)initWithError:(id)error {
    self = [self init];
    if (self) {
        [self reject:error];
    }
    return self;
}

- (void)resolve:(id)value {
    if ([self isPending]) {
        @try {
            if ([value isKindOfClass:[QPromise class]]) {
                _deferredValue = (QPromise *)value;
                _deferredValue
                .then(^id(id __value) {
                    [self resolve:__value];
                    return nil;
                })
                .fail(^(id __error) {
                    [self reject:__error];
                });
            }
            else {
                _resolved = YES;
                _value = value;
                if (_nextPromise) {
                    @try {
                        id __value = _thenBlock(value);
                        [_nextPromise resolve:__value];
                    }
                    @catch (NSException *exception) {
                        [_nextPromise reject:exception];
                    }
                }
            }
        }
        @catch (NSException *exception) {
            [self reject:exception];
        }
    }
}

- (void)reject:(id)error {
    if ([self isPending]) {
        _rejected = YES;
        _error = error;
        if (_failBlock) {
            _failBlock(_error);
        }
        else if (_nextPromise) {
            [_nextPromise reject:_error];
        }
    }
}

- (QPromise *(^)(QThen))then {
    return ^QPromise *(QThen block) {
        return [self then:block];
    };
}

- (QPromise *)then:(QThen)thenBlock {
    _nextPromise = [[QPromise alloc] init];
    if ([self isResolved]) {
        // Current promise is already resolved, so immediately invoke the callback.
        @try {
            [_nextPromise resolve:thenBlock(_value)];
        }
        @catch (NSException *exception) {
            [_nextPromise reject:exception];
        }
    }
    else if ([self isRejected]) {
        // If the current promise is already rejected then pass the error onto the
        // next promise.
        [_nextPromise reject:_error];
    }
    else {
        // Promise is neither resolved nor rejected, copy the callback for later usage.
        _thenBlock = [thenBlock copy];
    }
    return _nextPromise;
}

- (QPromise *(^)(QFail))fail {
    return ^QPromise *(QFail block) {
        return [self fail:block];
    };
}

- (QPromise *)fail:(QFail)failBlock {
    if ([self isRejected]) {
        failBlock(_error);
    }
    else if ([self isPending]) {
        _failBlock = [failBlock copy];
    }
    return self;
}

- (id)value {
    return _value;
}

- (id)error {
    return _error;
}

- (BOOL)isResolved {
    return _resolved;
}

- (BOOL)isRejected {
    return _rejected;
}

- (BOOL)isPending {
    return !(_resolved || _rejected);
}

@end

@implementation DeferredSet

- (id)initWithCount:(NSInteger)count {
    self = [super init];
    if (self) {
        _promise = [[QPromise alloc] init];
        _values = [[NSMutableArray alloc] initWithCapacity:count];
        _count = count;
        _resolvedCount = 0;
    }
    return self;
}

- (QThen)thenForIndex:(NSInteger)index {
    return ^id(id value) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (_resolvedCount < _count) {
                _resolvedCount++;
                if (value == nil) {
                    [_values setObject:[NSNull null] atIndexedSubscript:index];
                }
                else {
                    [_values setObject:value atIndexedSubscript:index];
                }
                if (_resolvedCount == _count) {
                    [_promise resolve:_values];
                }
            }
        });
        return nil;
    };
}

- (void)reject:(id)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        [_promise reject:error];
    });
}

@end

@implementation Q

+ (QPromise *)fcall:(QFn)fn {
    return [[QPromise alloc] initWithValue:fn()];
}

+ (QPromise *)resolve:(id)value {
    return [[QPromise alloc] initWithValue:value];
}

+ (QPromise *)reject:(id)error {
    return [[QPromise alloc] initWithError:error];
}

+ (QPromise *)all:(NSArray *)promises {
    __block DeferredSet *deferreds = [[DeferredSet alloc] initWithCount:[promises count]];
    for (NSInteger i = 0; i < [promises count]; i++) {
        QPromise *promise = [promises objectAtIndex:i];
        promise
        .then([deferreds thenForIndex:i])
        .fail(^(id error) {
            [deferreds reject:error];
        });
    }
    return deferreds.promise;
}

+ (BOOL)isPromise:(id)obj {
    return [obj isKindOfClass:[QPromise class]];
}

@end
