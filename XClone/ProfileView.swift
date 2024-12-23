//
//  ProfileView.swift
//  XClone
//
//  Created by fatowl on 2024/12/21.
//

import SwiftUI

// プロフィール表示するのに必要なパラメータ群
// 不要な通信をしないように
struct ProfilePresentState {
    var nickname: String
}

struct ProfileView: View {
    @State var state: ProfilePresentState = .init(nickname: "nickname")
    @State var isShowingEditProfileView = false
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("ニックネーム")
                HStack {
                    Text("\(state.nickname)")
                    Button {
                        isShowingEditProfileView = true 
                    } label: {
                        Text("編集")
                            .padding(5)
                            .foregroundStyle(.white)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
            }
            .padding()
            .onAppear {
                Task {
                    await getProfile()
                }
            }
        }
        .navigationTitle(Text("プロフィール"))
        .sheet(isPresented: $isShowingEditProfileView) {
            EditProfileView(presentState: $state, isPresented: $isShowingEditProfileView)
        }
    }
    
    func getProfile() async {
        let supabase = SupabaseService.instance
        do {
            let user = try await supabase.getCurrentUser()
            guard let userId = user?.id.uuidString else {
                print("current user not found")
                return
            }
            guard let profile = try await supabase.getProfile(userId: userId) else {
                print("profile not found")
                return
            }
            
            if let name = profile.nickname {
                await MainActor.run {
                    state.nickname = name
                }
            } else {
                state.nickname = "名無しさん"
            }
            
        } catch {
            print(error)
        }
    }
}

#Preview {
    ProfileView()
}
