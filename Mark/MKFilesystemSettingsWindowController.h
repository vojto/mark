//
//  MKFilesystemSettingsWindowController.h
//  Mark
//
//  Created by Vojtech Rinik on 11/21/13.
//  Copyright (c) 2013 Vojtech Rinik. All rights reserved.
//

#import "MKFileSystemSyncService.h"

@interface MKFilesystemSettingsWindowController : NSWindowController <NSOpenSavePanelDelegate>

- (IBAction)choosePathAction:(id)sender;

@end
