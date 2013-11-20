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

#pragma mark - Creating tasks

- (void)createTaskAction:(id)sender {
    NSRange selection = [self.sourceView selectedRange];
    selection.length = 0;
    
    NSRange lineRange;
    NSTextStorage *storage = self.sourceView.textStorage;
    NSString *line = [self lineAtRange:selection lineRange:&lineRange in:storage.string];
    
    NSRegularExpression *regex;
    NSString *expression;
    NSTextCheckingResult *match;
    
    // First, check if line is already a TODO
    expression = @"^\\s*((\\*|\\-)\\s*\\[ \\])\\s*.*$";
    regex = [NSRegularExpression regularExpressionWithPattern:expression options:NSRegularExpressionCaseInsensitive error:nil];
    match = [regex firstMatchInString:line options:0 range:NSMakeRange(0, [line length])];
    
    if (match) {
        // TODO: Progress
    } else {
        // Turn line (with possible bullet) into a TODO
        expression = @"^(\\s*)(\\*|\\-)?\\s*(.*)$";
        regex = [NSRegularExpression regularExpressionWithPattern:expression options:NSRegularExpressionCaseInsensitive error:nil];
        // Decide which bullet character we should use
        NSString *bulletChar = @"*";
        match = [regex firstMatchInString:line options:0 range:NSMakeRange(0, line.length)];
        if (match) {
            NSRange matchRange = [match rangeAtIndex:2];
            if (matchRange.location != NSNotFound) {
                bulletChar = [line substringWithRange:matchRange];
            }
        }

        NSString *template = [NSString stringWithFormat:@"$1%@ [ ] $3", bulletChar];
        NSString *replacement = [regex stringByReplacingMatchesInString:line options:0 range:NSMakeRange(0, line.length) withTemplate:template];
        
        [storage replaceCharactersInRange:lineRange withString:replacement];
        NSRange highlightRange = lineRange;
        highlightRange.length = replacement.length;
        [self.sourceView highlightRange:highlightRange];
    }

}

- (NSString *)lineAtRange:(NSRange)range lineRange:(NSRange *)lineRange in:(NSString *)contents {
    // TODO: Use lineRangeForRange
    NSUInteger lineStart;
    NSUInteger lineEnd;
    NSString *line;
    [contents getLineStart:&lineStart end:NULL contentsEnd:&lineEnd forRange:range];
    lineRange->location = lineStart;
    lineRange->length = lineEnd - lineStart;
    line = [contents substringWithRange:*lineRange];
    return line;
}

@end
