//
//  QRScanViewController.m
//  QRScanViewController
//
//  Created by 酌晨茗 on 16/2/18.
//  Copyright © 2016年 酌晨茗. All rights reserved.
//

#import "QRScanViewController.h"
#import <AVFoundation/AVFoundation.h>

#define Width [UIScreen mainScreen].bounds.size.width
#define Height [UIScreen mainScreen].bounds.size.height
#define WindowWidth 250

@interface QRScanViewController ()<UIAlertViewDelegate, AVCaptureMetadataOutputObjectsDelegate, UINavigationControllerDelegate,  UIImagePickerControllerDelegate>

@property (nonatomic, strong) AVCaptureSession *session;

@property (nonatomic, strong) UIView *bacView;
@property (nonatomic, strong) UIImageView *scanImgView;

@property (nonatomic, assign) CGRect scanRect;

@end

@implementation QRScanViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.clipsToBounds = YES;
    self.title = @"扫一扫";
    
    self.view.backgroundColor = [UIColor lightGrayColor];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"相册" style:UIBarButtonItemStylePlain target:self action:@selector(photo)];
    
    [self createOverlayViewWithSuggestionTitle:@"将二维码放入框中，即可自动扫描"];
    [self startQRScan];
    
    // Do any additional setup after loading the view.
}

#pragma mark - 视图将要出现
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    [self resumeAnimation];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:YES];
    [UIView animateWithDuration:0.3 animations:^{
        self.view.backgroundColor = [UIColor clearColor];
    }];
}

#pragma mark - 蒙板
- (void)createOverlayViewWithSuggestionTitle:(NSString *)title {
    CGFloat left = (Width - WindowWidth) / 2.0;
    CGFloat top = (Height - WindowWidth) / 2.0;
    
    CGRect rect = CGRectMake(left, top, WindowWidth, WindowWidth);
    self.scanRect = rect;
    
    CGFloat lineLong = 15;
    CGFloat lineWidth = 1.5;
    
    UIColor *bacColor = [UIColor lightGrayColor];

    self.bacView = [[UIView alloc] initWithFrame:rect];
    self.bacView.backgroundColor = [UIColor clearColor];
    self.bacView.clipsToBounds = YES;
    [self.view addSubview:_bacView];
    self.scanImgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"scan_net"]];
    
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, Width, Height) cornerRadius:0];
    
    UIBezierPath *subPath = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:0];
    [path appendPath:subPath];
    [path setUsesEvenOddFillRule:YES];
    
    CAShapeLayer *fillLayer = [CAShapeLayer layer];
    fillLayer.path = path.CGPath;
    fillLayer.fillRule = kCAFillRuleEvenOdd;
    fillLayer.fillColor = bacColor.CGColor;
    fillLayer.opacity = 0.6;
    [self.view.layer addSublayer:fillLayer];
    UIColor *lineColor = [UIColor colorWithRed:75 / 255.0 green:137 / 255.0 blue:220 / 255.0 alpha:1];
    for (int i = 0; i < 2; i++) {
        for (int j = 0; j < 2; j++) {
            UIView *vLine = [[UIView alloc] initWithFrame:CGRectMake(left + (WindowWidth - lineWidth) * j, top + (WindowWidth - lineLong) * i, lineWidth, lineLong)];
            vLine.backgroundColor = lineColor;
            
            UIView *hLine = [[UIView alloc] initWithFrame:CGRectMake(left + (WindowWidth - lineLong) * j, top + (WindowWidth - lineWidth) * i, lineLong, lineWidth)];
            hLine.backgroundColor = lineColor;
            
            [self.view addSubview:vLine];
            [self.view addSubview:hLine];
        }
    }
    
    UILabel *suggestionLable = [[UILabel alloc] initWithFrame:CGRectMake(left, top + WindowWidth + 10, WindowWidth, 30)];
    suggestionLable.text = title;
    suggestionLable.textAlignment = NSTextAlignmentCenter;
    suggestionLable.textColor = [UIColor whiteColor];
    suggestionLable.backgroundColor = [UIColor clearColor];
    suggestionLable.font = [UIFont systemFontOfSize:14];
    [self.view addSubview:suggestionLable];
}

