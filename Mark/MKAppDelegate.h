//
//  MKAppDelegate.h
//  Mark
//
//  Created by Vojtech Rinik on 22/10/13.
//  Copyright (c) 2013 Vojtech Rinik. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MKAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (assign) NSManagedObjectContext *managedContext;

@end
