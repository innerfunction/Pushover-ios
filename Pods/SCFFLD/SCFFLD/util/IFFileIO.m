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
//  Created by Julian Goacher on 03/07/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "IFFileIO.h"
#import "ZipArchive.h"
#import "IFLogger.h"

@interface IFZipArchiveDelegate : NSObject <ZipArchiveDelegate> {
    NSString *zipPath;
}

- (id)initWithZipPath:(NSString *)zipPath;

@end

@implementation IFFileIO

// Read a file and parse its contents as JSON.
+ (id)readJSONFromFileAtPath:(NSString *)path {
    id data = nil;
    NSData *json = [NSData dataWithContentsOfFile:path];
    if (json) {
        data = [NSJSONSerialization JSONObjectWithData:json
                                               options:0
                                                 error:nil];
    }
    return data;
}

// Write JSON to a file.
+ (BOOL)writeJSON:(id)data toFileAtPath:(NSString *)path {
    if ([NSJSONSerialization isValidJSONObject:data]) {
        NSData *json = [NSJSONSerialization dataWithJSONObject:data
                                                       options:0
                                                         error:nil];
        return [json writeToFile:path atomically:YES];
    }
    return NO; // Invalid JSON object.
}

// Unzip an archive to the specified location.
+ (BOOL)unzipFileAtPath:(NSString *)zipPath toPath:(NSString *)outPath {
    return [IFFileIO unzipFileAtPath:zipPath toPath:outPath overwrite:YES];
}

+ (BOOL)unzipFileAtPath:(NSString *)zipPath toPath:(NSString *)outPath overwrite:(BOOL)overwrite {
    BOOL ok = NO;
    ZipArchive *archive = [[ZipArchive alloc] init];
    archive.delegate = [[IFZipArchiveDelegate alloc] initWithZipPath:zipPath];
    if ([archive UnzipOpenFile:zipPath]) {
        if ([archive UnzipFileTo:outPath overWrite:overwrite]) {
            ok = YES;
        }
        else {
            [IFLogger withTag:@"IFFileIO" error:@"Failed to unzip %@ to %@", zipPath, outPath];
        }
        [archive UnzipCloseFile];
    }
    else {
        [IFLogger withTag:@"IFFileIO" error:@"Failed to open zip file %@", zipPath];
    }
    return ok;
}

@end

@implementation IFZipArchiveDelegate

- (id)initWithZipPath:(NSString *)_zipPath {
    self = [super init];
    if (self) {
        zipPath = _zipPath;
    }
    return self;
}

#pragma mark - ZipArchiveDelegate

- (void)ErrorMessage:(NSString *)msg {
    [IFLogger withTag:@"IFFileIO" error:@"Error processing zip file %@: %@", zipPath, msg];
}


@end
