//
//  MKTagsController.h
//  Mark
//
//  Created by Vojtech Rinik on 23/10/13.
//  Copyright (c) 2013 Vojtech Rinik. All rights reserved.
//

#import "MKTagsArrayController.h"

@interface MKTagsController : NSObject <NSTableViewDataSource, NSTableViewDelegate>

@property (assign) IBOutlet NSTableView *tagsTableView;
@property (assign) IBOutlet MKTagsArrayController *tagsArrayController;

@end
