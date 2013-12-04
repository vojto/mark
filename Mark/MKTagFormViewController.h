//
//  MKNewTagViewController.h
//  Mark
//
//  Created by Vojtech Rinik on 23/10/13.
//  Copyright (c) 2013 Vojtech Rinik. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MKTagFormViewController : NSViewController

@property (assign) NSManagedObjectContext *context;

@property (assign) NSPopover *popover;

@property (assign) IBOutlet NSTextField *name;

- (IBAction)createAction:(id)sender;

@end
