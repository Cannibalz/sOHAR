//
//  CalculateTime.swift
//  swiftOHAR
//
//  Created by Kaofan on 2018/2/13.
//  Copyright © 2018年 Tom Cruise. All rights reserved.
//

import Foundation
func CalculateExecuteTime(title: String!, call: () -> Void) {
    let startTime = CACurrentMediaTime()
    call()
    let endTime = CACurrentMediaTime()
    if let title = title {
        print("\(title): ")
    }
    print("Time - \(endTime - startTime)")
}
