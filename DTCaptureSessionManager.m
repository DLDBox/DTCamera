//
//  CaptureSessionManager.m
//
//
//  Created by Dana Devoe on 5/2/14.
//  Copyright (c) 2014 Dana Devoe. All rights reserved.
//


#import "DTCaptureSessionManager.h"
#import <ImageIO/ImageIO.h>
#import "DTLog.h"

@interface DTCaptureSessionManager()
@property(nonatomic,assign)BOOL isUsingFrontCamera;
@property (nonatomic,weak)AVCaptureDeviceInput* currentDevice ;
@property (nonatomic,assign) CaptureSessionFlashMode flashandTorchMode;
@property (nonatomic,assign) CGFloat zoomValue;
@property (nonatomic,assign) CGFloat previousZoom;

@end

@implementation DTCaptureSessionManager

@synthesize captureSession;
@synthesize previewLayer;
@synthesize stillImageOutput;

#pragma mark Capture Session Configuration

- (id)init
{
	if ((self = [super init]))
    {
		[self setCaptureSession:[[AVCaptureSession alloc] init]];
        self.zoomValue = 1.0;
        self.previousZoom = 1.0;
	}
	return self;
}

- (void)addVideoPreviewLayer
{
	[self setPreviewLayer:[[AVCaptureVideoPreviewLayer alloc] initWithSession:[self captureSession]]];
	[[self previewLayer] setVideoGravity:AVLayerVideoGravityResizeAspectFill];
}

- (BOOL) isDevicePresentWithID:(NSString *)deviceID
{
    return [AVCaptureDevice deviceWithUniqueID:deviceID] ? YES : NO;
}

- (void)addVideoInputFrontCamera:(BOOL)front
{
    NSArray *devices = [AVCaptureDevice devices];
    AVCaptureDevice *frontCamera;
    AVCaptureDevice *backCamera;
    
    self.isUsingFrontCamera = front;
    
    for (AVCaptureDevice *device in devices)
    {
        DLog(@"Device name: %@", [device localizedName]);
        
        if ([device hasMediaType:AVMediaTypeVideo])
        {
            if ([device position] == AVCaptureDevicePositionBack)
            {
                DLog(@"Device position : back");
                backCamera = device;
            }
            else
            {
                DLog(@"Device position : front");
                frontCamera = device;
            }
        }
    }
    
    NSError *error = nil;
    
    if (front)
    {
        AVCaptureDeviceInput *frontFacingCameraDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:frontCamera error:&error];
        if (!error)
        {
            if (self.currentDevice) {
                [[self captureSession] removeInput:self.currentDevice];
            }
            self.currentDevice = frontFacingCameraDeviceInput;
            
            if ([[self captureSession] canAddInput:frontFacingCameraDeviceInput]) {
                [[self captureSession] addInput:frontFacingCameraDeviceInput];
            }
            else{
                DLog(@"Couldn't add front facing video input");
            }
        }
    }
    else
    {
        AVCaptureDeviceInput *backFacingCameraDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:backCamera error:&error];
        if (!error)
        {
            if (self.currentDevice) {
                [[self captureSession] removeInput:self.currentDevice];
            }
            self.currentDevice = backFacingCameraDeviceInput;
            if ([[self captureSession] canAddInput:backFacingCameraDeviceInput])
            {
                [[self captureSession] addInput:backFacingCameraDeviceInput];
            }
            else
            {
                DLog(@"Couldn't add back facing video input");
            }
        }
    }
}

- (void)addStillImageOutput 
{
  [self setStillImageOutput:[[AVCaptureStillImageOutput alloc] init]];
  NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG,AVVideoCodecKey,nil];
  [[self stillImageOutput] setOutputSettings:outputSettings];
  
  AVCaptureConnection *videoConnection = nil;
  for (AVCaptureConnection *connection in [[self stillImageOutput] connections])
  {
      for (AVCaptureInputPort *port in [connection inputPorts])
      {
          if ([[port mediaType] isEqual:AVMediaTypeVideo] )
          {
              videoConnection = connection;
              break;
          }
      }
      
      if (videoConnection)
      {
          break; 
      }
  }
  
  [[self captureSession] addOutput:[self stillImageOutput]];
}

- (void)removeStillImageOutput
{
    [self.captureSession removeOutput:self.stillImageOutput];
}

- (void) captureStillImageWithCompletion:(void (^)(UIImage *theImage,NSDictionary *exif,NSError *error) )block
{
	AVCaptureConnection *videoConnection = nil;
	for (AVCaptureConnection *connection in [[self stillImageOutput] connections])
    {
		for (AVCaptureInputPort *port in [connection inputPorts])
        {
			if ([[port mediaType] isEqual:AVMediaTypeVideo])
            {
				videoConnection = connection;
				break;
			}
		}
        
		if (videoConnection){
            break;
        }
	}
    
    if ( !self.isUsingFrontCamera ) {
        [self userFlashMode];
    }
    
	//NSLog(@"about to request a capture from: %@", [self stillImageOutput]);
	[[self stillImageOutput] captureStillImageAsynchronouslyFromConnection:videoConnection
                                                         completionHandler:^(CMSampleBufferRef imageSampleBuffer, NSError *error){
                                                             CFDictionaryRef exifAttachments = CMGetAttachment(imageSampleBuffer, kCGImagePropertyExifDictionary, NULL);
                                                             
                                                             if (imageSampleBuffer)
                                                             {
                                                                 NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
                                                                 UIImage *image = [[UIImage alloc] initWithData:imageData];
                                                                 
                                                                 block(image,(__bridge NSDictionary *)(exifAttachments),error);
                                                             }
                                                             else{
                                                                 DLog( @"I got a NULL imageSampleBuffer for some reason in %s",__PRETTY_FUNCTION__ );
                                                             }
                                                             
                                                         }];
    
}

