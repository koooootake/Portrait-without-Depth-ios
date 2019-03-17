# Portrate-iOS
[![MIT License](http://img.shields.io/badge/license-MIT-green.svg?style=flat)](LICENSE)
[![Twitter](https://img.shields.io/badge/twitter-@koooootake-blue.svg?style=flat)](http://twitter.com/koooootake)

iOS demo app make 2D images, without Depth, into Portrait mode.

## How to build
1. Download `opencv2.framework` from [here](https://opencv.org/releases.html), then put it into this folder.
2. Open `Portrait.xcworkspace` with Xcode 10.x and build it ✨

## Contents
In Portrait mode, you can take beautiful photos that keep your subject sharp while blurring the background.  
This app make 2D images, without Depth, into Portrait mode.

### 1. Segmentation
In portrait mode, the most important thing is the segmentation of the subject and the background.  
This app use GrabCut.

#### GrabCut with Rect
![grabcut-with-rect](https://user-images.githubusercontent.com/12197538/54493357-6ee12a80-4912-11e9-98b7-18ad5d3033df.gif)

#### GrabCut with Mask
![grabcut-with-mask](https://user-images.githubusercontent.com/12197538/54493383-c97a8680-4912-11e9-8edd-814aed350953.gif)

### 2. Color leak prevention
The subject color leaks into the background is not beautiful.  
So, This app tried deleting the subject from the background.  
Using Inpainting.

#### Blur & Inpainting
![blur-and-inpainting](https://user-images.githubusercontent.com/12197538/54493557-cbdde000-4914-11e9-8fbb-34c2a1400a03.gif)


### 3. Depth-of-Feild
Depth-of-field is the range where the photo is in focus.  
I introduced another function into my app to control blurring area.

#### Adjust
![adjust-depth-of-field](https://user-images.githubusercontent.com/12197538/54493410-1a8a7a80-4913-11e9-8e60-e824ba97f06e.gif)

**This app can make beautiful 2D Images in portrait mode ✨**  
before ← → after  
<img src="https://user-images.githubusercontent.com/12197538/54493659-dea4e480-4915-11e9-90d0-4af7315254e9.png" width="300"> <img src="https://user-images.githubusercontent.com/12197538/54493650-c6cd6080-4915-11e9-86c7-5e20e705bbad.jpg" width="300">

Please give it a try ! 

## Requirement
Xcode 10.x  
iOS 12.0+

## Author
[Rina Kotake](https://koooootake.com/)

## Licenses
* [OpenCV](https://opencv.org/)
* [TimOliver/TOCropViewController](https://github.com/TimOliver/TOCropViewController)

Special Thanks ✨
