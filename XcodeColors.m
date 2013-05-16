//
//  XcodeColors.m
//  XcodeColors
//
//  Created by Uncle MiF on 9/13/10.
//  Copyright 2010 Deep IT. All rights reserved.
//

#import "XcodeColors.h"
#import <objc/runtime.h>

#define XCODE_COLORS "XcodeColors"

// How to apply color formatting to your log statements:
// 
// To set the foreground color:
// Insert the ESCAPE_SEQ into your string, followed by "fg124,12,255;" where r=124, g=12, b=255.
// 
// To set the background color:
// Insert the ESCAPE_SEQ into your string, followed by "bg12,24,36;" where r=12, g=24, b=36.
// 
// To reset the foreground color (to default value):
// Insert the ESCAPE_SEQ into your string, followed by "fg;"
// 
// To reset the background color (to default value):
// Insert the ESCAPE_SEQ into your string, followed by "bg;"
// 
// To reset the foreground and background color (to default values) in one operation:
// Insert the ESCAPE_SEQ into your string, followed by ";"
// 
// 
// Feel free to copy the define statements below into your code.
// <COPY ME>

#define XCODE_COLORS_ESCAPE @"\033["

#define XCODE_COLORS_RESET_FG  XCODE_COLORS_ESCAPE @"fg;" // Clear any foreground color
#define XCODE_COLORS_RESET_BG  XCODE_COLORS_ESCAPE @"bg;" // Clear any background color
#define XCODE_COLORS_RESET     XCODE_COLORS_ESCAPE @";"   // Clear any foreground or background color

// </COPY ME>

static IMP IMP_NSTextStorage_fixAttributesInRange = nil;

@implementation XcodeColors_NSTextStorage

void ApplyANSIColors(NSTextStorage *textStorage, NSRange textStorageRange, NSString *escapeSeq)
{
	NSString *affectedString = [[textStorage string] substringWithRange:textStorageRange];

    NSDictionary *errorAttributes = @{NSForegroundColorAttributeName:[NSColor colorWithCalibratedRed:0.717 green:0.000 blue:0.028 alpha:1.000]};
    NSDictionary *greenAttributes = @{NSForegroundColorAttributeName:[NSColor colorWithCalibratedRed:0.186 green:0.582 blue:0.017 alpha:1.000]};
    
    // Apply red color to strings looking like ***this***.
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\*\\*\\*.*?\\*\\*\\*"
                                                                           options:(NSRegularExpressionCaseInsensitive |
                                                                                    NSRegularExpressionDotMatchesLineSeparators)
                                                                             error:&error];
    NSArray *matches = [regex matchesInString:affectedString options:0 range:NSMakeRange(0, affectedString.length)];
    for (NSTextCheckingResult *match in matches) {
        NSRange matchRange = match.range;
        [textStorage addAttributes:errorAttributes range:matchRange];
    }
    
    // Apply green color to strings looking like ---this---
    error = NULL;
    regex = [NSRegularExpression regularExpressionWithPattern:@"---.*?---"
                                                      options:(NSRegularExpressionCaseInsensitive |
                                                               NSRegularExpressionDotMatchesLineSeparators)
                                                        error:&error];
    matches = [regex matchesInString:affectedString options:0 range:NSMakeRange(0, affectedString.length)];
    for (NSTextCheckingResult *match in matches) {
        NSRange matchRange = match.range;
        [textStorage addAttributes:greenAttributes range:matchRange];
    }
}

- (void)fixAttributesInRange:(NSRange)aRange
{
	// This method "overrides" the method within NSTextStorage.
	
	// First we invoke the actual NSTextStorage method.
	// This allows it to do any normal processing.
	
	IMP_NSTextStorage_fixAttributesInRange(self, _cmd, aRange);
	
	// Then we scan for our special escape sequences, and apply desired color attributes.
	
	char *xcode_colors = getenv(XCODE_COLORS);
	if (xcode_colors && (strcmp(xcode_colors, "YES") == 0))
	{
		ApplyANSIColors(self, aRange, XCODE_COLORS_ESCAPE);
	}
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation XcodeColors

IMP ReplaceInstanceMethod(Class sourceClass, SEL sourceSel, Class destinationClass, SEL destinationSel)
{
	if (!sourceSel || !sourceClass || !destinationClass)
	{
		NSLog(@"XcodeColors: Missing parameter to ReplaceInstanceMethod");
		return nil;
	}
	
	if (!destinationSel)
		destinationSel = sourceSel;
	
	Method sourceMethod = class_getInstanceMethod(sourceClass, sourceSel);
	if (!sourceMethod)
	{
		NSLog(@"XcodeColors: Unable to get sourceMethod");
		return nil;
	}
	
	IMP prevImplementation = method_getImplementation(sourceMethod);
	
	Method destinationMethod = class_getInstanceMethod(destinationClass, destinationSel);
	if (!destinationMethod)
	{
		NSLog(@"XcodeColors: Unable to get destinationMethod");
		return nil;
	}
	
	IMP newImplementation = method_getImplementation(destinationMethod);
	if (!newImplementation)
	{
		NSLog(@"XcodeColors: Unable to get newImplementation");
		return nil;
	}
	
	method_setImplementation(sourceMethod, newImplementation);
	
	return prevImplementation;
}

+ (void)load
{
	NSLog(@"XcodeColors: %@ (v10.1)", NSStringFromSelector(_cmd));
	
	char *xcode_colors = getenv(XCODE_COLORS);
	if (xcode_colors && (strcmp(xcode_colors, "YES") != 0))
		return;
	
	IMP_NSTextStorage_fixAttributesInRange =
	    ReplaceInstanceMethod([NSTextStorage class], @selector(fixAttributesInRange:),
							  [XcodeColors_NSTextStorage class], @selector(fixAttributesInRange:));
	
	setenv(XCODE_COLORS, "YES", 0);
}

+ (void)pluginDidLoad:(id)xcodeDirectCompatibility
{
	NSLog(@"XcodeColors: %@", NSStringFromSelector(_cmd));
}

- (void)registerLaunchSystemDescriptions
{
	NSLog(@"XcodeColors: %@", NSStringFromSelector(_cmd));
}

@end
