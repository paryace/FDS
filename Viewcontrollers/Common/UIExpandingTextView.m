/*
 *  UIExpandingTextView.m
 *  
 *  Created by Brandon Hamilton on 2011/05/03.
 *  Copyright 2011 Brandon Hamilton.
 *  
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *  
 *  The above copyright notice and this permission notice shall be included in
 *  all copies or substantial portions of the Software.
 *  
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 *  THE SOFTWARE.
 */

/* 
 *  This class is based on growingTextView by Hans Pickaers 
 *  http://www.hanspinckaers.com/multi-line-uitextview-similar-to-sms
 */

#import "UIExpandingTextView.h"
#import <QuartzCore/QuartzCore.h>
#define kTextInsetX 4
#define kTextInsetBottom 0

@implementation UIExpandingTextView

@synthesize internalTextView;
@synthesize delegate;

@synthesize text;
@synthesize font;
@synthesize textColor;
@synthesize textAlignment; 
@synthesize selectedRange;
@synthesize editable;
@synthesize dataDetectorTypes; 
@synthesize animateHeightChange;
@synthesize returnKeyType;
@synthesize textViewBackgroundImage;
@synthesize placeholder;
#define RGBACOLOR(r,g,b,a) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:(a)]
- (void)setPlaceholder:(NSString *)placeholders
{
    placeholder = placeholders;
    placeholderLabel.text = placeholders;
}

- (int)minimumNumberOfLines
{
    return minimumNumberOfLines;
}

- (int)maximumNumberOfLines
{
    return maximumNumberOfLines;
}

- (id)initWithFrame:(CGRect)frame 
{
    if ((self = [super initWithFrame:frame])) 
    {
        forceSizeUpdate = NO;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		CGRect backgroundFrame = frame;
        backgroundFrame.origin.y = 0;
		backgroundFrame.origin.x = 0;
        
        CGRect textViewFrame = CGRectInset(backgroundFrame, kTextInsetX, kTextInsetX);

        /* Internal Text View component */
		internalTextView = [[UIExpandingTextViewInternal alloc] initWithFrame:textViewFrame];
		internalTextView.delegate        = self;
		internalTextView.font            = [UIFont systemFontOfSize:17.0];
		internalTextView.contentInset    = UIEdgeInsetsMake(-4,0,-4,0);	
        internalTextView.text            = @"-";
		internalTextView.scrollEnabled   = NO;
        internalTextView.opaque          = NO;
        internalTextView.backgroundColor = [UIColor clearColor];
        internalTextView.showsHorizontalScrollIndicator = NO;
        [internalTextView sizeToFit];
        
//        internalTextView.layer.borderColor = RGBACOLOR(78, 51, 34, 0.8)  .CGColor;
//        internalTextView.layer.borderWidth =1.0;
        internalTextView.layer.cornerRadius =5.0;
        
        internalTextView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        
        /* set placeholder */
        placeholderLabel = [[UILabel alloc]initWithFrame:CGRectMake(8,1,self.bounds.size.width - 16,self.bounds.size.height)];
        placeholderLabel.text = placeholder;
        placeholderLabel.font = internalTextView.font;
        placeholderLabel.backgroundColor = [UIColor clearColor];
        placeholderLabel.textColor = [UIColor grayColor];
        [internalTextView addSubview:placeholderLabel];
        
        /* Custom Background image */
        textViewBackgroundImage = [[UIImageView alloc] initWithFrame:backgroundFrame];
        textViewBackgroundImage.image          = [UIImage imageNamed:@"InputBack"];
        textViewBackgroundImage.contentMode    = UIViewContentModeScaleToFill;
//        UIEdgeInsets insets = UIEdgeInsetsMake(0.5, 0.5, 0, 0);
//        [textViewBackgroundImage setImage:[[UIImage imageNamed:@"keyBoardBack"] resizableImageWithCapInsets:insets]];
//        textViewBackgroundImage.contentStretch = CGRectMake(0.5, 0.5, 0, 0);
        [self addSubview:textViewBackgroundImage];
        [self addSubview:internalTextView];

        /* Calculate the text view height */
		UIView *internal = (UIView*)[[internalTextView subviews] objectAtIndex:0];
		minimumHeight = internal.frame.size.height;
		[self setMinimumNumberOfLines:1];
		animateHeightChange = YES;
		internalTextView.text = @"";
//		[self setMaximumNumberOfLines:13];
        [self sizeToFit];
    }
    return self;
}

