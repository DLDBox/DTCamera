//
//  CaptureSessionManager.m
//
//
//  Created by Dana Devoe on 5/2/14.
//  Copyright (c) 2014 Dana Devoe. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(NSUInteger, CaptureSessionFlashMode){
    CaptureSessionFlashOn,
    CaptureSessionFlashOff,
    CaptureSessionFlashAuto,
};

@interface DTCaptureSessionManager : NSObject {

}

@property (retain) AVCaptureVideoPreviewLayer *previewLayer;
@property (retain) AVCaptureSession *captureSession;
@property (retain) AVCaptureStillImageOutput *stillImageOutput;

- (BOOL) isDevicePresentWithID:(NSString *)deviceID;

- (void)addVideoPreviewLayer;
- (void)addStillImageOutput;
- (void)addVideoInputFrontCamera:(BOOL)front;

- (void)removeStillImageOutput;

- (void) swithCamera;
- (void) setTorchandFlash:(CaptureSessionFlashMode)flashMode;

- (void) captureStillImageWithCompletion:(void (^)(UIImage *theImage,NSDictionary *exif,NSError *error) )block;

- (void) setZoomFactor:(CGFloat)zoom;
- (void) resetZoom;

@end
