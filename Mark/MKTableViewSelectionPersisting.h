//
//  MKTableViewSelectionPersisting.h
//  Mark
//
//  Created by Vojtech Rinik on 26/11/13.
//  Copyright (c) 2013 Vojtech Rinik. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MKTableViewSelectionPersisting : NSObject

@property (strong) NSIndexSet *selectionToLoad;
@property (assign) NSArrayController *arrayController;

- (id)initWithArrayController:(NSArrayController *)arrayController;

@end
