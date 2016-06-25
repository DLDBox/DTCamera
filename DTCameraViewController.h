//
//  DTCameraViewController.m
//
//
//  Created by Dana Devoe on 5/2/14.
//  Copyright (c) 2014 Dana Devoe. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import "DTViewController.h"
#import "DTCaptureSessionManager.h"

//typedef NS_ENUM(NSInteger, DTCameraFlashMode){
//    DTCameraFlashModeOff,
//    DTCameraFlashModeOn,
//    DTCameraFlashModeAuto
//};

#define SETTING_FLASH_STATUS @"kSettingFlashStatus"

@interface DTCameraViewController : UIViewController

- (BOOL)isFrontCameraAvailable;
- (BOOL)isBackCameraAvailable;
- (BOOL)isFlashAvailable;

//- (void)switchToFrontCamera;
- (void)switchToBackCamera;
- (void)setFlashValue:(CaptureSessionFlashMode)flashMode;
- (CaptureSessionFlashMode)flashValue;
- (void)addOverlyViews:(NSArray *)views;
- (void)takePictureWithBlock:(void (^)(UIImage *image,NSDictionary *dictionary,NSError *error))block;

- (void)setFocusView:(UIView *)focusView;

@end
