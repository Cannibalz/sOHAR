//
//  cRealsense.cpp
//  swiftOHAR
//
//  Created by Tom Cruise on 2017/4/18.
//  Copyright © 2017年 Tom Cruise. All rights reserved.
//

#include "cRealsense.hpp"
#include <iostream>
#include <opencv2/imgproc/imgproc.hpp>
#include "cImageProcess.hpp"
cRealsense::cRealsense()
{
    
}
cv::Mat cRealsense:: colorImage()
{
    cv::Mat color(cv::Size(640, 480), CV_8UC3, (void*)dev->get_frame_data(rs::stream::color), cv::Mat::AUTO_STEP);
    cv::Mat returnColor;
    color.copyTo(returnColor);
    cv::cvtColor(returnColor, returnColor, CV_BGR2RGB);
    return returnColor;
}
cv::Mat cRealsense:: depthImage()
{
    rs::intrinsics depth_intr = dev->get_stream_intrinsics(rs::stream::depth);
    cv::Mat depth16( depth_intr.height,depth_intr.width,CV_16U,(void*)dev->get_frame_data(rs::stream::depth) );
    cv::Mat depth8u = depth16;
    depth8u.convertTo( depth8u, CV_8UC1, /*1/255.0*/255.0/10000 );
    //uint16_t *depthImage = (uint16_t *) dev->get_frame_data(rs::stream::depth);
    cv::Mat returnDepth;//(depth_intr.height,depth_intr.width,CV_16UC1,depthImage);
    cv::Mat metalDepth = Mat(640,480,CV_32FC1);
    depth8u.copyTo(returnDepth);
    //metalDepth.row(0).col(0) = 0.5;
    depth8u.convertTo(metalDepth,CV_32FC1,1.0/255.0);
    //cout << "min: " << min << ",Max: " << max << endl;
    //cout << "Count: " << metalDepth.channels() << "Mat: " << endl << metalDepth << endl;
    //return returnDepth;
    return returnDepth;
}

