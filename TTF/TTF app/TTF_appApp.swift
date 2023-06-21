//
//  TTF_appApp.swift
//  TTF app
//
//  Created by Francesco Fossari on 09/04/21.
//

import SwiftUI

@main

struct TTFapp: App{
    @State private var newScene = false
    var body: some Scene {
        WindowGroup {
            if newScene{
               // Squats()
            }else{
                ContentView()
            }
        }
    }
}
