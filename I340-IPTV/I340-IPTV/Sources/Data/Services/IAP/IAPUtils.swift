//
//  Utils.swift
//  RazeFaces
//
//  Created by Nguyen Van Nhon on 7/10/19.
//  Copyright © 2019 Razeware LLC. All rights reserved.
//

import Foundation

class IAPUtils{
    
    class func getStringFromDate(date: Date, format: String) -> String         // convert date to string
    {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        let stringdate = dateFormatter.string(from: date)
        return stringdate
    }
    
    class func getDatefromString(strdate: String, format: String) -> Date      // convert string to date
    {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        if dateFormatter.date(from: strdate) != nil {
            let datevalue = dateFormatter.date(from: strdate)
            return datevalue!
        } else {
            // invalid format
            return Date()
        }
    }
}
