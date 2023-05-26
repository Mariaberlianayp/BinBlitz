//
//  howToView.swift
//  nano2
//
//  Created by Maria Berliana on 26/05/23.
//

import SwiftUI
import UIKit
import ARKit

struct ViewControllerWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> ViewController {
        return ViewController()
    }
    
    func updateUIViewController(_ uiViewController: ViewController, context: Context) {
        // Update the view controller if needed
    }
}

struct howToView: View {
    init(){
            UINavigationBar.setAnimationsEnabled(false)
        }
    @State private var redirectToGame = false
    @State var appeared: Double = 0
    var body: some View {
        NavigationView{
            ZStack{
                Image("howTO")
                VStack{
                    Button(action: {
                        redirectToGame = true
                    }) {
                        Image(systemName: "arkit")
                            .fontWeight(.semibold)
                            .padding(.leading, 20.0)
                            .padding(.vertical, 8.0)
                        Text("PLAY")
                            .fontWeight(.black)
                            .padding(.leading, 10.0)
                            .padding(.trailing, 35.0)
                    }
                    .foregroundColor(Color("DarkBlue"))
                    .background(Color("tosca"))
                    .cornerRadius(30)
                    .font(.system(size: 25))
                }.padding(.top, 650.0)
            }
            
        }.navigationBarBackButtonHidden(true)
            .opacity(appeared)
            .animation(Animation.easeIn(duration: 1.0), value: appeared)
            .onAppear {self.appeared = 1.0}
            .onDisappear {self.appeared = 0.0}
            .sheet(isPresented: $redirectToGame, onDismiss: {
                // Reset your data here
            }) {
                ViewControllerWrapper()
            }
            .onAppear {
                redirectToGame = false
            }
    }
}

struct howToView_Previews: PreviewProvider {
    static var previews: some View {
        howToView()
    }
}
