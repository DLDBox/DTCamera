//
//  DTCameraViewController.m
//
//
//  Created by Dana Devoe on 5/2/14.
//  Copyright (c) 2014 Dana Devoe. All rights reserved.
//

#import "DTCameraViewController.h"
#import "DTCameraFocusSquare.h"

@interface DTCameraViewController ()

@property (strong) DTCaptureSessionManager *captureManager; // manages the camera

@property (nonatomic,strong) NSArray *uiViews; // UIViews[0..n]

@property (nonatomic,strong) DTCameraFocusSquare *camFocus;

@property (copy) void (^completionBlock)(UIImage *,NSDictionary*,NSError*);
@property (nonatomic,strong) UIPinchGestureRecognizer *pinchGeture;
@property (nonatomic,weak) UIView *focusView;

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo;

@end

@implementation DTCameraViewController

@synthesize captureManager;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	[self setCaptureManager:[[DTCaptureSessionManager alloc] init]];
   
	[[self captureManager] addVideoInputFrontCamera:NO]; // set to YES for Front Camera, No for Back camera
    [[self captureManager] addStillImageOutput];
	[[self captureManager] addVideoPreviewLayer];
   
	CGRect layerRect = [[[self view] layer] bounds];
    [[[self captureManager] previewLayer] setBounds:layerRect];
    [[[self captureManager] previewLayer] setPosition:CGPointMake(CGRectGetMidX(layerRect),CGRectGetMidY(layerRect))];
	[[[self view] layer] addSublayer:[[self captureManager] previewLayer]];
   
	[[captureManager captureSession] startRunning];
    
    self.pinchGeture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(didPinchView:)];
    [self.view addGestureRecognizer:self.pinchGeture];
    
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

#pragma mark - Rotation Methods
- (BOOL)shouldAutorotate
{
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void) toastAlert:(NSString *)title
{
}


- (void)addOverlyViews:(NSArray *)views;
{
   for(UIView *aView in views)
   {
      NSAssert( [aView isKindOfClass:UIView.class], @"Passing a non-view to the camera overlay");
      [[self view] addSubview:aView];
   }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    //[IMAGECACHE removeAll];
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    _completionBlock(image,(__bridge NSDictionary *)contextInfo,error);
}

#pragma mark - <Public> Methods
- (BOOL)isFrontCameraAvailable
{
    return [[self captureManager] isDevicePresentWithID:@"Front Camera"];
}

- (BOOL)isBackCameraAvailable
{
    return [[self captureManager] isDevicePresentWithID:@"Back Camera"];
}

- (BOOL)isFlashAvailable
{
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    return [captureDevice hasFlash];
}

- (void)switchToBackCamera
{
    [self.captureManager swithCamera];
}

- (void)setFlashValue:(CaptureSessionFlashMode)flashMode
{
    [captureManager setTorchandFlash:flashMode];
    
    [[NSUserDefaults standardUserDefaults] setInteger:flashMode forKey:SETTING_FLASH_STATUS];
}

- (CaptureSessionFlashMode)flashValue
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:SETTING_FLASH_STATUS];
}

- (void) takePictureWithBlock:(void (^)(UIImage *image,NSDictionary *dictionary,NSError *error))block
{
    _completionBlock = block;
    
    [[self captureManager] captureStillImageWithCompletion:^(UIImage *image,NSDictionary *dictionary,NSError *error)
    {
        block(image,dictionary,error);
        //UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
    }];
}

#pragma mark - focus methods
- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (event.allTouches.count == 1)
    {
        UITouch *touch = [[event allTouches] anyObject];
        CGPoint touchPoint = [touch locationInView:touch.view];
        [self focus:touchPoint];
        
        if (self.camFocus){
            [self.camFocus removeFromSuperview];
        }
        
        // Make sure the focus square is active only when touching inside of the camera's view
        //Which should be the focusView
        if( [touch view] == self.focusView )
        {
            self.camFocus = [[DTCameraFocusSquare alloc]initWithFrame:CGRectMake(touchPoint.x-40, touchPoint.y-40, 80, 80)];
            [self.camFocus setBackgroundColor:[UIColor clearColor]];
            [self.view addSubview:self.camFocus];
            [self.camFocus setNeedsDisplay];
            
            [UIView beginAnimations:nil context:NULL];
            [UIView setAnimationDuration:1.5];
            [self.camFocus setAlpha:0.0];
            [UIView commitAnimations];
        }
    }
}

- (void) focus:(CGPoint) aPoint;
{
    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    if (captureDeviceClass != nil)
    {
        AVCaptureDevice *device = [captureDeviceClass defaultDeviceWithMediaType:AVMediaTypeVideo];
        
        if([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:AVCaptureFocusModeAutoFocus])
        {
            CGRect screenRect = [[UIScreen mainScreen] bounds];
            double screenWidth = screenRect.size.width;
            double screenHeight = screenRect.size.height;
            double focus_x = aPoint.x/screenWidth;
            double focus_y = aPoint.y/screenHeight;
            
            if([device lockForConfiguration:nil])
            {
                [device setFocusPointOfInterest:CGPointMake(focus_x,focus_y)];
                [device setFocusMode:AVCaptureFocusModeAutoFocus];
                
                if ([device isExposureModeSupported:AVCaptureExposureModeAutoExpose]){
                    [device setExposureMode:AVCaptureExposureModeAutoExpose];
                }
                [device unlockForConfiguration];
            }
        }
    }
}

#pragma mark - <UIGestureRecognizer> Callback
- (void) didPinchView:(UITapGestureRecognizer *)sender
{
    UIPinchGestureRecognizer *pinch = (UIPinchGestureRecognizer *)sender;
    
    if (sender.state == UIGestureRecognizerStateBegan)
    {
        //DLog( @"Pinch Begin" );
    }
    else if( sender.state == UIGestureRecognizerStateCancelled)
    {
        //DLog( @"Pinch Cancel" );
    }
    else if( sender.state == UIGestureRecognizerStateEnded)
    {
        //DLog( @"Pinch End" );
    }
    else if( sender.state == UIGestureRecognizerStateChanged)
    {
        //DLog( @"Pinch Change (%f)",pinch.scale );
        [[self captureManager] setZoomFactor:pinch.scale];

    }
}

- (void)setFocusView:(UIView *)focusView
{
    _focusView = focusView;
}

@end

