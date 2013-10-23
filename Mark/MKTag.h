//
//  MKTag.h
//  Mark
//
//  Created by Vojtech Rinik on 23/10/13.
//  Copyright (c) 2013 Vojtech Rinik. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MKNote;

@interface MKTag : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *notes;
@end

@interface MKTag (CoreDataGeneratedAccessors)

- (void)addNotesObject:(MKNote *)value;
- (void)removeNotesObject:(MKNote *)value;
- (void)addNotes:(NSSet *)values;
- (void)removeNotes:(NSSet *)values;

@end
