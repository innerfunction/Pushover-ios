//
//  Q.h
//  Q
//
//  Created by Julian Goacher on 29/09/2015.
//  Copyright (c) 2015 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>

/** Block signature for function calls (see Q.fcall). */
typedef id (^QFn) ();
/** Block signature for then continuations. */
typedef id (^QThen) (id);
/** Block signature for fail continuations. */
typedef void (^QFail) (id);

/** A deferred promise. */
@interface QPromise : NSObject {
    id _value;                  // The resolved value.
    id _error;                  // The rejected error.
    BOOL _resolved;             // Flag indicating whether the promise is resolved.
    BOOL _rejected;             // Flag indicating whether the promise is rejected.
    QThen _thenBlock;           // Block to be called if the promise is resolved.
    QFail _failBlock;           // Block to be called if the promise is rejected.
    QPromise *_nextPromise;     // Chained promise, returned by this promise's then property.
    QPromise *_deferredValue;   // A resolved value which has been passed as a promise.
}

// Properties allowing 'then' and 'fail' to be accessed using dot-notation, which works much
// better when chaining than square-bracket notation (which can also be used, but which tends
// to replicate the pyramid of doom when long chains are involved).
// This property style found and copied from https://github.com/robb/Underscore.m/tree/development/Underscore

@property (readonly) QPromise *(^then)(QThen thenBlock);
@property (readonly) QPromise *(^fail)(QFail failBlock);

- (void)resolve:(id)value;
- (void)reject:(id)error;
- (QPromise *)then:(QThen)thenBlock;
- (QPromise *)fail:(QFail)failBlock;

/** The value this promise was resolved with. */
- (id)value;
/** The error this promise was rejected with. */
- (id)error;
/** Test whether this promise is resolved, i.e. has a value result. */
- (BOOL)isResolved;
/** Test whether this promise is rejected, i.e. has an error. */
- (BOOL)isRejected;
/** Test whether this promise is still pending, i.e. has been neither resolved or rejected. */
- (BOOL)isPending;

@end

@interface Q : NSObject

/**
 * Return a promise resolving to the result of invoking the block argument.
 */
+ (QPromise *)fcall:(QFn)fn;
/**
 * Return a promise resolving to the value argument.
 */
+ (QPromise *)resolve:(id)value;
/**
 * Return a rejected promise with the specified error.
 */
+ (QPromise *)reject:(id)error;
/**
 * Return a promise which is resolved once all promises in the array argument have been resolved.
 * The resulting promise will resolve to an array containing the value result of each promise in the
 * array argument.
 * If any promise in the argument is rejected then the result is rejected with the first generated error.
 */
+ (QPromise *)all:(NSArray *)promises;
/**
 * Test whether an argument is a promise.
 */
+ (BOOL)isPromise:(id)obj;

@end
