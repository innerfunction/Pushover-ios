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
//  Created by Julian Goacher on 24/05/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFCommand.h"
#import "IFHTTPClient.h"
#import "IFCommandScheduler.h"

/**
 * A command to download a zip file from a remote location and unpack it to the device's filesystem.
 * NOTE: This is a fairly basic initial implementation of this command, needed to provide a bulk image
 * download function to the app (to downloaded initial image content after the app's installation).
 * The command doesn't block the command scheduler execution queue; rather the command returns control
 * to the scheduler as soon as the HTTP request has been submitted. The command schedules two follow
 * up commands (an unzip followed by an rm) once the request has completed.
 * The code needs to be reviewed WRT background execution. The command will loose state if the app is
 * terminated whilst the download is in progress - it may be possible instead for the command to
 * continue and resume despite this, but this needs further investigation.
 *
 * Arguments: <url> <path>
 * - url:       The URL to download.
 * - path:      A location to unzip the downloaded zip file to.
 */

@interface IFDownloadZipCommand : NSObject <IFCommand> {
    IFHTTPClient *_httpClient;
    __weak IFCommandScheduler *_commandScheduler;
    NSMutableSet *_promises;
}

- (id)initWithHTTPClient:(IFHTTPClient *)httpClient commandScheduler:(IFCommandScheduler *)commandScheduler;

@end
