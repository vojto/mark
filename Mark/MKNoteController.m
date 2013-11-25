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
    
    [self.sourceView setAutomaticDashSubstitutionEnabled:NO];

}

#pragma mark - Creating tasks

- (void)createTaskAction:(id)sender {
    [self progressTaskUsingMap:@{@"[ ]": @"[x]", @"[x]": @"[ ]", @"[o]": @"[x]"}];
}

- (void)zoneInTaskAction:(id)sender {
    [self progressTaskUsingMap:@{@"[ ]": @"[o]", @"[x]": @"[o]", @"[o]": @"[ ]"}];
}

- (void)progressTaskUsingMap:(NSDictionary *)progressMap {
    NSRange selection = [self.sourceView selectedRange];
    selection.length = 0;
    
    NSRange lineRange;
    NSString *line = [self.sourceView lineAtRange:selection lineRange:&lineRange];
    
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
    
    NSString *indentString = @"\t";
    NSInteger indentSize = indentString.length;
    
    selection = [self.sourceView selectedRange];
    
    block = [self.sourceView lineAtRange:selection lineRange:&lineRange];

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
    if (updatedLines.count > 1) {
        [self.sourceView setSelectedRange:newRange];
    }
}

#pragma mark - Text tools

- (NSRange)replaceInRange:(NSRange)range with:(NSString *)replacement {
    NSTextStorage *storage = self.sourceView.textStorage;
    
    if ([self.sourceView shouldChangeTextInRange:range replacementString:replacement]) {
        [storage beginEditing];
        [storage replaceCharactersInRange:range withString:replacement];
        [storage endEditing];
        [self.sourceView didChangeText];
    }
    
    
    NSRange newRange = range;
    newRange.length = replacement.length;
    
    
    [self.sourceView highlightRange:newRange];
    return newRange;
}

@end