-(void)sizeToFit
{
    CGRect r = self.frame;
    if ([self.text length] > 0) 
    {
        /* No need to resize is text is not empty */
        return;
    }
    r.size.height = minimumHeight + kTextInsetBottom;
    self.frame = r;
}

-(void)setFrame:(CGRect)aframe
{
    CGRect backgroundFrame   = aframe;
    backgroundFrame.origin.y = 0;
    backgroundFrame.origin.x = 0;
    CGRect textViewFrame = CGRectInset(backgroundFrame, kTextInsetX, kTextInsetX);
	internalTextView.frame   = textViewFrame;
//    backgroundFrame.size.height  -= 8;
    textViewBackgroundImage.frame = backgroundFrame;
    forceSizeUpdate = YES;
	[super setFrame:aframe];
}

-(void)clearText
{
    self.text = @"";
    [self textViewDidChange:self.internalTextView];
}
     
-(void)setMaximumNumberOfLines:(int)n
{
    BOOL didChange            = NO;
    NSString *saveText        = internalTextView.text;
    NSString *newText         = @"-";
    internalTextView.hidden   = YES;
    internalTextView.delegate = nil;
    for (int i = 2; i < n; ++i)
    {
        newText = [newText stringByAppendingString:@"\n|W|"];
    }
    internalTextView.text     = newText;
    /*fix for iOS7 */
    if(floor(NSFoundationVersionNumber)>NSFoundationVersionNumber_iOS_6_1) {
        didChange = (maximumHeight != [self measureHeightOfUITextView:self.internalTextView]);
        maximumHeight             = [self measureHeightOfUITextView:self.internalTextView];
    }
    else {
        didChange = (maximumHeight != self.internalTextView.contentSize.height);
        maximumHeight             = self.internalTextView.contentSize.height;
    }
//    if(floor(NSFoundationVersionNumber)>NSFoundationVersionNumber_iOS_6_1) {
//        maximumHeight             = [self measureHeightOfUITextView:self.internalTextView];
//    } else {
//        maximumHeight             = self.internalTextView.contentSize.height;
//    }
    maximumNumberOfLines      = n;
    internalTextView.text     = saveText;
    internalTextView.hidden   = NO;
    internalTextView.delegate = self;
    if (didChange) {
        forceSizeUpdate = YES;
        [self textViewDidChange:self.internalTextView];
    }
}

-(void)setMinimumNumberOfLines:(int)m
{
    NSString *saveText        = internalTextView.text;
    NSString *newText         = @"-";
    internalTextView.hidden   = YES;
    internalTextView.delegate = nil;
    for (int i = 2; i < m; ++i)
    {
        newText = [newText stringByAppendingString:@"\n|W|"];
    }
    internalTextView.text     = newText;
//    / below line is fix */
    if(floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) {
        minimumHeight = [self measureHeightOfUITextView:self.internalTextView];
    }
    else {
        minimumHeight = internalTextView.contentSize.height;
    }
    
    internalTextView.text     = saveText;
    internalTextView.hidden   = NO;
    internalTextView.delegate = self;
    [self sizeToFit];
    minimumNumberOfLines = m;
}


