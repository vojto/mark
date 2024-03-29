//
//  MKNote.h
//  Mark
//
//  Created by Vojtech Rinik on 23/10/13.
//  Copyright (c) 2013 Vojtech Rinik. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MKTag;

@interface MKNote : NSManagedObject

@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *content;
@property (nonatomic, retain) NSDate *updatedAt;
@property (nonatomic, retain) NSSet *tags;
@property (nonatomic, retain) NSString *fs_filename;
@property (nonatomic, retain) NSString *uuid;

- (NSString *)tagsString;
- (NSArray *)tagNames;
- (void)setTagNames:(NSArray *)tagNames;
- (void)ensureUUID;

@end

@interface MKNote (CoreDataGeneratedAccessors)

- (void)addTagsObject:(MKTag *)value;
- (void)removeTagsObject:(MKTag *)value;
- (void)addTags:(NSSet *)values;
- (void)removeTags:(NSSet *)values;

@end
