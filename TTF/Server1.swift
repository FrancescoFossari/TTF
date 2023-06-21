//
//  Server1.swift
//  TTF app
//
//  Created by Francesco Fossari on 10/04/21.
//

import  SwiftUI
import ParthenoKit


struct serverDemoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView12()
        }
    }
}

struct ContentView12: View {
    @State var sTeam = ""
    @State var sTag = ""
    @State var sKey = ""
    @State var sVal = ""
    @State var p = ParthenoKit()
    
    var body: some View {
            WriteView(sTeam: $sTeam, sTag: $sTag, sKey: $sKey, sVal: $sVal, p: $p)
    }
}

struct ContentView12_Previews: PreviewProvider {
    static var previews: some View {
        ContentView12()
    }
}

struct ReadView: View {
    
    @Binding var sTeam: String
    @Binding var sTag: String
    @Binding var sKey: String
    @Binding var sVal: String
    @Binding var p: ParthenoKit
    
    var body: some View {
        
        VStack{
            Group{
                Text("Team (*)")
                TextField("Inserisci il nome del tuo team", text: $sTeam)
                    .padding(6)
                    .border(Color.gray, width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
                    .padding(3)
                
                Text("Tag")
                TextField("Inserisci un eventuale tag", text: $sTag)
                    .padding(6)
                    .border(Color.gray, width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
                    .padding(3)
                
                Text("Chiave (*) (usa % per l'elenco di tutte)")
                TextField("Inserisci la chiave univoca associata al valore", text: $sKey)
                    .padding(6)
                    .border(Color.gray, width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
                    .padding(3)
            }
            
            Spacer()
            
            Button(action: {
                 sVal = p.readSync(team: sTeam, tag: sTag, key: sKey)
            })
            {
                Text("Leggi")
                    .padding(10)
                    .foregroundColor(.white)
            }.background(Color.black)
            Spacer()
            
            Group{
                Spacer()
                Text("Valore")
                if let valore = sVal {
                    Text(valore)
                        .padding(6)
                        .border(Color.gray, width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
                        .padding(3)
                }
                
                Spacer()
                Spacer()
                Text("(*) Obbligatorio")
                Spacer()
            }
        }
    }
}


struct WriteView: View {
    @Binding var sTeam: String
    @Binding var sTag: String
    @Binding var sKey: String
    @Binding var sVal: String
    @Binding var p: ParthenoKit
    
    var body: some View {
        VStack{
            Group{
                Text("Team Name(*)")
                    .font(.system(.largeTitle,design: .rounded))
                                        .fontWeight(.bold)
                                        .aspectRatio(contentMode: .fill)
                                        .foregroundColor(.black)
                                        .cornerRadius(10)
                                        .padding(20)
                TextField("", text: $sTeam)
                    .font(.system(.largeTitle, design:.rounded))
                                       .frame(minWidth: 10,  maxWidth: 280, minHeight: 10)
                                       .padding(20)
                                       .background(Color.white)
                                       .cornerRadius(10)
                                       .foregroundColor(ColorManager.bluemodificato)
                                       .overlay(
                                                   RoundedRectangle(cornerRadius: 20)
                                                       .stroke(ColorManager.bluemodificato, lineWidth: 5)
                                               )
                
                Text("Team PassKey")
                    .font(.system(.largeTitle,design: .rounded))
                                        .fontWeight(.bold)
                                        .aspectRatio(contentMode: .fill)
                                        .foregroundColor(.black)
                                        .cornerRadius(10)
                                        .padding(20)
                TextField("", text: $sTag)
                    .font(.system(.largeTitle, design:.rounded))
                                       .frame(minWidth: 10,  maxWidth: 280, minHeight: 10)
                                       .padding(20)
                                       .background(Color.white)
                                       .cornerRadius(10)
                                       .foregroundColor(ColorManager.bluemodificato)
                                       .overlay(
                                                   RoundedRectangle(cornerRadius: 20)
                                                       .stroke(ColorManager.bluemodificato, lineWidth: 5)
                                               )
                
                Text("Name")
                    .font(.system(.largeTitle,design: .rounded))
                                        .fontWeight(.bold)
                                        .aspectRatio(contentMode: .fill)
                                        .foregroundColor(.black)
                                        .cornerRadius(10)
                                        .padding(20)
                TextField("", text: $sKey)
                    .font(.system(.largeTitle, design:.rounded))
                                       .frame(minWidth: 10,  maxWidth: 280, minHeight: 10)
                                       .padding(20)
                                       .background(Color.white)
                                       .cornerRadius(10)
                                       .foregroundColor(ColorManager.bluemodificato)
                                       .overlay(
                                                   RoundedRectangle(cornerRadius: 20)
                                                       .stroke(ColorManager.bluemodificato, lineWidth: 5)
                                               )
                
                Text("Points")
                    .font(.system(.largeTitle,design: .rounded))
                                        .fontWeight(.bold)
                                        .aspectRatio(contentMode: .fill)
                                        .foregroundColor(.black)
                                        .cornerRadius(10)
                                        .padding(20)
                TextField("", text: $sVal)
                    .font(.system(.largeTitle, design:.rounded))
                    .frame(minWidth: 10,  maxWidth: 280, minHeight: 10)
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(10)
                    .foregroundColor(ColorManager.bluemodificato)
                    .overlay(
                            RoundedRectangle(cornerRadius: 20)
                            .stroke(ColorManager.bluemodificato, lineWidth: 5)
                                               )
            }
            Text("(*) Mandatory")
                .fontWeight(.bold)
            
            Button(action: {
                let result = p.writeSync(team: sTeam, tag: sTag, key: sKey, value: sVal)
                if result == false {
                    print("error!")
                }else{
                    sVal = ""
                }
            }) {
                Text("Done!")
                 .padding(5)
                  .foregroundColor(.white)
                  .font(.system(.largeTitle, design:.rounded))
                  .background(ColorManager.bluemodificato)
                 .cornerRadius(10)
                 .foregroundColor(.white)
            }
            
            Spacer()
                .frame(height: 100)
           
        }
    }
}
