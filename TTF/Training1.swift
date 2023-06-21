//
//  Training1.swift
//  TTF app
//
//  Created by Francesco Fossari on 09/04/21.
//

import SwiftUI

struct Training: View{
    var body: some View{
        
        NavigationView{
            VStack{
        VStack(alignment: .leading, spacing: 2){
            VStack{
                
               Spacer()
                   .frame(height: 100)
                
                Text("Training")
                    .foregroundColor(.black)
                    .font(.system(.largeTitle, design:.rounded))
                        .frame(minWidth: 10,  maxWidth: 280, minHeight: 10)
                        .padding(15)
                        .cornerRadius(10)
Spacer()
    .frame(height:250)
                NavigationLink(destination: ML1(newScene: .constant(false)), label:{
                    ZStack{
                        
                                    Image("squat22")
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .padding(10)
                                        .cornerRadius(10)
                                        .blur(radius:5, opaque: false)
                        
                                    Text("SQUATS")
                                        .font(.system(.largeTitle,design: .rounded))
                                        .fontWeight(.bold)
                                        .aspectRatio(contentMode: .fit)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                        .padding(30)
                        

                    }
                })
                   
                Spacer()
                    .frame(height: 300)
            } ;Spacer()
                .frame(height: 150)
   }
  }
 }
}
}

