//
//  MKNoteController.m
//  Mark
//
//  Created by Vojtech Rinik on 19/11/13.
//  Copyright (c) 2013 Vojtech Rinik. All rights reserved.
//

#import "MKNoteController.h"


@implementation MKNoteController

- (void)awakeFromNib {
    [APP_DELEGATE on:@"newNote" block:^(id data) {
        [self.titleField becomeFirstResponder];
    }];
    
    [self.sourceView loadScheme:@"PageScheme"];
    [self.sourceView loadSyntax:@"PageSyntax"];

    [self.sourceView highlight];

}

@end
