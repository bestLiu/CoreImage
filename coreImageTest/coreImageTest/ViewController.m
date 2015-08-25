//
//  ViewController.m
//  coreImageTest
//
//  Created by mac1 on 15/7/1.
//  Copyright (c) 2015年 BNDK. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
{
    CIContext *context;
    CIImage *beginImage;
    CIFilter *blurFilter;
    CIFilter *filter;
    CIFilter *seDiaoFilter;
    CIFilter *zoomFilter;
    CIFilter *effctFilter;
    CIFilter *mskFilter;
   // CIFaceFeature *faceFeature;
}
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UISlider *slider;
@property (weak, nonatomic) IBOutlet UISlider *blurSlider;



@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    
//获取所有滤镜及属性方法
    [self logAllFilters];
    
    beginImage = [CIImage imageWithCGImage:[UIImage imageNamed:@"feng"].CGImage];
    _imageView.image = [UIImage imageWithCIImage:beginImage];
    context = [CIContext contextWithOptions:nil];
    
    //复古滤镜
    filter = [CIFilter filterWithName:@"CISepiaTone"
                                  keysAndValues: kCIInputImageKey, beginImage,
                        @"inputIntensity", [NSNumber numberWithFloat:0.8], nil];
    
    //高斯模糊滤镜
    blurFilter = [CIFilter filterWithName:@"CIGaussianBlur" ];
    [blurFilter setValue:beginImage forKey:kCIInputImageKey];
    
    //色调滤镜
    seDiaoFilter = [CIFilter filterWithName:@"CIHueAdjust" withInputParameters:@{kCIInputImageKey:beginImage}];
    
    //缩放模糊滤镜
    zoomFilter = [CIFilter filterWithName:@"CIZoomBlur" withInputParameters:@{kCIInputCenterKey:[CIVector vectorWithX:150 Y:150],kCIInputImageKey:beginImage}];
    
    //黑白滤镜
    effctFilter = [CIFilter filterWithName:@"CIPhotoEffectNoir" withInputParameters:@{kCIInputImageKey:beginImage}];
    
    //马赛克滤镜
    mskFilter = [CIFilter filterWithName:@"CIPixellate" withInputParameters:nil];
    
    
}


//复古
- (IBAction)silerValueChanged:(id)sender
{
    float slideValue = [_slider value];
    [filter setValue:[NSNumber numberWithFloat:slideValue]
              forKey:@"inputIntensity"];
    CIImage *outputImage = [filter outputImage];
    [blurFilter setValue:outputImage forKey:kCIInputImageKey];
    
    CGImageRef cgimg = [context createCGImage:outputImage
                                     fromRect:[outputImage extent]];
    
    UIImage *newImg = [UIImage imageWithCGImage:cgimg];
    [_imageView setImage:newImg];
    
    CGImageRelease(cgimg);
}

//高斯模糊
- (IBAction)blurSliderValueChanged:(id)sender
{
    float value = [_blurSlider value];
    
    [blurFilter setValue:[NSNumber numberWithFloat:value] forKey: @"inputRadius"];
    
    CIImage *outputImage = [blurFilter outputImage];
    CGImageRef cgImage = [context createCGImage:outputImage fromRect:[outputImage extent]];
    _imageView.image = [UIImage imageWithCGImage:cgImage];
}
//色调
- (IBAction)seDiaoValueChanged:(UISlider *)sender
{
    float sliderValue = sender.value;
    [seDiaoFilter setValue:@(sliderValue) forKey:kCIInputAngleKey];
    CIImage *outputImage = [seDiaoFilter outputImage];
    CGImageRef cgImage = [context createCGImage:outputImage fromRect:[outputImage extent]];
    _imageView.image = [UIImage imageWithCGImage:cgImage];
    
}
- (IBAction)zoomValueChanged:(id)sender
{
    UISlider *slider = sender;
    [zoomFilter setValue:@(slider.value) forKey:kCIInputRadiusKey];
    CGImageRef cgImage = [context createCGImage:zoomFilter.outputImage fromRect:zoomFilter.outputImage.extent];
    _imageView.image = [UIImage imageWithCGImage:cgImage];
}


