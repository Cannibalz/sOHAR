//
//  cImageProcess.hpp
//  swiftOHAR
//
//  Created by Tom Cruise on 2017/6/14.
//  Copyright © 2017年 Tom Cruise. All rights reserved.
//

#ifndef cImageProcess_hpp
#define cImageProcess_hpp

#include <stdio.h>
#include <opencv2/core.hpp>
#include <opencv2/opencv.hpp>
#include <opencv2/aruco.hpp>
#endif /* cImageProcess_hpp */
using namespace cv;
using namespace std;
class cImageProcess
{
public:
    cImageProcess();
    cImageProcess(Mat);
    void DetectAndDrawMarkers();
    void RefreshFrame(Mat);
    vector<int> getIDs();
    Mat getImage();
    Vec3d getRvec(int);
    Vec3d getTvec(int);
    Mat SobelEdgeDetect(Mat); 
private:
    Mat ARImage;
    Mat inputImage;
    Mat cameraMatrix, distCoeffs; //相機參數
    float markerLength;
    vector< Vec3d > rvecs, tvecs;
    vector<int>ids;
    vector<vector<Point2f>>corners, rejected;
    Ptr<cv::aruco::Dictionary> dictionary;
};

