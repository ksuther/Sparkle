//
//  main.m
//  SandboxService
//
//  Created by Yahoo (Fernando Pereira) on 5/12/14.
//
// based on
//  Created by Whitney Young on 3/19/12.
//  Copyright (c) 2012 FadingRed. All rights reserved.
//
// Additions by Yahoo:
// Copyright 2014 Yahoo Inc. Licensed under the project's open source license.
//
// 

#include <xpc/xpc.h>
#include <Foundation/Foundation.h>
#import "SUPlainInstallerInternals.h"
#import "SULog.h"
#import "SUCodeSigningVerifier.h"

static void peer_event_handler(xpc_connection_t peer, xpc_object_t event)
{
	xpc_type_t type = xpc_get_type(event);
	if (type == XPC_TYPE_ERROR) {
		if (event == XPC_ERROR_CONNECTION_INVALID) {
			// The client process on the other end of the connection has either
			// crashed or cancelled the connection. After receiving this error,
			// the connection is in an invalid state, and you do not need to
			// call xpc_connection_cancel(). Just tear down any associated state
			// here.
		} else if (event == XPC_ERROR_TERMINATION_IMMINENT) {
			// Handle per-connection termination cleanup.
		}
	} else {
		assert(type == XPC_TYPE_DICTIONARY);
		// Handle the message.
		const char *identifier = xpc_dictionary_get_string(event, "id");
		BOOL copyPath = strcmp(identifier, "copy_path") == 0;
		BOOL launchTask = strcmp(identifier, "launch_task") == 0;
		
		if( copyPath )
		{
			const char *src = xpc_dictionary_get_string(event, "source");
			const char *dst = xpc_dictionary_get_string(event, "destination");
			const char *tmp = xpc_dictionary_get_string(event, "tmp");
			
			NSFileManager *manager = [NSFileManager defaultManager];
			NSString *relaunchPathToCopy = src ? [manager stringWithFileSystemRepresentation:src length:strlen(src)] : nil;
			NSString *targetPath = dst ? [manager stringWithFileSystemRepresentation:dst length:strlen(dst)] : nil;
			NSString *temporaryName = tmp ? [NSString stringWithUTF8String:tmp] : nil;
			NSError *error = nil;
            
            
            // Validation
            if ( [SUCodeSigningVerifier codeSignatureIsValidAtPath:temporaryName error:&error] )
            {
                // Installation
                [SUPlainInstaller copyPathWithAuthentication:relaunchPathToCopy overPath:targetPath appendVersion:SPARKLE_APPEND_VERSION_NUMBER error:&error];
            }
            else
            {
                SULog(@"====> Code signature check on update failed: %@", [error description]);
            }
			
			// send response to indicate ok
			xpc_object_t reply = xpc_dictionary_create_reply(event);
			xpc_connection_send_message(peer, reply);
		}
		else if( launchTask )
		{
			const char *path = xpc_dictionary_get_string(event, "path");
			xpc_object_t array = xpc_dictionary_get_value(event, "arguments");
            
			NSFileManager *manager = [NSFileManager defaultManager];
			NSString *relaunchToolPath = path ? [manager stringWithFileSystemRepresentation:path length:strlen(path)] : nil;;
			NSMutableArray *arguments = [NSMutableArray array];
            
            [SUPlainInstaller releaseFromQuarantine:relaunchToolPath];
			
			for (size_t i = 0; i < xpc_array_get_count(array); i++) {
				NSString *string = [NSString stringWithUTF8String:xpc_array_get_string(array, i)];
				
				if (string) {
					[arguments addObject:string];
				}
			}
			
			[NSTask launchedTaskWithLaunchPath: relaunchToolPath arguments:arguments];
			
			// send response to indicate ok
			xpc_object_t reply = xpc_dictionary_create_reply(event);
			xpc_connection_send_message(peer, reply);
		}
	}
}

static void event_handler(xpc_connection_t peer)
{
	// By defaults, new connections will target the default dispatch
	// concurrent queue.
	xpc_connection_set_event_handler(peer, ^(xpc_object_t event) {
		peer_event_handler(peer, event);
	});
	
	// This will tell the connection to begin listening for events. If you
	// have some other initialization that must be done asynchronously, then
	// you can defer this call until after that initialization is done.
	xpc_connection_resume(peer);
}

__attribute((noreturn)) int main(int __unused argc, const char __unused *argv[])
{
	xpc_main(event_handler);
}