//反色(底片)
- (IBAction)invertColor:(id)sender
{
    CIFilter *invertFilter = [CIFilter filterWithName:@"CIColorInvert" withInputParameters:@{kCIInputImageKey:beginImage}];
    CIImage *outputImage = [invertFilter outputImage];
    CGImageRef cgImage = [context createCGImage:outputImage fromRect:[outputImage extent]];
    _imageView.image = [UIImage imageWithCGImage:cgImage];
}


//复合滤镜
- (IBAction)buttonClick:(id)sender
{
    // 1.创建CISepiaTone滤镜
    CIFilter *sepiaToneFilter = [CIFilter filterWithName:@"CISepiaTone"];
    [sepiaToneFilter setValue:beginImage forKey:kCIInputImageKey];
    [sepiaToneFilter setValue:[NSNumber numberWithFloat:1.0] forKey:kCIInputIntensityKey];
    
    // 2.创建白斑图滤镜
    CIFilter *randomFilter = [CIFilter filterWithName:@"CIRandomGenerator"];
    CIFilter *whiteSpecksFilter = [CIFilter filterWithName:@"CIColorMatrix" withInputParameters:@{kCIInputImageKey:[randomFilter.outputImage imageByCroppingToRect:[beginImage extent]]}];
    [whiteSpecksFilter setValue:[CIVector vectorWithX:0 Y:1 Z:0 W:0] forKey:@"inputRVector"];
    [whiteSpecksFilter setValue:[CIVector vectorWithX:0 Y:1 Z:0 W:0] forKey:@"inputGVector"];
    [whiteSpecksFilter setValue:[CIVector vectorWithX:0 Y:1 Z:0 W:0] forKey:@"inputBVector"];
    [whiteSpecksFilter setValue:[CIVector vectorWithX:0 Y:0 Z:0 W:0] forKey:@"inputBiasVector"];
    
    
    // 3.把CISepiaTone滤镜和白斑图滤镜以源覆盖(source over)的方式先组合起来
    CIFilter *sourceOverCompositingFilter = [CIFilter filterWithName:@"CISourceOverCompositing"];
    [sourceOverCompositingFilter setValue:whiteSpecksFilter.outputImage forKey:kCIInputBackgroundImageKey];
    [sourceOverCompositingFilter setValue:sepiaToneFilter.outputImage forKey:kCIInputImageKey];
    
    
    // 4.用CIAffineTransform滤镜先对随机噪点图进行处理
    CIFilter *affineTransformFilter = [CIFilter filterWithName:@"CIAffineTransform"];
    [affineTransformFilter setValue:[[CIFilter filterWithName:@"CIRandomGenerator"].outputImage imageByCroppingToRect:[beginImage extent]] forKey:kCIInputImageKey];
    [affineTransformFilter setValue:[NSValue valueWithCGAffineTransform:CGAffineTransformMakeScale(1.5, 25)] forKey:kCIInputTransformKey];
    
    
    // 5.创建蓝绿色磨砂图滤镜
    CIFilter *darkScratchesFilter = [CIFilter filterWithName:@"CIColorMatrix"];
    [darkScratchesFilter setValue:affineTransformFilter.outputImage forKey:kCIInputImageKey];
    [darkScratchesFilter setValue:[CIVector vectorWithX:4 Y:0 Z:0 W:0] forKey:@"inputRVector"];
    [darkScratchesFilter setValue:[CIVector vectorWithX:0 Y:0 Z:0 W:0] forKey:@"inputGVector"];
    [darkScratchesFilter setValue:[CIVector vectorWithX:0 Y:0 Z:0 W:0] forKey:@"inputBVector"];
    [darkScratchesFilter setValue:[CIVector vectorWithX:0 Y:0 Z:0 W:0] forKey:@"inputAVector"];
    [darkScratchesFilter setValue:[CIVector vectorWithX:0 Y:1 Z:1 W:1] forKey:@"inputBiasVector"];

    
    // 6.用CIMinimumComponent滤镜把蓝绿色磨砂图滤镜处理成黑色磨砂图滤镜
    CIFilter *minimumComponentFilter = [CIFilter filterWithName:@"CIMinimumComponent"];
    [minimumComponentFilter setValue:darkScratchesFilter.outputImage forKey:kCIInputImageKey];
    

    // 7.最终组合在一起
    CIFilter *multiplyCompositingFilter = [CIFilter filterWithName:@"CIMultiplyCompositing"];
    [multiplyCompositingFilter setValue:minimumComponentFilter.outputImage forKey:kCIInputBackgroundImageKey];
    [multiplyCompositingFilter setValue:sourceOverCompositingFilter.outputImage forKey:kCIInputImageKey];
    
    // 8.最后输出
    CIImage *outputImage000 = [multiplyCompositingFilter outputImage];
    CGImageRef cgImage1 = [context createCGImage:outputImage000 fromRect:[outputImage000 extent]];
    _imageView.image = [UIImage imageWithCGImage:cgImage1];
    
}

