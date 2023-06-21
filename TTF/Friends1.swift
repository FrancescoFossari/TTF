//
//  Friends1.swift
//  TTF app
//
//  Created by Francesco Fossari on 09/04/21.
//

import SwiftUI
import ParthenoKit

struct Friend: View{
    @State var num = 0
    @State var p = ParthenoKit()
    @State var conta: Int = 0
    @State var ciao: String = ""
    let label: String = ""
    
    var body: some View{
        //NavigationView{
            VStack{
                Text("Leader Board")
                    .fontWeight(.bold)
                    .font(.system(.largeTitle, design:.rounded))
                    .padding(4)
                    .foregroundColor(.black)
                    
                
                Text("Swipe for results!")
                    .fontWeight(.bold)
                    .font(.system(.largeTitle, design:.rounded))
                    .padding(2)
                    .foregroundColor(ColorManager.bluemodificato)
                    
                
                Scores()
                
                
                /*
                Button(action: {
                    var wVal = p.writeSync(team: "Team E", tag: "amicionline1", key: "*nickname", value: "0")
                    var sVal = p.readSync(team: "Team E", tag: "amicionline1", key: "%")
                    let tok =  sVal.components(separatedBy:"§")
                    num = tok.count
                }) {
                    
                    Text("Press for Refresh")
                        .padding(10)
                        .font(.system(.largeTitle, design:.rounded))
                        .background(ColorManager.bluemodificato)
                        .cornerRadius(10)
                        .foregroundColor(.white)
 */
        }
      }
  
    
    struct ContentView: View {
        
        @State var sTeam = ""
        @State var sTag = ""
        @State var sKey = ""
        @State var sVal = ""
        @State var p = ParthenoKit()
        
        var body: some View{
            TabView{
                ReadView(sTeam: $sTeam, sTag: $sTag, sKey: $sKey, sVal: $sVal, p: $p)
                    .tabItem {
                        Text("Lettura")
                        Image(systemName: "icloud.and.arrow.down")
                }
            }
        }
    }
}

var p = ParthenoKit()
struct Scores: View {
    var userName =  p.readSync(team: "Team E", tag: "Scores", key: "%")
    
    var body: some View {
        let fullNameArr = userName.components(separatedBy: "§")
        let reversed1 = Array(fullNameArr.sorted())
        List(reversed1, id: \.self)
        {value in
                HStack(alignment: .bottom){
                Text("\(value.components(separatedBy: "|")[0].replacingOccurrences(of: "+0000", with: ""))")
                    .font(.system(size: 25))
                    .bold()
                    .foregroundColor(ColorManager.bluemodificato)
                
                    Spacer()
                    Text("\(value.components(separatedBy: "|")[1])")
                        .font(.system(size: 25))
                        .bold()
                        .foregroundColor(ColorManager.bluemodificato)

            }
        }
    }
}


    




