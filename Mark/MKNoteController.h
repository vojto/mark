//
//  MKNoteController.h
//  Mark
//
//  Created by Vojtech Rinik on 19/11/13.
//  Copyright (c) 2013 Vojtech Rinik. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RKSyntaxView/RKSyntaxView.h>

@interface MKNoteController : NSObject

@property (weak) IBOutlet NSTextField *titleField;
@property (weak) IBOutlet NSScrollView *contentField;

@property (unsafe_unretained) IBOutlet RKSyntaxView *sourceView;

- (IBAction)createTaskAction:(id)sender;
- (IBAction)indentRightAction:(id)sender;
- (IBAction)indentLeftAction:(id)sender;

@end
