//
//  DataModel.swift
//  AppStore
//
//  Created by Navdeep

import UIKit

struct App {
    var title: String
    var subtitle: String
    var id = UUID()
    var image: String
}


class DataModel {
    
    static var sections: [Section] = [.welocmeLabel,.crousel3d,.button,.trending2D]
    
    static var apps: [App] = [
        App(title: "Explore 3D Designs", subtitle: "3BHK", image: "a"),
        App(title: "Explore 3D Designs", subtitle: "2BHK",image: "b"),
        App(title: "Explore 3D Designs", subtitle: "2BHK", image: "c"),
        App(title: "Explore 3D Designs", subtitle: "2BHK", image: "d"),
    ]
    
    static var standardApps: [App] = [
        App(title: "Stylish & Functional Designs", subtitle: "", image: "a1"),
        App(title: "Your Vision, Our Design", subtitle: "",image: "a2"),
        App(title: "Customized Spaces for You", subtitle: "", image: "a3"),
        App(title: "Bring your dream home to life with inspiring layouts", subtitle: "", image: "a4"),
    ]
    
    static var label2D: [App] = [
        App(title: "Popular 2D Designs", subtitle: "", image: ""),
        
    ]
}





enum Section{
    case welocmeLabel
    case crousel3d
    case trending2D
    case button
}
