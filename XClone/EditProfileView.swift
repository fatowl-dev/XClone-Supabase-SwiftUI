//
//  EditProfileView.swift
//  XClone
//
//  Created by fatowl on 2024/12/21.
//

import SwiftUI

struct EditProfileView: View {
    @Binding var presentState: ProfilePresentState
    @Binding var isPresented: Bool
    @State private var nicknameText: String
    @State private var isShowindAlert: Bool = false
    
    init(presentState: Binding<ProfilePresentState>, isPresented: Binding<Bool>) {
        self._presentState = presentState
        self._isPresented = isPresented
        self._nicknameText = .init(initialValue: "")
    }
    
    var body: some View {
        VStack {
            Text("ニックネーム")
            TextField("ニックネーム", text: $nicknameText)
                .padding(3)
                .border(.primary, width: 1)
            HStack {
                Button {
                    isPresented = false
                } label: {
                    Text("キャンセル")
                        .padding(6)
                        .foregroundStyle(.white)
                        .background(.red)
                        .cornerRadius(10)
                }
                
                Button {
                    Task {
                        await updateProfile()
                    }
                } label: {
                    Text("保存する")
                        .padding(6)
                        .foregroundStyle(.white)
                        .background(.blue)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
        .onAppear {
            nicknameText = presentState.nickname
        }
        .alert("エラー", isPresented: $isShowindAlert) {
        } message: {
            Text("プロフィールの変更に失敗しました")
        }
    }
    
    func updateProfile() async {
        let supabase = SupabaseService.instance
        do {
            guard let user = try await supabase.getCurrentUser() else {
                print("current user not found")
                return
            }
            
            let userId = user.id.uuidString
            let newNickname = nicknameText
            
            try await supabase.updateProfile(userId: userId, nickname: newNickname)
            
            await MainActor.run {
                //ProfileViewの表示を更新
                presentState.nickname = newNickname
                //EditProfileViewを閉じる
                isPresented = false
            }
        } catch {
            print(error)
        }
    }
}

#Preview {
    EditProfileView(presentState: .constant(ProfilePresentState(nickname: "nickname")), isPresented: .constant(true))
}
