//
// Created by Kaofan on 2017/9/29.
// Copyright (c) 2017 Tom Cruise. All rights reserved.
//

import Foundation

class markerSystem : NSObject
{
    private var Count : Int = 0
    var idDictionary : Dictionary = [Int:Int]()
    var markers : [marker] = []

    func setMarkers(byJsonString : String)
    {
        if byJsonString != "[]"
        {
            let jsonData = byJsonString.data(using: .utf8)
            let decoder = JSONDecoder()
            let KingGeorge = try! decoder.decode([marker].self, from: jsonData!);
            self.markers = KingGeorge
            idCalculating()
        }
    }
    func idCalculating()
    {
        var tempId : Dictionary = [Int:Int]() //now
        for marker in markers
        {
            if tempId[marker.id] == nil
            {
                tempId[marker.id] = 1
            }
            else
            {
                tempId[marker.id] = tempId[marker.id]!+1
            }
        }
        for ID in tempId
        {
           idDictionary[ID.key] = ID.value
        }
        for ID in idDictionary
        {
            if tempId[ID.key] == nil
            {
                idDictionary.removeValue(forKey: ID.key)
            }
        }
    }
    func getCount() -> Int
    {
        return self.Count
    }

}