#pragma mark - 扫描
- (void)startQRScan {
    //获取摄像设备
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    //创建输入流
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    if (!input) return;
    //创建输出流
    AVCaptureMetadataOutput *output = [[AVCaptureMetadataOutput alloc] init];
    //设置代理 在主线程里刷新
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    //设置有效扫描区域
    output.rectOfInterest = _scanRect;
    //初始化链接对象
    self.session = [[AVCaptureSession alloc] init];
    //高质量采集率
    [self.session setSessionPreset:AVCaptureSessionPresetHigh];
    
    [self.session addInput:input];
    [self.session addOutput:output];
    //设置扫码支持的编码格式(如下设置条形码和二维码兼容)
    output.metadataObjectTypes = @[AVMetadataObjectTypeQRCode, AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode128Code];
    
    AVCaptureVideoPreviewLayer *layer = [AVCaptureVideoPreviewLayer layerWithSession:_session];
    layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    layer.frame = self.view.layer.bounds;
    [self.view.layer insertSublayer:layer atIndex:0];
    //开始捕获
    [self.session startRunning];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    if (metadataObjects.count > 0) {
        [_session stopRunning];
        AVMetadataMachineReadableCodeObject * metadataObject = [metadataObjects objectAtIndex:0];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"扫描结果" message:metadataObject.stringValue delegate:self cancelButtonTitle:@"退出" otherButtonTitles:@"再次扫描", nil];
        [alert show];
    }
}

#pragma mark - 相册
- (void)photo {
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        //1.初始化相册拾取器
        UIImagePickerController *controller = [[UIImagePickerController alloc] init];
        //2.设置代理
        controller.delegate = self;
        //3.设置资源：
        /**
         UIImagePickerControllerSourceTypePhotoLibrary,相册
         UIImagePickerControllerSourceTypeCamera,相机
         UIImagePickerControllerSourceTypeSavedPhotosAlbum,照片库
         */
        controller.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
        //4.随便给他一个转场动画
        controller.modalTransitionStyle=UIModalTransitionStyleFlipHorizontal;
        [self presentViewController:controller animated:YES completion:NULL];
        
    } else {
        UIAlertView * alert = [[UIAlertView alloc]initWithTitle:@"提示" message:@"设备不支持访问相册，请在设置->隐私->照片中进行设置！" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alert show];
    }
}

#pragma mark-> imagePickerController delegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    //1.获取选择的图片
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    //2.初始化一个监测器
    CIDetector*detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{ CIDetectorAccuracy : CIDetectorAccuracyHigh }];
    
    [picker dismissViewControllerAnimated:YES completion:^{
        //监测到的结果数组
        NSArray *features = [detector featuresInImage:[CIImage imageWithCGImage:image.CGImage]];
        if (features.count >= 1) {
            /**结果对象 */
            CIQRCodeFeature *feature = [features objectAtIndex:0];
            NSString *scannedResult = feature.messageString;
            UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"扫描结果" message:scannedResult delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
            [alertView show];
            
        } else {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:@"该图片没有包含一个二维码！" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
            [alertView show];
            
        }
    }];
}

#pragma mark - 动画
- (void)resumeAnimation {
    CAAnimation *animation = [_scanImgView.layer animationForKey:@"translationAnimation"];
    if(animation) {
        // 1. 将动画的时间偏移量作为暂停时的时间点
        CFTimeInterval pauseTime = _scanImgView.layer.timeOffset;
        // 2. 根据媒体时间计算出准确的启动动画时间，对之前暂停动画的时间进行修正
        CFTimeInterval beginTime = CACurrentMediaTime() - pauseTime;
        
        // 3. 要把偏移时间清零
        [self.scanImgView.layer setTimeOffset:0.0];
        // 4. 设置图层的开始动画时间
        [self.scanImgView.layer setBeginTime:beginTime];
        
        [self.scanImgView.layer setSpeed:1.5];
    } else {
        self.scanImgView.frame = CGRectMake(0, -WindowWidth, WindowWidth, WindowWidth);
        CABasicAnimation *scanNetAnimation = [CABasicAnimation animation];
        scanNetAnimation.keyPath = @"transform.translation.y";
        scanNetAnimation.byValue = @(WindowWidth);
        scanNetAnimation.duration = 3.0;
        scanNetAnimation.repeatCount = MAXFLOAT;
        [_scanImgView.layer addAnimation:scanNetAnimation forKey:@"translationAnimation"];
        [self.bacView addSubview:_scanImgView];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