- (void)textViewDidChange:(UITextView *)textView
{
    NSLog(@"走textViewDidChange%@",textView);
    if(textView.text.length == 0)
        placeholderLabel.alpha = 1;
    else
        placeholderLabel.alpha = 0;
    
	NSInteger newHeight ;
    if(floor(NSFoundationVersionNumber)>NSFoundationVersionNumber_iOS_6_1) {
        newHeight = [self measureHeightOfUITextView:self.internalTextView];
    }else {
        newHeight = self.internalTextView.contentSize.height;
    }

	if(newHeight < minimumHeight || !internalTextView.hasText)
    {
        newHeight = minimumHeight;
    }
    
	if (internalTextView.frame.size.height != newHeight || forceSizeUpdate)
	{
        forceSizeUpdate = NO;
        if (newHeight > maximumHeight && internalTextView.frame.size.height <= maximumHeight)
        {
            newHeight = maximumHeight;
        }
		if (newHeight <= maximumHeight)
		{
			if(animateHeightChange)
            {
				[UIView beginAnimations:@"" context:nil];
				[UIView setAnimationDelegate:self];
				[UIView setAnimationDidStopSelector:@selector(growDidStop)];
				[UIView setAnimationBeginsFromCurrentState:YES];
			}
			
			if ([delegate respondsToSelector:@selector(expandingTextView:willChangeHeight:)]) 
            {
				[delegate expandingTextView:self willChangeHeight:(newHeight+ kTextInsetBottom)];
			}
			
			/* Resize the frame */
			CGRect r = self.frame;
			r.size.height = newHeight + kTextInsetBottom;
			self.frame = r;
			r.origin.y = 0;
			r.origin.x = 0;
            internalTextView.frame = CGRectInset(r, kTextInsetX, kTextInsetX);
//            r.size.height -= 8;
            textViewBackgroundImage.frame = r;
			if(animateHeightChange)
            {
				[UIView commitAnimations];
			}
            else if ([delegate respondsToSelector:@selector(expandingTextView:didChangeHeight:)]) 
            {
                [delegate expandingTextView:self didChangeHeight:(newHeight+ kTextInsetBottom)];
            }
		}
		
		if (newHeight >= maximumHeight)
		{
            /* Enable vertical scrolling */
			if(!internalTextView.scrollEnabled)
            {
				internalTextView.scrollEnabled = YES;
				[internalTextView flashScrollIndicators];
			}
		} 
        else 
        {
            /* Disable vertical scrolling */
			internalTextView.scrollEnabled = NO;
		}
	}
	if ([delegate respondsToSelector:@selector(expandingTextViewDidChange:)])
    {
		[delegate expandingTextViewDidChange:self];
	}
}

-(void)growDidStop
{
	if ([delegate respondsToSelector:@selector(expandingTextView:didChangeHeight:)]) 
    {
		[delegate expandingTextView:self didChangeHeight:self.frame.size.height];
	}
}
-(BOOL)becomeFirstResponder{
    [super becomeFirstResponder];
    return [internalTextView becomeFirstResponder];
}
-(BOOL)resignFirstResponder
{
	[super resignFirstResponder];
	return [internalTextView resignFirstResponder];
}

- (void)dealloc 
{
	[internalTextView release];
    [textViewBackgroundImage release];
    [placeholderLabel release];
    [super dealloc];
}

#pragma mark UITextView properties

-(void)setText:(NSString *)atext
{
	internalTextView.text = atext;
    [self performSelector:@selector(textViewDidChange:) withObject:internalTextView];
}

-(NSString*)text
{
	return internalTextView.text;
}

-(void)setFont:(UIFont *)afont
{
	internalTextView.font= afont;
	[self setMaximumNumberOfLines:maximumNumberOfLines];
	[self setMinimumNumberOfLines:minimumNumberOfLines];
}

-(UIFont *)font
{
	return internalTextView.font;
}	

-(void)setTextColor:(UIColor *)color
{
	internalTextView.textColor = color;
}

-(UIColor*)textColor
{
	return internalTextView.textColor;
}

-(void)setTextAlignment:(NSTextAlignment)aligment
{
	internalTextView.textAlignment = aligment;
}

-(NSTextAlignment)textAlignment
{
	return internalTextView.textAlignment;
}

-(void)setSelectedRange:(NSRange)range
{
	internalTextView.selectedRange = range;
}

-(NSRange)selectedRange
{
	return internalTextView.selectedRange;
}

-(void)setEditable:(BOOL)beditable
{
	internalTextView.editable = beditable;
}

-(BOOL)isEditable
{
	return internalTextView.editable;
}

-(void)setReturnKeyType:(UIReturnKeyType)keyType
{
	internalTextView.returnKeyType = keyType;
}

-(UIReturnKeyType)returnKeyType
{
	return internalTextView.returnKeyType;
}

-(void)setDataDetectorTypes:(UIDataDetectorTypes)datadetector
{
	internalTextView.dataDetectorTypes = datadetector;
}

-(UIDataDetectorTypes)dataDetectorTypes
{
	return internalTextView.dataDetectorTypes;
}

