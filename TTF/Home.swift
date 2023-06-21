//
//  Home.swift
//  TTF app
//
//  Created by Francesco Fossari on 09/04/21.
//

import SwiftUI
import ParthenoKit

struct HomeView: View {
    @State private var newScene = false
    var body: some View {
        NavigationView{
            
            VStack{
        //VISUALIZZA IL NICKNAME IN ALTO A SINISTRA
        VStack(alignment: .leading, spacing: 2){
     //BOTTONI DA IMPLEMENTARE
            VStack{
                Spacer()
                        
                    .frame(height: 140)
                    Image("TTF")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipShape(Circle())
                        .font(.system(size: 50))
                        .frame(width: 300)
                 Spacer()
                    .frame(height: 150)
                
                
                NavigationLink(destination:ContentView12() , label: {
                        Text("Join a Team! ")
                            .font(.system(.largeTitle, design:.rounded))
                            .frame(minWidth: 10,  maxWidth: 200, minHeight: 10)
                            .padding(40)
                            .background(ColorManager.bluemodificato)
                            .cornerRadius(10)
                            .foregroundColor(.white)
                    })
            }
                Spacer()
                    .frame(height: 250)
    }
   }
  }
}
}






