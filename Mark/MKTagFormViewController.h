//
//  MKNewTagViewController.h
//  Mark
//
//  Created by Vojtech Rinik on 23/10/13.
//  Copyright (c) 2013 Vojtech Rinik. All rights reserved.
//

#import "MKTag.h"

@interface MKTagFormViewController : NSViewController

@property (assign) NSManagedObjectContext *context;

@property (assign) NSPopover *popover;

@property (strong) NSString *name;

@property (strong) MKTag *tag;

- (id)initWithDefaultNib;

- (void)reset;
- (IBAction)createAction:(id)sender;

@end
