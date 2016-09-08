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
//  Created by Julian Goacher on 09/12/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFCommand.h"

typedef QPromise *(^IFCommandProtocolBlock) (NSArray *args);

/**
 * A command protocol.
 * A command implementation that supports multiple different named commands, useful for
 * defining protocols composed of a number of related commands.
 */
@interface IFCommandProtocol : NSObject <IFCommand> {
    NSDictionary *_commands;
    NSString *_commandPrefix;
}

/** Return a list of command names supported by this protocol. */
- (NSArray *)supportedCommands;
/** Register a protocol command. */
- (void)addCommand:(NSString *)name withBlock:(IFCommandProtocolBlock)block;
/** Qualify a protocol command name with the current command prefix. */
- (NSString *)qualifiedCommandName:(NSString *)name;
/**
 * Parse a command argument list.
 * Transforms an array of command arguments into a dictionary of name/value pairs.
 * Arguments can be defined by position, or by using named switches (e.g. -name value).
 * The names of positional arguments are specified using the argOrder list.
 */
- (NSDictionary *)parseArgArray:(NSArray *)args argOrder:(NSArray *)argOrder defaults:(NSDictionary *)defaults;

@end
