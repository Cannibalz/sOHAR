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
    dictionary = cv::aruco::getPredefinedDictionary(cv::aruco::DICT_ARUCO_ORIGINAL);
    cv::String filename = "/Users/kaofan/Desktop/out_camera_calibrationWith20img.yml";   //Pro
    //cv::String filename = "/Users/TomCruise/Desktop/CameraParas.yml";   //iMac
    //cv::String filename = "/Users/TomCruise/Desktop/out_camera_calibration.yml";// <- new param from aruco calibration
    cv::FileStorage fs;
    fs.open(filename, cv::FileStorage::READ);
    fs["camera_matrix"] >> cameraMatrix;
    fs["distortion_coefficients"] >> distCoeffs;
    //if using new yml file,first letter of param name is lower case
    cameraParameters.readFromXMLFile("/Users/kaofan/Desktop/out_camera_calibrationWith20img.yml");
    markerDetector.setDictionary("ARUCO_MIP_36h12");
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
    markers = markerDetector.detect(inputImage);
    inputImage.copyTo(ARImage);
    for(size_t i=0;i<markers.size();i++)
    {
        markers[i].draw(ARImage);
        //cout << "not estimatePose yet Tvec: " << markers[i].Tvec << endl;
        markerPoseTracker.estimatePose(markers[i], cameraParameters, 0.05);
        //cout << "after estimatePose Tvec: " << markers[i].Tvec << endl;
        CvDraw.draw3dAxis(ARImage, markers[i], cameraParameters);
        CvDraw.draw3dCube(ARImage, markers[i], cameraParameters);
        cout << "3Dpoints:" <<markers[i].get3DPoints() << endl;
        cout << "center:" << markers[i].getCenter() << endl;
        cout << "corner 0:" << markers[i][0] << ",corner 1:" << markers[i][1] << ",corner 2:" << markers[i][2] << ",corner 3:" << markers[i][3] << endl;
        cv::Point2f centerV(0,0);
        for(int j = 0;j<4;j++)
        {
            centerV.x += markers[i][j].x;
            centerV.y += markers[i][j].y;
        }
        centerV.x /= 4;
        centerV.y /= 4;
        cout << "calculate center:" << centerV << endl;
    }
//    if(ids.size()>0)
//    {
//        cv::Mat oneRvecs(3,1,CV_64FC1);
//        cv::Mat rotMat(4, 4, CV_64F);
//        cv::Mat oneTvecs(3,1,CV_64FC1);
//        cv::aruco::drawDetectedMarkers(ARImage, corners, ids);
//        float markerLength = 0.05;
//        cv::aruco::estimatePoseSingleMarkers(corners, markerLength, cameraMatrix, distCoeffs, rvecs, tvecs);
//        for (int a = 0;a<3;a++)
//        {
//            oneRvecs.row(a).col(0) = rvecs[0][a];
//            oneTvecs = tvecs[0];
//            //cout << oneTvecs.at<double>(0,0) << "," << oneTvecs.at<double>(0,1) << "," << oneTvecs.at<double>(0,2);
//        }
//        Rodrigues(oneRvecs, rotMat);
//
//        for(int j = 0;j<ids.size();j++)
//        {
//            cv::aruco::drawAxis(ARImage, cameraMatrix, distCoeffs, rvecs[j], tvecs[j], 0.1);
//        }
//    }
}
cv::Mat cImageProcess::getDetectAndDrawMarkers(cv::Mat Image)
{
    cv::aruco::detectMarkers(Image, dictionary, corners, ids);
    markers = markerDetector.detect(Image);
    
    cv::Mat arImage;
    Image.copyTo(arImage);
    
    for(size_t i=0;i<markers.size();i++) //new aruco
    {
        markers[i].draw(ARImage);
        //cout << "not estimatePose yet Tvec: " << markers[i].Tvec << endl;
        markerPoseTracker.estimatePose(markers[i], cameraParameters, 0.05);
        //cout << "after estimatePose Tvec: " << markers[i].Tvec << endl;
        CvDraw.draw3dAxis(arImage, markers[i], cameraParameters);
        CvDraw.draw3dCube(arImage, markers[i], cameraParameters);
        //cout << "3Dpoints:" <<markers[i].get3DPoints() << endl;
        cout << "center:" << markers[i].getCenter() << endl;
        cout << "corner 0:" << markers[i][0] << ",corner 1:" << markers[i][1] << ",corner 2:" << markers[i][2] << ",corner 3:" << markers[i][3] << endl;
        cv::Point2f centerV(0,0);
        cout << "Tvec: " << markers[i].Tvec << " Rvec: " << markers[i].Rvec << endl;
        for(int j = 0;j<4;j++)
        {
            centerV.x += markers[i][j].x;
            centerV.y += markers[i][j].y;
        }
        centerV.x /= 4;
        centerV.y /= 4;
        cout << "calculate center:" << centerV << endl;
    }
    
    if(ids.size()>0) //legacy aruco
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
cv::Mat cImageProcess::SobelEdgeDetect(cv::Mat inputImage)
{
    cv::Mat SobelImage; //test
    if(inputImage.type() == CV_8UC3)
    {
        cvtColor(inputImage, inputImage, CV_BGR2GRAY);
    }
    GaussianBlur(inputImage, inputImage, cv::Size(3, 3), 0, 0);
    cv::Mat grad_x, grad_y;
    cv::Mat abs_grad_x, abs_grad_y;
    Sobel(inputImage, grad_x, CV_16S, 1, 0, 3, 1, 0, cv::BORDER_DEFAULT);
    convertScaleAbs(grad_x, abs_grad_x);  //轉成CV_8U
    Sobel(inputImage, grad_y, CV_16S, 0, 1, 3, 1, 0, cv::BORDER_DEFAULT);
    convertScaleAbs(grad_y, abs_grad_y);
    cv::Mat dst;
    addWeighted(abs_grad_x, 0.5, abs_grad_y, 0.5, 0, dst);
    threshold(dst, SobelImage, 80, 255, cv::THRESH_BINARY | cv::THRESH_OTSU);
    return SobelImage;
}
vector<int> cImageProcess::getIDs()
{
    return ids;
}
cv::Vec3d cImageProcess::getRvec(int index)
{
    return rvecs[index];
}
cv::Vec3d cImageProcess::getTvec(int index)
{
    return tvecs[index];
}
vector<cv::Vec3d> cImageProcess::getRvecs()
{
    return  rvecs;
}
vector<cv::Vec3d> cImageProcess::getTvecs()
{
    return  tvecs;
}
vector<vector<cv::Point2f>> cImageProcess::getCorners()
{
    return corners;
}
cv::Mat cImageProcess::getImage()
{
    return ARImage;
}
