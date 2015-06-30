//
//  NBEmojiSearchViewExampleTests.m
//  NBEmojiSearchViewExampleTests
//
//  Created by Dasmer Singh on 6/29/15.
//  Copyright (c) 2015 Dasmer Singh. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <KIF/KIF.h>

@interface NBEmojiSearchViewExampleTests : XCTestCase

@end

@implementation NBEmojiSearchViewExampleTests

-(void)testAutocompleteEmojiTypeFlow
{
    UIView *firstResponder = [self firstResponderInView:[[UIApplication sharedApplication] keyWindow]];
    [tester enterTextIntoCurrentFirstResponder:@"I love to play :bask"];
    UIView *basketballCell = [tester waitForTappableViewWithAccessibilityLabel:@"basketball"];
    [basketballCell tap];
    [tester expectView:firstResponder toContainText:@"I love to play 🏀 "];

    [tester enterTextIntoCurrentFirstResponder:@"and :soc"];
    UIView *soccerCell = [tester waitForTappableViewWithAccessibilityLabel:@"soccer"];
    [soccerCell tap];
    [tester expectView:firstResponder toContainText:@"I love to play 🏀 and ⚽ "];
}



#pragma mark - Internal

- (UIView *)firstResponderInView:(UIView *)view;
{
    if (view.isFirstResponder) {
        return view;
    }

    for (UIView *subView in view.subviews)
    {
        UIView *firstResponder = [self firstResponderInView:subView];

        if (firstResponder) {
            return firstResponder;
        }
    }
    return nil;
}

@end
