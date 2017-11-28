//
//  cImageProcess.cpp
//  swiftOHAR
//
//  Created by Tom Cruise on 2017/6/14.
//  Copyright © 2017年 Tom Cruise. All rights reserved.
//

#include "cImageProcess.hpp"

cImageProcess::cImageProcess()
{
    markerLength = 0.1f;
    dictionary = cv::aruco::getPredefinedDictionary(aruco::DICT_ARUCO_ORIGINAL);
    //cv::String filename = "/Users/kaofan/Desktop/CameraParas.yml";   //Pro
    cv::String filename = "/Users/TomCruise/Desktop/CameraParas.yml";   //iMac
    cv::FileStorage fs;
    fs.open(filename, cv::FileStorage::READ);
    fs["Camera_Matrix"] >> cameraMatrix;
    fs["Distortion_Coefficients"] >> distCoeffs;
}
cImageProcess::cImageProcess(cv::Mat Image)
{
    //cRealsense rs;
    cImageProcess();
    inputImage = Image;
    ARImage = Image;
}
void cImageProcess::RefreshFrame(cv::Mat Image)
{
    inputImage = Image;
}
void cImageProcess::DetectAndDrawMarkers()
{
    cv::aruco::detectMarkers(inputImage, dictionary, corners, ids);

    inputImage.copyTo(ARImage);
    if(ids.size()>0)
    {
        cv::Mat oneRvecs(3,1,CV_64FC1);
        cv::Mat rotMat(4, 4, CV_64F);
        cv::Mat oneTvecs(3,1,CV_64FC1);
        cv::aruco::drawDetectedMarkers(ARImage, corners, ids);
        float markerLength = 0.05;
        cv::aruco::estimatePoseSingleMarkers(corners, markerLength, cameraMatrix, distCoeffs, rvecs, tvecs);
        for (int a = 0;a<3;a++)
        {
            oneRvecs.row(a).col(0) = rvecs[0][a];
            oneTvecs = tvecs[0];
            //cout << oneTvecs.at<double>(0,0) << "," << oneTvecs.at<double>(0,1) << "," << oneTvecs.at<double>(0,2);
        }
        Rodrigues(oneRvecs, rotMat);
        
        for(int j = 0;j<ids.size();j++)
        {
            cv::aruco::drawAxis(ARImage, cameraMatrix, distCoeffs, rvecs[j], tvecs[j], 0.1);
        }
    }
}
Mat cImageProcess::getDetectAndDrawMarkers(Mat Image)
{
    cv::aruco::detectMarkers(Image, dictionary, corners, ids);
    Mat arImage;
    Image.copyTo(arImage);
    if(ids.size()>0)
    {
        cv::Mat oneRvecs(3,1,CV_64FC1);
        cv::Mat rotMat(4, 4, CV_64F);
        cv::Mat oneTvecs(3,1,CV_64FC1);
        cv::aruco::drawDetectedMarkers(arImage, corners, ids);
        float markerLength = 0.05;
        cv::aruco::estimatePoseSingleMarkers(corners, markerLength, cameraMatrix, distCoeffs, rvecs, tvecs);
        for (int a = 0;a<3;a++)
        {
            oneRvecs.row(a).col(0) = rvecs[0][a];
            oneTvecs = tvecs[0];
            //cout << oneTvecs.at<double>(0,0) << "," << oneTvecs.at<double>(1,0) << "," << oneTvecs.at<double>(2,0);
        }
        Rodrigues(oneRvecs, rotMat);
        
        for(int j = 0;j<ids.size();j++)
        {
            cv::aruco::drawAxis(arImage, cameraMatrix, distCoeffs, rvecs[j], tvecs[j], 0.1);
        }
    }
    return arImage;
}
Mat cImageProcess::SobelEdgeDetect(Mat inputImage)
{
    Mat SobelImage; //test
    if(inputImage.type() == CV_8UC3)
    {
        cvtColor(inputImage, inputImage, CV_BGR2GRAY);
    }
    GaussianBlur(inputImage, inputImage, Size(3, 3), 0, 0);
    Mat grad_x, grad_y;
    Mat abs_grad_x, abs_grad_y;
    Sobel(inputImage, grad_x, CV_16S, 1, 0, 3, 1, 0, BORDER_DEFAULT);
    convertScaleAbs(grad_x, abs_grad_x);  //轉成CV_8U
    Sobel(inputImage, grad_y, CV_16S, 0, 1, 3, 1, 0, BORDER_DEFAULT);
    convertScaleAbs(grad_y, abs_grad_y);
    Mat dst;
    addWeighted(abs_grad_x, 0.5, abs_grad_y, 0.5, 0, dst);
    threshold(dst, SobelImage, 80, 255, THRESH_BINARY | THRESH_OTSU);
    return SobelImage;
}
vector<int> cImageProcess::getIDs()
{
    return ids;
}
Vec3d cImageProcess::getRvec(int index)
{
    return rvecs[index];
}
Vec3d cImageProcess::getTvec(int index)
{
    return tvecs[index];
}
vector<Vec3d> cImageProcess::getRvecs()
{
    return  rvecs;
}
vector<Vec3d> cImageProcess::getTvecs()
{
    return  tvecs;
}
vector<vector<Point2f>> cImageProcess::getCorners()
{
    return corners;
}
Mat cImageProcess::getImage()
{
    return ARImage;
}
