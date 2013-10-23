//
//  MKTagsArrayController.h
//  Mark
//
//  Created by Vojtech Rinik on 23/10/13.
//  Copyright (c) 2013 Vojtech Rinik. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MKTagsArrayController : NSArrayController

@property (strong) NSDictionary *extraItem;

- (NSArray *)selectedObjectsExceptExtraItems;

@end
