//
//  OpenCVManager.h
//  Portrait
//
//  Created by Rina Kotake on 2018/12/01.
//  Copyright © 2018年 koooootake. All rights reserved.
//

#ifndef OpenCVManager_h
#define OpenCVManager_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface OpenCVManager : NSObject
+ (OpenCVManager*)sharedManager;

-(UIImage*)doGrabCut:(UIImage*)sourceImage foregroundRect:(CGRect) rect iterationCount:(int)iterCount;
-(UIImage*)doGrabCut:(UIImage*)sourceImage markersImage:(UIImage*)maskImage iterationCount:(int) iterCount;
-(UIImage*)doBlur:(CGFloat)blurSize isUpdatedSegmentation:(BOOL)isUpdatedSegmentation gradientMaskImage:(UIImage*)gradientMaskImage;
-(UIImage*)inpaintingImage;
-(UIImage*)blurWithoutGradientImage;
-(void) resetManager;
@end

#endif /* OpenCVManager_h */
