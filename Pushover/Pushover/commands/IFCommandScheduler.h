// Copyright 2016 InnerFunction Ltd.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
//  Created by Julian Goacher on 07/12/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFDB.h"
#import "IFService.h"

@interface IFCommandScheduler : NSObject <IFService> {
    // The queue database.
    IFDB *_db;
    // A list of commands currently being executed.
    NSArray *_execQueue;
    // Pointer into the exec queue to the command currently being executed.
    NSInteger _execIdx;
    // Current batch number.
    NSInteger _currentBatch;
}

/**
 * The name of the command queue database.
 */
@property (nonatomic, strong) NSString *queueDBName;
/**
 * A map of command instances, keyed by name.
 * Commands which are command protocol instances (i.e. IFCommandProtocol subclasses) have each
 * of their protocol commands mapped into the command namespace with the protocol command name
 * as a prefix, so e.g. { name => protocol } --> name.command1, name.command2 etc.
 */
@property (nonatomic, strong) NSDictionary *commands;
/**
 * Whether to delete queue database records after processing.
 * Defaults to YES. When NO, the 'status' field is used to track pending vs. executed records;
 * this mode is primarily useful for debugging.
 */
@property (nonatomic, assign) BOOL deleteExecutedQueueRecords;

/** Execute all commands currently on the queue. */
- (void)executeQueue;
/** Append a new command to the queue. */
- (void)appendCommand:(NSString *)name withArgs:(NSArray *)args;
/** Append a new command to the queue. */
- (void)appendCommand:(NSString *)command, ...;
/** Purge the current execution queue. */
- (void)purgeQueue;
/** Purge the current command batch. */
- (void)purgeCurrentBatch;

/** Get the command execution queue. */
+ (dispatch_queue_t)getCommandExecutionQueue;

@end
