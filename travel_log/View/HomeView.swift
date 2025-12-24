//
//  HomeView.swift
//  travel_log
//
//  Created by 鈴木廉太郎 on 2025/11/30.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack{
            ZStack {
                VStack(spacing:30) {
                    Spacer(minLength: 50)
                    Color.clear
                    Image("tabirogu")
                        .resizable()
                        .frame(width:350,height:350)
                    CustomButton(title: "使い方！", action: {print("hello")})
                    CustomNavButton(title: "友達を追加", destination: FriendAddView())
                    CustomButton(title: "設定", action: {print("hello")})
                    
                    Spacer(minLength: 80)
                    
                    
                    
                }
                
                
                .background(Color.customBackgroundColor)
                .ignoresSafeArea()
            }
        }
        
        
    }
}

#Preview {
    HomeView()
}


    

