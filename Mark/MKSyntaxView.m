//
//  MKSyntaxView.m
//  Mark
//
//  Created by Vojtech Rinik on 25/11/13.
//  Copyright (c) 2013 Vojtech Rinik. All rights reserved.
//

#import "MKSyntaxView.h"

@implementation MKSyntaxView

- (void)insertNewline:(id)sender {
    NSLog(@"Inserting newline...");
    
    // Copy whitespace from current line
    NSRange selection = [self selectedRange];
    NSRange lineRange;
    NSString *line = [self lineAtRange:selection lineRange:&lineRange];
    NSString *whitespace = @"";

    
    NSString *pattern = @"^\\s*[\\*\\-]?\\s*";
    NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:NULL];
    NSTextCheckingResult *result = [expression firstMatchInString:line options:0 range:NSMakeRange(0, line.length)];
    if (result) {
        NSRange range = [result rangeAtIndex:0];
        whitespace = [line substringWithRange:range];
    }
    
    NSString *newline = [NSString stringWithFormat:@"\n%@", whitespace];
    
    [self insertText:newline];
    


}

- (NSString *)lineAtRange:(NSRange)range lineRange:(NSRange *)lineRange {
    NSUInteger lineStart, lineEnd;
    NSString *line;
    [self.textStorage.string getLineStart:&lineStart end:NULL contentsEnd:&lineEnd forRange:range];
    lineRange->location = lineStart;
    lineRange->length = lineEnd - lineStart;
    line = [self.textStorage.string substringWithRange:*lineRange];
    return line;
}

@end
