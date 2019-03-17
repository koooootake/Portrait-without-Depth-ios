//
//  OpenCVManager.m
//  Portrait
//
//  Created by Rina Kotake on 2018/12/01.
//  Copyright © 2018年 koooootake. All rights reserved.
//
#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>

#import "OpenCVManager.h"
#import <Foundation/Foundation.h>

@implementation OpenCVManager

//MARK: shared
static OpenCVManager* sharedData_ = nil;

+ (OpenCVManager*)sharedManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedData_ = [OpenCVManager new];
    });
    return sharedData_;
}

cv::Mat inputMat, maskMat, inpaintMat, blurWithoutGradientMat;
cv::Mat resultMat, bgModel, fgModel;
cv::Mat1b fgMaskMat, bgMaskMat;

//MARK: GrabCut
///前景RectからGrabCutで前景抽出
-(UIImage*)doGrabCut:(UIImage*)sourceImage foregroundRect:(CGRect)rect iterationCount:(int)iterationCount {
    //UIImageをMatに変換
    cv::Mat sourceMat;
    UIImageToMat(sourceImage, sourceMat);
    //RGBA > RGB
    cv::cvtColor(sourceMat , sourceMat , CV_RGBA2RGB);
    inputMat = sourceMat;
    //CGRectをRectに変換
    cv::Rect rectangle(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);

    //GrabCut
    //bgModel, fgMolde: 処理で使用する配列
    //iterationCount: 処理を繰り返す回数
    cv::grabCut(sourceMat, maskMat, rectangle, bgModel, fgModel, iterationCount, cv::GC_INIT_WITH_RECT);

    //結果から、前景らしい（GC_PR_FGD）領域を抽出して2値化
    cv::Mat1b fgMask;
    cv::compare(maskMat, cv::GC_PR_FGD, fgMask, cv::CMP_EQ);
    fgMaskMat = fgMask;
    bitwise_not(fgMaskMat, bgMaskMat);
    return MatToUIImage(fgMask);
}

///マーカーマスク画像からGrabCutで前景抽出
-(UIImage*)doGrabCut:(UIImage*)sourceImage markersImage:(UIImage*)markersImage iterationCount:(int)iterationCount {
    //新たに入力されたマーカーマスク画像を既存のマスクと合成する
    cv::Mat1b markersMat = [self synthesizeMaskWithMarkersImage:markersImage];

    //GrabCut
    cv::grabCut(inputMat, markersMat, cv::Rect(), bgModel, fgModel, iterationCount, cv::GC_INIT_WITH_MASK);
    maskMat = markersMat;

    //GC_FGDをGC_PR_FGDに変換
    cv::MatIterator_<unsigned char> itd = markersMat.begin();
    cv::MatIterator_<unsigned char> itd_end = markersMat.end();
    for(int i=0; itd != itd_end; ++itd, ++i) {
        if (*itd == cv::GC_FGD) {
            *itd = cv::GC_PR_FGD;
        }
    }

    cv::Mat1b fgMask;
    cv::compare(markersMat, cv::GC_PR_FGD, fgMask, cv::CMP_EQ);
    fgMaskMat = fgMask;
    bitwise_not(fgMaskMat, bgMaskMat);
    return MatToUIImage(fgMask);
}

///マスク組み合わせ
-(cv::Mat1b)synthesizeMaskWithMarkersImage:(UIImage*)image {
    //マーカーマスク画像の画素を抽出
    CGImageRef imageRef = [image CGImage];
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char *rawData = (unsigned char*) calloc(height * width * 4, sizeof(unsigned char));
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(rawData, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);

    //既存のマスクと合成
    cv::Mat1b markersMat = maskMat;
    uchar* data =  markersMat.data;
    int countFGD = 0, countBGD = 0, countRem = 0;

    for(int x = 0; x < width; x++) {
        for( int y = 0; y < height; y++) {
            NSUInteger byteIndex = ((image.size.width  * y) + x ) * 4;
            UInt8 red   = rawData[byteIndex];
            UInt8 green = rawData[byteIndex + 1];
            UInt8 blue  = rawData[byteIndex + 2];
            UInt8 alpha = rawData[byteIndex + 3];
            if(red == 255 && green == 255 && blue == 255 && alpha == 255) {//白色領域を前景
                data[width * y + x] = cv::GC_FGD;
                countFGD++;
            } else if(red == 0 && green == 0 && blue == 0 && alpha == 255) {//黒色領域を後景
                data[width * y + x] = cv::GC_BGD;
                countBGD++;
            } else {
                countRem++;
            }
        }
    }
    free(rawData);
    return markersMat;
}

