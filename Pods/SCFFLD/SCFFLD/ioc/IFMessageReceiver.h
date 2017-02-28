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
//  Created by Julian Goacher on 28/02/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFMessage.h"

/**
 * A protocol to be implemented by components capable of receiving messages
 * from other components.
 */
@protocol IFMessageReceiver <NSObject>

/**
 * Ask a target to receive a message.
 * @param message   The message to receive.
 * @param sender    The component which sent the message.
 * @return Returns _true_ if the message was processed by the target, _false_ otherwise.
 * A _true_ result will stop further processing of the message. A _false_ result may mean
 * that the message continues to be dispatched to other components (i.e. until some component
 * handles it).
 */
- (BOOL)receiveMessage:(IFMessage *)message sender:(id)sender;

@end
