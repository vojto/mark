//
//  MKNewTagViewController.m
//  Mark
//
//  Created by Vojtech Rinik on 23/10/13.
//  Copyright (c) 2013 Vojtech Rinik. All rights reserved.
//

#import "MKTagFormViewController.h"
#import "MKTag.h"

@interface MKTagFormViewController ()

@end

@implementation MKTagFormViewController

@synthesize tag;

- (id)initWithDefaultNib {
    if ((self = [self initWithNibName:@"MKTagFormViewController" bundle:nil])) {
        
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)reset {
    self.tag = nil;
}

- (void)createAction:(id)sender {
    if (!self.tag) {
        self.tag = [MKTag createEntity];
    }

    self.tag.name = self.name;
    [self.context saveToPersistentStoreAndWait];
    
    [self reset];
    [self.popover close];
}

- (void)setTag:(MKTag *)aTag {
    tag = aTag;
    self.name = tag.name;
}

- (MKTag *)tag {
    return tag;
}

@end
