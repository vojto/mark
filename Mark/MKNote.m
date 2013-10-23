//
//  MKNote.m
//  Mark
//
//  Created by Vojtech Rinik on 23/10/13.
//  Copyright (c) 2013 Vojtech Rinik. All rights reserved.
//

#import "MKNote.h"
#import "MKTag.h"


@implementation MKNote

@dynamic title;
@dynamic content;
@dynamic tags;

+ (NSString *)MR_entityName {
    return @"Note";
}

@end
