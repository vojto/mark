//
//  MKSyntaxView.h
//  Mark
//
//  Created by Vojtech Rinik on 25/11/13.
//  Copyright (c) 2013 Vojtech Rinik. All rights reserved.
//

#import "RKSyntaxView.h"

@interface MKSyntaxView : RKSyntaxView

- (NSString *)lineAtRange:(NSRange)range lineRange:(NSRange *)lineRange;

@end
