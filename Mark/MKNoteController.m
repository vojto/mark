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
    NSString *expression, *bulletSymbols, *template, *replacement;
    NSTextCheckingResult *match;
    
    // First, check if line is already a TODO
    bulletSymbols = @"\\*|\\-";
    expression = [NSString stringWithFormat:@"^\\s*(%@)\\s*(\\[[ xo]\\])\\s*.*$", bulletSymbols];
    regex = [NSRegularExpression regularExpressionWithPattern:expression options:NSRegularExpressionCaseInsensitive error:nil];
    match = [regex firstMatchInString:line options:0 range:NSMakeRange(0, [line length])];
    
    if (match) {
        // Progress todo
        // Find out the original status
        NSRange range = [match rangeAtIndex:2];
        NSString *symbol = [line substringWithRange:range];
        NSDictionary *progressMap = @{@"[ ]": @"[x]", @"[x]": @"[ ]"};
        NSString *nextSymbol = progressMap[symbol];
        if (nextSymbol) {
            replacement = [line stringByReplacingOccurrencesOfString:symbol withString:nextSymbol];
            [self replaceInRange:lineRange with:replacement];
        }
    } else {
        // Turn line (with possible bullet) into a TODO
        expression = [NSString stringWithFormat:@"^(\\s*)(%@)?\\s*(.*)$", bulletSymbols];
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

        template = [NSString stringWithFormat:@"$1%@ [ ] $3", bulletChar];
        replacement = [regex stringByReplacingMatchesInString:line options:0 range:NSMakeRange(0, line.length) withTemplate:template];
        
        [self replaceInRange:lineRange with:replacement];
    }
}

#pragma mark - Indentation

- (void)indentRightAction:(id)sender {
    [self indentSelectionRight:YES];
}

- (void)indentLeftAction:(id)sender {
    [self indentSelectionRight:NO];
}

- (void)indentSelectionRight:(BOOL)right {
    NSRange selection, lineRange;
    NSString *block, *replacement;
    NSArray *lines, *updatedLines;
    
    NSString *indentString = @"  ";
    NSInteger indentSize = indentString.length;
    
    selection = [self.sourceView selectedRange];
    NSTextStorage *storage = self.sourceView.textStorage;
    
    block = [self lineAtRange:selection lineRange:&lineRange in:storage.string];
    lines = [block componentsSeparatedByString:@"\n"];
    updatedLines = [lines map:^id(NSString *line) {
        if (right) {
            return [NSString stringWithFormat:@"%@%@", indentString, line];
        } else {
            NSRange indentRange = NSMakeRange(0, indentSize);
            NSString *left = [line substringWithRange:indentRange];
            if ([left isEqualToString:indentString]) {
                return [line stringByReplacingCharactersInRange:indentRange withString:@""];
            } else {
                return line;
            }
        }
    }];
    replacement = [updatedLines componentsJoinedByString:@"\n"];
    
    NSRange newRange = [self replaceInRange:lineRange with:replacement];
    [self.sourceView setSelectedRange:newRange];
}

#pragma mark - Text tools

- (NSRange)replaceInRange:(NSRange)range with:(NSString *)replacement {
    NSTextStorage *storage = self.sourceView.textStorage;
    [storage replaceCharactersInRange:range withString:replacement];
    NSRange newRange = range;
    newRange.length = replacement.length;
    [self.sourceView highlightRange:newRange];
    return newRange;
}

- (NSString *)lineAtRange:(NSRange)range lineRange:(NSRange *)lineRange in:(NSString *)contents {
    NSUInteger lineStart, lineEnd;
    NSString *line;
    [contents getLineStart:&lineStart end:NULL contentsEnd:&lineEnd forRange:range];
    lineRange->location = lineStart;
    lineRange->length = lineEnd - lineStart;
    line = [contents substringWithRange:*lineRange];
    return line;
}

@end
