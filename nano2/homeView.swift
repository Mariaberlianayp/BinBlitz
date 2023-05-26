//
//  homeView.swift
//  nano2
//
//  Created by Maria Berliana on 25/05/23.
//

import SwiftUI
import UIKit
import ARKit



struct homeView: View {
    init(){
            UINavigationBar.setAnimationsEnabled(false)
        }
    @State private var redirectToHow = false
    @State var appeared: Double = 0
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 42/255, green: 35/255, blue: 78/255)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    Image("Home")
                    
                    Button(action: {
                        redirectToHow = true
                    }) {
                        Image(systemName: "arkit")
                            .fontWeight(.semibold)
                            .padding(.leading, 20.0)
                        Text("PLAY")
                            .fontWeight(.black)
                            .padding(.leading, 10.0)
                            .padding(.trailing, 35.0)
                    }
                    .foregroundColor(Color("DarkBlue"))
                    .padding(10.0)
                    .background(Color("tosca"))
                    .cornerRadius(30)
                    .font(.system(size: 25))
                    NavigationLink(
                        destination: howToView(),
                        isActive: $redirectToHow,
                        label: {
                            EmptyView()
                        }
                    )
                }.padding(.top, -20.0)
                .background(Image("bg"))
            }
            .navigationBarBackButtonHidden(true)
            .opacity(appeared)
            .animation(Animation.easeIn(duration: 1.0), value: appeared)
            .onAppear {self.appeared = 1.0}
            .onDisappear {self.appeared = 0.0}
            
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .navigationBarBackButtonHidden(true)
        .onAppear {
            redirectToHow = false
        }
    }
}


struct homeView_Previews: PreviewProvider {
    static var previews: some View {
        homeView()
    }
}