- (BOOL)hasText
{
	return [internalTextView hasText];
}

- (void)scrollRangeToVisible:(NSRange)range
{
	[internalTextView scrollRangeToVisible:range];
}

#pragma mark -
#pragma mark UIExpandingTextViewDelegate

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView 
{
	if ([delegate respondsToSelector:@selector(expandingTextViewShouldBeginEditing:)]) 
    {
		return [delegate expandingTextViewShouldBeginEditing:self];
	} 
    else 
    {
		return YES;
	}
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView 
{
	if ([delegate respondsToSelector:@selector(expandingTextViewShouldEndEditing:)]) 
    {
		return [delegate expandingTextViewShouldEndEditing:self];
	} 
    else 
    {
		return YES;
	}
}

- (void)textViewDidBeginEditing:(UITextView *)textView 
{
	if ([delegate respondsToSelector:@selector(expandingTextViewDidBeginEditing:)]) 
    {
		[delegate expandingTextViewDidBeginEditing:self];
	}
}

- (void)textViewDidEndEditing:(UITextView *)textView 
{		
	if ([delegate respondsToSelector:@selector(expandingTextViewDidEndEditing:)]) 
    {
		[delegate expandingTextViewDidEndEditing:self];
	}
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)atext 
{

	if((![textView hasText] && [atext isEqualToString:@""] ) /*|| internalTextView.text.length >= 200*/)
    {
        return NO;
	}
    
	if ([atext isEqualToString:@"\n"]) 
    {
		if ([delegate respondsToSelector:@selector(expandingTextViewShouldReturn:)]) 
        {
			if (![delegate performSelector:@selector(expandingTextViewShouldReturn:) withObject:self]) 
            {
				return YES;
			} 
            else 
            {
//				[textView resignFirstResponder];
				return NO;
			}
		}
	}
	return YES;
}

- (void)textViewDidChangeSelection:(UITextView *)textView 
{
	if ([delegate respondsToSelector:@selector(expandingTextViewDidChangeSelection:)]) 
    {
		[delegate expandingTextViewDidChangeSelection:self];
	}
}


- (CGFloat)measureHeightOfUITextView:(UITextView *)textView
{
    if ([textView respondsToSelector:@selector(snapshotViewAfterScreenUpdates:)])
    {
        // This is the code for iOS 7. contentSize no longer returns the correct value, so
        // we have to calculate it.
        //
        // This is partly borrowed from HPGrowingTextView, but I've replaced the
        // magic fudge factors with the calculated values (having worked out where
        // they came from)
        CGRect frame = textView.bounds;
        
        // Take account of the padding added around the text.
        
        UIEdgeInsets textContainerInsets = textView.textContainerInset;
        UIEdgeInsets contentInsets = textView.contentInset;
        
        CGFloat leftRightPadding = textContainerInsets.left + textContainerInsets.right + textView.textContainer.lineFragmentPadding * 2 + contentInsets.left + contentInsets.right;
        CGFloat topBottomPadding = textContainerInsets.top + textContainerInsets.bottom + contentInsets.top + contentInsets.bottom;
        
        frame.size.width -= leftRightPadding;
        frame.size.height -= topBottomPadding;
        
        NSString *textToMeasure = textView.text;
        if ([textToMeasure hasSuffix:@"\n"])
        {
            textToMeasure = [NSString stringWithFormat:@"%@-", textView.text];
        }
        
        // NSString class method: boundingRectWithSize:options:attributes:context is
        // available only on ios7.0 sdk.
        
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        [paragraphStyle setLineBreakMode:NSLineBreakByWordWrapping];
        
        NSDictionary *attributes = @{ NSFontAttributeName: textView.font, NSParagraphStyleAttributeName : paragraphStyle };
        
        CGRect size = [textToMeasure boundingRectWithSize:CGSizeMake(CGRectGetWidth(frame), MAXFLOAT)
                                                  options:NSStringDrawingUsesLineFragmentOrigin
                                               attributes:attributes
                                                  context:nil];
        
        CGFloat measuredHeight = ceilf(CGRectGetHeight(size) + topBottomPadding);
        return measuredHeight+8.0f;
    }
    else
    {
        return textView.contentSize.height;
    }
}

@end
