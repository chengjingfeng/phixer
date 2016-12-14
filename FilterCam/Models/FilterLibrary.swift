//
//  FilterLibrary
//  FilterCam
//
//  Created by Philip Price on 12/2/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import Foundation
import GPUImage
import SwiftyJSON

// Static class that provides the data structures for holding the category and filter information, and also methods for loading from/saving to config files

class FilterLibrary{

    fileprivate static var initDone:Bool = false
    fileprivate static var saveDone:Bool = false

    static let sortClosure = { (value1: String, value2: String) -> Bool in return value1 < value2 }
    
    //////////////////////////////////////////////
    //MARK: - Category/Filter "Database"
    //////////////////////////////////////////////
    
    // The dictionary of Categories (key, title). key is category name
    open static var categoryDictionary:[String:String] = [:]
    open static var categoryList:[String] = []
    
    // Dictionary of FilterDescriptors (key, FilterDescriptorInterface). key is filter name
    open static var filterDictionary:[String:FilterDescriptorInterface?] = [:]
    
    // Dictionary of Category Dictionaries. Use category as key to get list of filters in that category
    typealias FilterList = Array<String>
    //open static var categoryFilters:[String:FilterList] = [:]
    open static var categoryFilters:[String:[String]] = [:]

    
    //////////////////////////////////////////////
    //MARK: - Setup/Teardown
    //////////////////////////////////////////////
    
    open static func checkSetup(){
        if (!FilterLibrary.initDone) {
            FilterLibrary.initDone = true
            
            // 'restore' the configuration from the setup file
            FilterLibrary.restore()
        }
        
    }
    
    fileprivate init(){
        FilterLibrary.checkSetup()
    }
    
    deinit{
        if (!FilterLibrary.saveDone){
            FilterLibrary.saveDone = true
            FilterLibrary.save()
        }
    }
    

    ////////////////////////////
    // Config File Processing
    ////////////////////////////
    
    
    fileprivate static let configFile = "FilterConfig"
    
    fileprivate static var parsedConfig:JSON = nil
    
    open static func restore(){
        var count:Int = 0
        var key:String
        var value:String
     
        categoryDictionary = [:]
        categoryList = []
        filterDictionary = [:]
        categoryFilters = [:]
        
        print ("FilterLibrary.restore() - loading configuration...")
        
        // find the configuration file, which must be part of the project
        let path = Bundle.main.path(forResource: configFile, ofType: "json")
        
        do {
            // load the file contents and parse the JSON string
            let fileContents = try NSString(contentsOfFile: path!, encoding: String.Encoding.utf8.rawValue) as String
            if let data = fileContents.data(using: String.Encoding.utf8) {
                parsedConfig = JSON(data: data)
                print("restore() - parsing data")
                //print ("\(parsedConfig)")
                
                // Category list
                count = 0
                for item in parsedConfig["categories"].arrayValue {
                    count = count + 1
                    key = item["key"].stringValue
                    value = item["title"].stringValue
                    addCategory(key:key, title:value)
                }
                print ("\(count) Categories found")

                // Build Category array from dictionary. More convenient than a dictionary
                categoryList = Array(categoryDictionary.keys)
                categoryList.sort(by: sortClosure)
                
                // Filter list
                count = 0
                for item in parsedConfig["filters"].arrayValue {
                    count = count + 1
                    key = item["key"].stringValue
                    value = item["class"].stringValue
                    addFilter(key:key, classname:value)
                }
                print ("\(count) Filters found")
                
                
                // Lookup Images
                count = 0
                for item in parsedConfig["lookup"].arrayValue {
                    count = count + 1
                    key = item["key"].stringValue
                    value = item["image"].stringValue
                    addLookup(key:key, image:value)
                }
                print ("\(count) Lookup Images found")
                
                
                // List of Filters in each Category
                count = 0
                for item in parsedConfig["assign"].arrayValue {
                    count = count + 1
                    key = item["category"].stringValue
                    var list:[String] = item["filters"].arrayValue.map { $0.string!}
                    list.sort(by: sortClosure) // sort alphabetically
                    addAssignment(category:key, filters:list)
                }
                print ("\(count) Category<-Filter Assignments found")
                
            } else {
                print("restore() - ERROR : no data found")
            }
        }
        catch let error as NSError {
            print("restore() - ERROR : reading from presets file : \(error.localizedDescription)")
        }
    }




    open static func save(){
        print ("FilterLibrary.save() - saving configuration...")
    }

 
    
    private static func addCategory(key:String, title:String){
        // just add the data to the dictionary
        FilterLibrary.categoryDictionary[key] = title
    }
  
    
    
    private static func addFilter(key:String, classname:String){
        // create an instance from the classname and add it to the dictionary
        var descriptor:FilterDescriptorInterface? = nil
        let ns = Bundle.main.infoDictionary!["CFBundleExecutable"] as! String
        let className = ns + "." + classname
        let theClass = NSClassFromString(className) as! FilterDescriptorInterface.Type
        descriptor = theClass.init()
        
        if (descriptor != nil){
            FilterLibrary.filterDictionary[key] = descriptor
            //print ("FilterLibrary.addFilter() Added class: \(classname)")
        } else {
            print ("FilterLibrary.addFilter() ERR: Could not create class: \(classname)")
        }
    }
    
    
    
    private static func addLookup(key:String, image:String){
        
        //var title: String
        //var ext: String
        
        let l = image.components(separatedBy:".")
        let title = l[0]
        let ext = l[1]
        //title = image[image.startIndex...image.index(image.endIndex, offsetBy:-5)]
        //ext = image[image.index(image.endIndex, offsetBy:-4)...image.endIndex]
        
        guard let path = Bundle.main.path(forResource: title, ofType: ext) else {
            print("addLookup() File not found:\(image)")
            return
        }
        
        // create a Lookup filter, set the name/title/image and add it to the Filter dictioary
        var descriptor:LookupFilterDescriptor
        descriptor = LookupFilterDescriptor()
        descriptor.key = key
        descriptor.title = title
        descriptor.setLookupFile(name: image)
        FilterLibrary.filterDictionary[key] = descriptor
    }
    
    
    
    private static func addAssignment(category:String, filters: [String]){
        FilterLibrary.categoryFilters[category] = filters
        
        if (!FilterLibrary.categoryList.contains(category)){
            print("addAssignment() ERROR: invalid category:\(category)")
        }
        
        // double-check that filters exist
        for key in filters {
            if (FilterLibrary.filterDictionary[key] == nil){
                print("addAssignment() ERROR: Filter not defined: \(key)")
            }
        }
        //print("Category:\(category) Filters: \(filters)")
    }

}
