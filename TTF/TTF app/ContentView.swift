//
//  ContentView.swift
//  TTF app
//
//  Created by Francesco Fossari on 09/04/21.
//

import SwiftUI

struct ContentView: View{
    @State private var selezione: Int = 0
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
        @State private var selectedImage: UIImage?
        @State private var isImagePickerDisplay = false
    var body: some View{
        TabView(selection: $selezione){
            HomeView()
                .tabItem{
                    Text("TTF cloud")
                    Image(systemName: "cloud")
                }.navigationBarTitle(Text("Training"))
            
            Training()
                //IMPLEMENTARE IL CODICE PER LA PAGINA
                .tabItem {
                    Text("Training")
                    Image(systemName: "figure.walk.circle")
                }.navigationBarTitle(Text("Training"))
        
            Friend()
                //IMPLEMENTARE IL CODICE DELLA PAGINA
                .tabItem {
                    Text("Friends")
                    Image(systemName: "person.badge.plus")
                }.navigationBarTitle(Text("Training"))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
 }
}
