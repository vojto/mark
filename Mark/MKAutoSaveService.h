//
//  MKAutoSaveService.h
//  Mark
//
//  Created by Vojtech Rinik on 19/11/13.
//  Copyright (c) 2013 Vojtech Rinik. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MKAutoSaveService : NSObject

@property (strong) NSManagedObjectContext *context;

- (id)initWithContext:(NSManagedObjectContext *)context;

@end
