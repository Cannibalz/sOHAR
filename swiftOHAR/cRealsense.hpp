//
//  cRealsense.hpp
//  swiftOHAR
//
//  Created by Tom Cruise on 2017/4/18.
//  Copyright © 2017年 Tom Cruise. All rights reserved.
//
#undef check
#include <opencv2/core.hpp>
#include <stdio.h>
#include <iostream>
#include <librealsense/rs.hpp>
using namespace std;
class cRealsense
{
public:
    cRealsense();
    cv::Mat colorImage();
    cv::Mat depthImage();
    cv::Mat D2CImage();
    cv::Mat C2DImage();
    cv::Mat detectedImage();
    vector<cv::Vec3d> Tvecs();
    vector<cv::Vec3d> Rvecs();
    string getPoseInformation();
    void init();
    void waitForNextFrame();
    void stop();
    void helloWorld();
private:
    rs::context ctx;
    rs::device *dev;
    vector<cv::Vec3d> rvecs,tvecs;
    vector<int> ids;
};