- (void) setTorchandFlash:(CaptureSessionFlashMode)flashMode
{
    self.flashandTorchMode = flashMode;
}

- (void) userFlashMode
{ // check if flashlight available
    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    
    if (captureDeviceClass != nil)
    {
        //AVCaptureDevice *device = self.currentDevice;//[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        
        if ([device hasTorch] && [device hasFlash])
        {
            [device lockForConfiguration:nil];
            switch (self.flashandTorchMode )
            {
                case CaptureSessionFlashOn:{
                    [device setTorchMode:AVCaptureTorchModeOn];
                    [device setFlashMode:AVCaptureFlashModeOn];
                }break;
                    
                case CaptureSessionFlashOff:{
                    [device setTorchMode:AVCaptureTorchModeOff];
                    [device setFlashMode:AVCaptureFlashModeOff];
                }break;
                    
                case CaptureSessionFlashAuto:{
                    [device setTorchMode:AVCaptureTorchModeAuto];
                    [device setFlashMode:AVCaptureFlashModeAuto];
                }break;
                    
                default:
                    break;
            }
            [device unlockForConfiguration];
        }
    }
}

- (void) swithCamera
{
    //Change camera source
    if([self captureSession])
    {
        //Indicate that some changes will be made to the session
        [[self captureSession] beginConfiguration];
        
        //Remove existing input
        AVCaptureInput* currentCameraInput = self.currentDevice;
        [[self captureSession] removeInput:currentCameraInput];
        
        //Get new input
        AVCaptureDevice *newCamera = nil;
        if(((AVCaptureDeviceInput*)currentCameraInput).device.position == AVCaptureDevicePositionBack)
        {
            newCamera = [self cameraWithPosition:AVCaptureDevicePositionFront];
            self.isUsingFrontCamera = YES;
        }
        else
        {
            newCamera = [self cameraWithPosition:AVCaptureDevicePositionBack];
            self.isUsingFrontCamera = NO;
        }
        
        //Add input to session
        NSError *err = nil;
        AVCaptureDeviceInput *newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:newCamera error:&err];
        if(!newVideoInput || err)
        {
            DLog(@"Error creating capture device input: %@", err.localizedDescription);
        }
        else
        {
            [[self captureSession] addInput:newVideoInput];
        }
        
        self.currentDevice = newVideoInput;
        
        //Commit all the configuration changes at once
        [[self captureSession] commitConfiguration];
    }
}

- (AVCaptureDevice *) cameraWithPosition:(AVCaptureDevicePosition) position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices){
        if ([device position] == position) return device;
    }
    return nil;
}

- (void)dealloc
{
	[[self captureSession] stopRunning];
}

- (void) setZoomFactor:(CGFloat)zoom
{
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    if ( zoom < 1.0 )
    {
        self.zoomValue *= zoom;
        //DLog( @"Zoom < 1.0" ) ;
    }
    else
    {
        CGFloat zoomDelta = (zoom - self.previousZoom);
        self.zoomValue += zoomDelta;
        //DLog( @"inZoom(%0.3f) preZoom(%0.3f) Zoom(%0.3f) Delta(%0.3f)",zoom,self.previousZoom,self.zoomValue,zoomDelta );
    }
    
    self.zoomValue = self.zoomValue < 1.0 ? 1 : self.zoomValue;
    self.previousZoom = self.zoomValue;

    if ( [device respondsToSelector:@selector(setVideoZoomFactor:)] &&
        device.activeFormat.videoMaxZoomFactor >= self.zoomValue)
    {
        NSError *error;
        
        if ( [device lockForConfiguration:&error] )
        {
            [device setVideoZoomFactor:self.zoomValue];
            [device unlockForConfiguration];
        }
    }
}

- (void) setZoomFactor0:(CGFloat)zoom
{
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    if ( zoom < 1.0 ){
        self.zoomValue *= zoom;
        DLog( @"Zoom < 1.0" ) ;
    }
    else
    {
        CGFloat zoomDelta = (zoom - self.previousZoom);
        self.zoomValue += zoomDelta;
        DLog( @"inZoom(%0.3f) preZoom(%0.3f) Zoom(%0.3f) Delta(%0.3f)",zoom,self.previousZoom,self.zoomValue,zoomDelta );
    }
    self.zoomValue = self.zoomValue < 1.0 ? 1 : self.zoomValue;
    
    self.previousZoom = zoom;
    
    
    if ( [device respondsToSelector:@selector(setVideoZoomFactor:)] &&
        device.activeFormat.videoMaxZoomFactor >= self.zoomValue)
    {
        NSError *error;
        
        if ( [device lockForConfiguration:&error] )
        {
            [device setVideoZoomFactor:self.zoomValue];
            [device unlockForConfiguration];
        }
    }
}

- (void)resetZoom
{
    self.zoomValue = 1.0;
    self.previousZoom = 1.0;
}

@end
