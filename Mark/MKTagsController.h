//
//  MKTagsController.h
//  Mark
//
//  Created by Vojtech Rinik on 23/10/13.
//  Copyright (c) 2013 Vojtech Rinik. All rights reserved.
//

#import "MKTagsArrayController.h"
#import "MKTag.h"

@interface MKTagsController : NSObject <NSTableViewDataSource, NSTableViewDelegate>

@property (strong) MKTag *selectedTag;

@property (assign) IBOutlet NSTableView *tagsTableView;
@property (assign) IBOutlet MKTagsArrayController *tagsArrayController;

@end