//黑白
- (IBAction)darkWhiteButtonClick:(id)sender
{
    CIImage *outputImage = [effctFilter outputImage];
    CGImageRef cgImage = [context createCGImage:outputImage fromRect:outputImage.extent];
    _imageView.image = [UIImage imageWithCGImage:cgImage];
}

//马赛克
- (IBAction)马赛克buttonclick:(id)sender
{
    [mskFilter setValue:[CIVector vectorWithX:CGRectGetWidth(_imageView.frame)/2 Y:CGRectGetHeight(_imageView.frame)/2] forKey:kCIInputCenterKey];
    [mskFilter setValue:beginImage forKey:kCIInputImageKey];
    [mskFilter setValue:@(20) forKey:kCIInputScaleKey];
    CIImage *outputImage = [mskFilter outputImage];
    CGImageRef cgImage = [context createCGImage:outputImage fromRect:[outputImage extent]];
    _imageView.image = [UIImage imageWithCGImage:cgImage];
}

- (IBAction)faceButtonClick:(id)sender
{
//    faceFeature
    NSDictionary* opts = [NSDictionary dictionaryWithObject:
                          CIDetectorAccuracyHigh forKey:CIDetectorAccuracy];
    CIDetector* detector = [CIDetector detectorOfType:CIDetectorTypeFace
                                              context:nil options:opts];
    NSArray* features = [detector featuresInImage:beginImage];
    
    
    CGSize inputImageSize = beginImage.extent.size;
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    transform = CGAffineTransformScale(transform, 1, -1); //在Y轴缩放-1相当于沿着X轴翻折一下
    transform = CGAffineTransformTranslate(transform, 0, -inputImageSize.height); //然后再向下平移一下。这两步相当于旋转180
    
    //遍历这张图片上的脸，此时只有一个对象，有时一张图片有多张脸
    for (CIFaceFeature *faceFeature in features)
    {
        CGRect faceViewBounds = CGRectApplyAffineTransform(faceFeature.bounds, transform);
        
        float scale = MIN(_imageView.bounds.size.width/inputImageSize.width, _imageView.bounds.size.height/inputImageSize.height);
        
        float offsetX = (_imageView.bounds.size.width - inputImageSize.width * scale)/2;
        float offsetY = (_imageView.bounds.size.height - inputImageSize.height * scale)/2;
        
        faceViewBounds = CGRectApplyAffineTransform(faceViewBounds, CGAffineTransformMakeScale(scale, scale));
        faceViewBounds.origin.x += offsetX;
        faceViewBounds.origin.y += offsetY;
        
        UIView *faceView = [[UIView alloc] initWithFrame:faceViewBounds];
        faceView.layer.borderWidth = 1;
        faceView.layer.borderColor = [UIColor redColor].CGColor;
        [_imageView addSubview:faceView];
        
       
    }
    
        

}







- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)logAllFilters {
    NSArray *properties = [CIFilter filterNamesInCategory:
                           kCICategoryBuiltIn];
    NSLog(@"%@", properties);
    for (NSString *filterName in properties) {
        CIFilter *fltr = [CIFilter filterWithName:filterName];
        NSLog(@"attributes————————————%@", [fltr attributes]);
    }
}

@end