cv::Mat cRealsense:: C2DImage()
{
    cv::Mat alignedC2D(cv::Size(640,480),CV_8UC3,(void*)dev->get_frame_data(rs::stream::color_aligned_to_depth), cv::Mat::AUTO_STEP);
    uchar* pCad = (uchar*)dev->get_frame_data(rs::stream::color_aligned_to_depth);
    cv::Mat returnC2D(480,640,CV_8UC3,pCad);
    alignedC2D.copyTo(returnC2D);
    cv::cvtColor(returnC2D, returnC2D, CV_BGR2RGB);
    return returnC2D;
}
cv::Mat cRealsense:: detectedImage()
{
    Mat returnDetectedImage;
    cv::Mat color(cv::Size(640, 480), CV_8UC3, (void*)dev->get_frame_data(rs::stream::color), cv::Mat::AUTO_STEP);
    cImageProcess cIP;
    returnDetectedImage = cIP.getDetectAndDrawMarkers(color);
    cv::cvtColor(returnDetectedImage, returnDetectedImage, CV_BGR2RGB);
    tvecs = cIP.getTvecs();
    rvecs = cIP.getRvecs();
    ids = cIP.getIDs();
    corners = cIP.getCorners();
    return returnDetectedImage;
}
vector<cv::Vec3d> cRealsense::Tvecs()
{
    return tvecs;
}
vector<cv::Vec3d> cRealsense::Rvecs()
{
    return rvecs;
}
void cRealsense::init() try
{
    printf("There are %d connected RealSense devices.\n", ctx.get_device_count());
    if(ctx.get_device_count() == 0)
    {
        printf("no device connected");
    }
    
    // This tutorial will access only a single device, but it is trivial to extend to multiple devices
    dev = ctx.get_device(0);
    dev->enable_stream(rs::stream::depth, rs::preset::best_quality);
    dev->enable_stream(rs::stream::color, rs::preset::best_quality);
    printf("\nUsing device 0, an %s\n", dev->get_name());
    printf("Serial number: %s\n", dev->get_serial());
    printf("Firmware version: %s\n", dev->get_firmware_version());
    // Configure all streams to run at VGA resolution at 60 frames per second
    dev->enable_stream(rs::stream::depth, 640, 480, rs::format::z16, 30);
    dev->enable_stream(rs::stream::color, 640, 480, rs::format::bgr8, 30);
    dev->enable_stream(rs::stream::infrared, 640, 480, rs::format::y8, 30);
    try { dev->enable_stream(rs::stream::infrared2, 640, 480, rs::format::y8, 30); }
    catch(...) { printf("Device does not provide infrared2 stream.\n"); }
    dev->start(); //start streaming
}
catch(const rs::error & e)
{
    // Method calls against librealsense objects may throw exceptions of type rs::error
    printf("rs::error was thrown when calling %s(%s):\n", e.get_failed_function().c_str(), e.get_failed_args().c_str());
    printf("    %s\n", e.what());
    //return EXIT_FAILURE;
}
string cRealsense::getPoseInformation()
{
    string jsonString = "[";
    //cout << tvecs.size() << "||fuck you||" << tvecs[0];
    for(int i = 0;i<ids.size();i++)
    {
        if(ids[i] != 0)
        {
            string singleRow = "{";
            singleRow = singleRow + "\"id\":" + to_string(ids[i]) + ",";
            cv::Mat oneTvec(3,1,CV_64FC1);
            cv::Mat oneRvec(3,1,CV_64FC1);
            cv::Mat oneRMat(4,4,CV_64F);
            vector<Point2f> oneCorners = corners[i];
            Vec3d eulerAngles;
            for(int j=0;j<3;j++)
            {
                oneTvec.at<double>(j,0) = tvecs.at(i)[j];
                oneRvec.row(j).col(0) = rvecs[i][j];
            }
            Rodrigues(rvecs[i], oneRMat);
            getEulerAngles(oneRMat, eulerAngles);
            Mat RotX = oneRMat.t();
            Mat tvecConverted = -RotX * oneTvec;
            //cout << "tvec" << tvecConverted << endl;
            //print("ea:");
            //print(eulerAngles); //數值為角度
            //print("\n");
            //cout << "gg:"<<oneTvec.at<double>(0,0) << "," << oneTvec.at<double>(0,1) << "," << oneTvec.at<double>(0,2) << "\n";
            singleRow = singleRow + "\"Tvec\":[" + to_string(oneTvec.at<double>(0,0)) + "," + to_string(oneTvec.at<double>(0,1)) + "," + to_string(oneTvec.at<double>(0,2)) + "],";
            //singleRow = singleRow + "\"Rvec\":[" + to_string(oneRvec.at<double>(0,0)) + "," + to_string(oneRvec.at<double>(0,1)) + "," + to_string(oneRvec.at<double>(0,2)) + "]}";
            singleRow = singleRow + "\"Rvec\":[" + to_string(eulerAngles[0]) + "," + to_string(eulerAngles[1]) + "," + to_string(eulerAngles[2]) + "],";
            singleRow = singleRow + "\"Corners\":[[" + to_string(oneCorners[0].x) + "," + to_string(oneCorners[0].y) + "],[" + to_string(oneCorners[1].x) + "," + to_string(oneCorners[1].y) + "],[" + to_string(oneCorners[2].x) + "," + to_string(oneCorners[2].y) + "],[" + to_string(oneCorners[3].x) + "," + to_string(oneCorners[3].y) + "]]}";
            if(i != (ids.size()-1))
            {
                singleRow += ",";
            }
            
            jsonString += singleRow;
        }
    }
    jsonString += "]";
    //cout<<jsonString;
    return jsonString;
}
void cRealsense::waitForNextFrame()
{
    dev->wait_for_frames(); 
}
void cRealsense::stop()
{
    dev->stop();
}
void cRealsense::helloWorld()
{
    std::cout<<"HELLO WORLD";
}
void cRealsense::getEulerAngles(Mat &rotCamerMatrix,Vec3d &eulerAngles)
{
    Mat cameraMatrix,rotMatrix,transVect,rotMatrixX,rotMatrixY,rotMatrixZ;
    double* _r = rotCamerMatrix.ptr<double>();
    double projMatrix[12] = {_r[0],_r[1],_r[2],0,
        _r[3],_r[4],_r[5],0,
        _r[6],_r[7],_r[8],0};
    //yaw=[1] pitch=[0] roll=[2]
    decomposeProjectionMatrix( Mat(3,4,CV_64FC1,projMatrix),
                              cameraMatrix,
                              rotMatrix,
                              transVect,
                              rotMatrixX,
                              rotMatrixY,
                              rotMatrixZ,
                              eulerAngles);
}
