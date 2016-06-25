//
//  CameraFocusSquare.m
//  LightPhoto
//
//  Created by Dana De Voe on 3/7/15.
//  Copyright (c) 2015 Dana Devoe. All rights reserved.
//

#import "DTCameraFocusSquare.h"
#import <QuartzCore/QuartzCore.h>
#import "UIColor+Sharpic.h"

const float squareLength = 80.0f;

@implementation DTCameraFocusSquare

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        [self setBackgroundColor:[UIColor clearColor]];
        [self.layer setBorderWidth:2.0];
        [self.layer setCornerRadius:4.0];
        [self.layer setBorderColor:[UIColor whiteColor].CGColor];
        
        CABasicAnimation* selectionAnimation = [CABasicAnimation
                                                animationWithKeyPath:@"borderColor"];
        
        selectionAnimation.toValue = (id)[UIColor sharepicDarkTealColor].CGColor;
        selectionAnimation.repeatCount = 8;
        
        [self.layer addAnimation:selectionAnimation
                          forKey:@"selectionAnimation"];
    }
    return self;
}
@end
