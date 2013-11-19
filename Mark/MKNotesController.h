//
//  MKNotesController.h
//  Mark
//
//  Created by Vojtech Rinik on 23/10/13.
//  Copyright (c) 2013 Vojtech Rinik. All rights reserved.
//

#import "MKTag.h"

@interface MKNotesController : NSObject

@property (assign) BOOL isSetup;
@property (assign) IBOutlet NSTableView *notesTable;
@property (assign) IBOutlet NSArrayController *notesArrayController;

- (void)filterNotesByTag:(MKTag *)tag;

- (IBAction)newNoteAction:(id)sender;

@end
