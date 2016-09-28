//
//  SUXPC.m
//  Sparkle
//
//  Created by Whitney Young on 3/19/12.
//  Copyright (c) 2012 FadingRed. All rights reserved.
//
// Additions by Yahoo:
// Copyright 2014 Yahoo Inc. Licensed under the project's open source license.
//

#import <xpc/xpc.h>
#import "SUXPC.h"

@implementation SUXPC

+ (void)launchTaskWithLaunchPath:(NSString *)path arguments:(NSArray *)arguments {
	xpc_connection_t connection = xpc_connection_create(SPARKLE_SANDBOX_SERVICE_NAME, NULL);
	xpc_connection_set_event_handler(connection, ^(xpc_object_t event) {
		xpc_dictionary_apply(event, ^bool(const char *key, xpc_object_t value) {
			const char *xpcString = xpc_string_get_string_ptr(value);

			if (xpcString) {
				NSLog(@"XPC %@: %@", [NSString stringWithUTF8String:key], [NSString stringWithUTF8String:xpcString]);
			}

			return true;
		});
	});
	xpc_connection_resume(connection);
	
	xpc_object_t message = xpc_dictionary_create(NULL, NULL, 0);
	xpc_dictionary_set_string(message, "id", "launch_task");
	
	if( path )
		xpc_dictionary_set_string(message, "path", [path fileSystemRepresentation]);
	
	xpc_object_t array = xpc_array_create(NULL, 0);
	for (id argument in arguments) {
		const char *argumentString = [argument UTF8String];

		if (argumentString) {
			xpc_array_append_value(array, xpc_string_create(argumentString));
		}
	}
	
	xpc_dictionary_set_value(message, "arguments", array);
	
	xpc_object_t response = xpc_connection_send_message_with_reply_sync(connection, message);
	xpc_type_t type = xpc_get_type(response);
	BOOL success = (type == XPC_TYPE_DICTIONARY);
	
	if (!success) {
		NSLog(@"XPC launch error");
	}
}

@end
