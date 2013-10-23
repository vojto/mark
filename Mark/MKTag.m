//
//  MKTag.m
//  Mark
//
//  Created by Vojtech Rinik on 23/10/13.
//  Copyright (c) 2013 Vojtech Rinik. All rights reserved.
//

#import "MKTag.h"
#import "MKNote.h"


@implementation MKTag

@dynamic name;
@dynamic notes;

+ (NSString *)MR_entityName {
    return @"Tag";
}

@end
