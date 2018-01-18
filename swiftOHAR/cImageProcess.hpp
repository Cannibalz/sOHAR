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
using namespace std;
class cImageProcess
{
public:
    cImageProcess();
    cImageProcess(cv::Mat);
    void DetectAndDrawMarkers();
    cv::Mat getDetectAndDrawMarkers(cv::Mat);
    void RefreshFrame(cv::Mat);
    vector<int> getIDs();
    cv::Mat getImage();
    vector<cv::Vec3d> getRvecs();
    vector<cv::Vec3d> getTvecs();
    cv::Vec3d getRvec(int);
    cv::Vec3d getTvec(int);
    vector<vector<cv::Point2f>> getCorners();
    cv::Mat SobelEdgeDetect(cv::Mat); 
private:
    cv::Mat ARImage;
    cv::Mat inputImage;
    cv::Mat cameraMatrix, distCoeffs; //相機參數
    float markerLength;
    vector< cv::Vec3d > rvecs, tvecs;
    vector<int>ids;
    vector<vector<cv::Point2f>>corners, rejected;
    cv::Ptr<cv::aruco::Dictionary> dictionary;
};

