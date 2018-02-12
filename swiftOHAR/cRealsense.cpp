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
    //cv::Mat color(cv::Size(960, 720), CV_8UC3, (void*)dev->get_frame_data(rs::stream::color), cv::Mat::AUTO_STEP);
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
    depth8u.copyTo(returnDepth);

    
    return returnDepth;
}

cv::Mat cRealsense:: C2DImage()
{
    uchar* pCad = (uchar*)dev->get_frame_data(rs::stream::color_aligned_to_depth);
    cv::Mat returnC2D(480,640,CV_8UC3,pCad);
    cv::cvtColor(returnC2D, returnC2D, CV_BGR2RGB);
    return returnC2D;
}
cv::Mat cRealsense:: D2CImage()
{
    uchar* pDac = (uchar*)dev->get_frame_data(rs::stream::depth_aligned_to_color);
    cv::Mat returnD2C(480,640,CV_16U,pDac); //長寬要反過來
    returnD2C.convertTo(returnD2C, CV_8UC1,255.0/10000);
    return returnD2C;
}
cv::Mat cRealsense:: detectedImage()
{
    cv::Mat returnDetectedImage;
    cv::Mat color(cv::Size(640, 480), CV_8UC3, (void*)dev->get_frame_data(rs::stream::color), cv::Mat::AUTO_STEP);
    cImageProcess cIP;
    returnDetectedImage = cIP.getDetectAndDrawMarkers(color);
    cv::cvtColor(returnDetectedImage, returnDetectedImage, CV_BGR2RGB);
    tvecs = cIP.getTvecs();
    rvecs = cIP.getRvecs();
    ids = cIP.getIDs();
    corners = cIP.getCorners();
    markers = cIP.getMarkers();
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
    for(int i = 0;i<markers.size();i++)
    {
        if(markers[i].isValid() && markers[i].Tvec.at<int>(0,0) != -999999)
        {
            cout << markers[i] << endl;
            string singleRow = "{";
            singleRow = singleRow + "\"id\":" + to_string(markers[i].id) + ",";
            cv::Mat oneTvec(3,1,CV_64FC1);
    //        cv::Mat oneRvec(3,1,CV_64FC1);
            cv::Mat oneRMat(3,3,CV_32F);
            cv::Vec3d eulerAngles;
            for(int j=0;j<3;j++)
            {
                oneTvec.at<double>(j,0) = markers[i].Tvec.at<double>(j);
                //oneRvec.row(j).col(0) = markers[i].Rvec.at<double>(j);
            }
            cout << "Rvec" << markers[i].Rvec << endl;
            Rodrigues(markers[i].Rvec, oneRMat);
            singleRow = singleRow + "\"Rmat\":[" + to_string(oneRMat.at<float>(0,0)) + "," + to_string(oneRMat.at<float>(0,1)) + "," + to_string(oneRMat.at<float>(0,2)) + "," + to_string(oneRMat.at<float>(1,0)) + "," + to_string(oneRMat.at<float>(1,1)) + "," + to_string(oneRMat.at<float>(1,2)) + "," + to_string(oneRMat.at<float>(2,0)) + "," + to_string(oneRMat.at<float>(2,1)) + "," + to_string(oneRMat.at<float>(2,2)) + "" + "],";
            cout << "RmatSingle" << to_string(oneRMat.at<float>(0,1)) << endl;
            cout << "rMat: " << oneRMat << endl;
            //getEulerAngles(oneRMat, eulerAngles);
            //cout << "EA: " << eulerAngles << endl;
//            cv::Mat RotX = oneRMat.t();
//            cout << "ROTX : " << RotX << endl <<"Tvec: " << markers[i].Tvec << endl;
//            //cout << "Tvec[0]" << markers[i].Tvec.at<float>(0) << endl;;
//        
//            cv::Mat tvecConverted = -RotX * markers[i].Tvec.t();
//            cout << "New Tvec Converted " << tvecConverted << endl;
//            cout << "tvec00 : " << markers[i].Tvec.at<float>(0,0) << endl;
            singleRow = singleRow + "\"Tvec\":[" + to_string(oneTvec.at<double>(0,0)) + "," + to_string(oneTvec.at<double>(0,1)) + "," + to_string(oneTvec.at<double>(0,2)) + "],";
            //        //singleRow = singleRow + "\"Rvec\":[" + to_string(oneRvec.at<double>(0,0)) + "," + to_string(oneRvec.at<double>(0,1)) + "," + to_string(oneRvec.at<double>(0,2)) + "]}";
            singleRow = singleRow + "\"Rvec\":[" + to_string(eulerAngles[0]) + "," + to_string(eulerAngles[1]) + "," + to_string(eulerAngles[2]) + "],";
            singleRow = singleRow + "\"Corners\":[[" + to_string(markers[i][0].x) + "," + to_string(markers[i][0].y) + "],[" + to_string(markers[i][1].x) + "," + to_string(markers[i][1].y) + "],[" + to_string(markers[i][2].x) + "," + to_string(markers[i][2].y) + "],[" + to_string(markers[i][3].x) + "," + to_string(markers[i][3].y) + "]]}";
            if(i != (markers.size()-1))
            {
                singleRow += ",";
            }
            
            jsonString += singleRow;
        }
    }
    //cout << tvecs.size() << "||fuck you||" << tvecs[0];
    for(int i = 0;i<ids.size();i++)
    {
        if(markers.size() > 0)
        {
            jsonString += ",";
        }
        if(ids[i] != 0)
        {
            string singleRow = "{";
            singleRow = singleRow + "\"id\":" + to_string(ids[i]) + ",";
            singleRow = singleRow + "\"Rmat\":[0],";
            cv::Mat oneTvec(3,1,CV_64FC1);
            cv::Mat oneRvec(3,1,CV_64FC1);
            cv::Mat oneRMat(4,4,CV_64F);
            vector<cv::Point2f> oneCorners = corners[i];
            cv::Vec3d eulerAngles;
            for(int j=0;j<3;j++)
            {
                oneTvec.at<double>(j,0) = tvecs.at(i)[j];
                oneRvec.row(j).col(0) = rvecs[i][j];
            }
            Rodrigues(rvecs[i], oneRMat);
            getEulerAngles(oneRMat, eulerAngles);
            cv::Mat RotX = oneRMat.t();
            cv::Mat tvecConverted = -RotX * oneTvec;
            //print(eulerAngles); //數值為角度
            cout << "Rvec: " << oneRvec << endl;
            cout << "ROTX : " << RotX << endl <<"Tvec: " << oneTvec << endl;
//            cout << "old tvecConverted" << tvecConverted << endl;
            cout << "eulerAngle" << eulerAngles << endl;
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
    cout<<jsonString;
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
void cRealsense::getEulerAngles(cv::Mat &rotCamerMatrix,cv::Vec3d &eulerAngles)
{
    cv::Mat cameraMatrix,rotMatrix,transVect,rotMatrixX,rotMatrixY,rotMatrixZ;
    double* _r = rotCamerMatrix.ptr<double>();
    double projMatrix[12] = {_r[0],_r[1],_r[2],0,
        _r[3],_r[4],_r[5],0,
        _r[6],_r[7],_r[8],0};
    //yaw=[1] pitch=[0] roll=[2]
    decomposeProjectionMatrix( cv::Mat(3,4,CV_64FC1,projMatrix),
                              cameraMatrix,
                              rotMatrix,
                              transVect,
                              rotMatrixX,
                              rotMatrixY,
                              rotMatrixZ,
                              eulerAngles);
}
