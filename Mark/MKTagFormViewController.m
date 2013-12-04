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

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)createAction:(id)sender {
    NSLog(@"Creating tag with name: %@", self.name.stringValue);
    
    MKTag *tag = [MKTag createEntity];
    tag.name = self.name.stringValue;
    self.name.stringValue = @"";
    
    [self.context saveToPersistentStoreAndWait];
    
    [self.popover close];
}

@end