//MARK: Blur
-(UIImage*)doBlur:(CGFloat)blurSize isUpdatedSegmentation:(BOOL)isUpdatedSegmentation gradientMaskImage:(UIImage*)gradientMaskImage {
    cv::Mat sourceMat = inputMat;
    cv::Mat1b fgMask = fgMaskMat;
    cv::Mat1b bgMask = bgMaskMat;
    cv::Mat inpaintingMat;

    if(isUpdatedSegmentation) {
        //fgマスクの縁を太くする
        cv::Mat1b fgContoursMask;
        fgMask.copyTo(fgContoursMask);
        std::vector<std::vector<cv::Point>> contours;
        std::vector<cv::Vec4i> hierarchy;
        cv::findContours(fgContoursMask, contours, hierarchy, cv::RETR_EXTERNAL, cv::CHAIN_APPROX_TC89_L1);
        cv::drawContours(fgContoursMask, contours, -1, cv::GC_PR_FGD, sourceMat.size().width / 120);

        //Inpainting 自動補間
        cv::inpaint(sourceMat, fgContoursMask, inpaintingMat, 3, cv::INPAINT_TELEA);
        inpaintMat = inpaintingMat;
    } else {
        inpaintingMat = inpaintMat;
    }

    cv::Mat blurResultMat, blurMat;
    double sigumaX = 0;//sigumaX: XYの標準偏差、X=Y=0の時blurSizeから決定する
    cv::GaussianBlur(inpaintingMat, blurMat, cv::Size(blurSize, blurSize), sigumaX, sigumaX, cv::BORDER_REPLICATE);
    blurWithoutGradientMat = blurMat;

    if (gradientMaskImage) {
        //グラデーションマスクを変換
        cv::Mat gradientMaskMat;
        UIImageToMat(gradientMaskImage, gradientMaskMat);
        cv::cvtColor(gradientMaskMat , gradientMaskMat , CV_RGBA2GRAY);
        bitwise_not(gradientMaskMat, gradientMaskMat);

        //グラデーションマスクとBlur画像を合成
        blurResultMat = cv::Mat(sourceMat.size(), sourceMat.type());
        for (int y = 0; y < blurResultMat.rows; ++y) {
            for (int x = 0; x < blurResultMat.cols; ++x) {
                cv::Vec3b pixelOrig = sourceMat.at<cv::Vec3b>(y, x);
                cv::Vec3b pixelBlur = blurMat.at<cv::Vec3b>(y, x);
                float blurVal = gradientMaskMat.at<unsigned char>(y, x) / 255.0f;
                cv::Vec3b pixelOut = blurVal * pixelBlur + (1.0f - blurVal) * pixelOrig;
                blurResultMat.at<cv::Vec3b>(y, x) = pixelOut;
            }
        }
    } else {
        blurResultMat = blurMat;
    }

    //合成
    cv::Mat bgMat, fgMat, result;
    blurResultMat.copyTo(bgMat, bgMask);
    sourceMat.copyTo(fgMat, fgMask);
    cv::add(bgMat, fgMat, result);

    //DOF比較用
    cv::Mat bgWithoutGradientMat;
    blurMat.copyTo(bgWithoutGradientMat, bgMask);
    cv::add(bgWithoutGradientMat, fgMat, blurWithoutGradientMat);

    return MatToUIImage(result);
}

-(UIImage*)inpaintingImage {
    cv::Mat inpaintingMat = inpaintMat;
    return MatToUIImage(inpaintingMat);
}

-(UIImage*)blurWithoutGradientImage {
    cv::Mat blurMat = blurWithoutGradientMat;
    return MatToUIImage(blurMat);
}

//MARK: reset
-(void)resetManager {
    maskMat.setTo(cv::GC_PR_BGD);
    bgModel.setTo(0);
    fgModel.setTo(0);
}

@end
