//
//  MainView.swift
//  XClone
//
//  Created by fatowl on 2024/12/21.
//

import SwiftUI

struct MainView: View {
    @State var isLoggedIn = false
    
    var body: some View {
        if isLoggedIn {
            TimelineView(isLoggedIn: $isLoggedIn)
        } else {
            LoginView(isLoggedIn: $isLoggedIn)
        }
    }
}

#Preview {
    MainView()
}
