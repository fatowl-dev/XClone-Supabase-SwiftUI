//
//  SignUpView.swift
//  XClone
//
//  Created by fatowl on 2024/12/19.
//

import SwiftUI

struct RegisterView: View {
    @State private var emailText = ""
    @State private var passwordText = ""
    @State private var confirmPasswordText = ""
    @State private var isRegistered = false
    @State private var isCommunicating = false
    @State private var isShowingAlert = false
    
    var body: some View {
        if isCommunicating {
            //通信中はインジケーターを表示
            ProgressView()
        }
        else {
            NavigationStack {
                VStack(spacing: 0) {
                    HStack {
                        Text("メールアドレス")
                        Spacer()
                    }
                    
                    TextField("email", text: $emailText)
                        .autocapitalization(.none)  //これがないと自動で先頭が大文字になる
                        .keyboardType(.emailAddress)
                        .textFieldStyle(.roundedBorder)
                        .padding(.bottom)
                    
                    HStack {
                        Text("パスワード")
                        Spacer()
                    }
                    
                    SecureField("password", text: $passwordText)
                        .textFieldStyle(.roundedBorder)
                        .padding(.bottom)
                    
                    HStack {
                        Text("パスワード（確認用）")
                        Spacer()
                    }
                    SecureField("password", text: $confirmPasswordText)
                        .textFieldStyle(.roundedBorder)
                        .padding(.bottom)
                    
                    Button {
                        isCommunicating = true
                        Task {
                            await resisterWithEmail(email: emailText, password: passwordText)
                        }
                    } label: {
                        Text("新規登録")
                    }
                    .padding(6)
                    .foregroundStyle(.background)
                    .background(.selection)
                    .cornerRadius(10)
                    .disabled(!validate())
                }
                .padding()
                .navigationTitle(Text("XCloneに登録"))
                .navigationDestination(isPresented: $isRegistered) {
                    MainView()
                }
                .alert("エラー", isPresented: $isShowingAlert) {
                } message: {
                    Text("登録に失敗しました")
                }
            }
        }
    }
    
    func resisterWithEmail(email: String, password: String) async {
        do {
            let supabase = SupabaseService.instance
            try await supabase.registerWithEmail(email: email, password: password)
            
            // いったんログインしてユーザープロフィールを作成しログアウトする
            // この方法だと途中で通信が切れた場合、ユーザーはあるがプロフィールがない状態になる可能性がある
            try await supabase.loginWithEmail(email: email, password: password)
            if let user  = try await supabase.getCurrentUser() {
                try await supabase.addProfile(userId: user.id.uuidString)
            }
            try await supabase.logout()
            
            await MainActor.run {
                isRegistered = true
            }
        } catch {
            isShowingAlert = true
            print(error)
        }
        
        await MainActor.run {
            isCommunicating = false
        }
    }
    
    func validate() -> Bool {
        // メールアドレスが5文字未満
        if emailText.trimmingCharacters(in: .whitespacesAndNewlines).count < 5 { return false }
        // パスワードが6文字未満(Supabaseの初期設定)
        if passwordText.trimmingCharacters(in: .whitespacesAndNewlines).count < 6 { return false }
        // パスワードと確認用パスワードが一致していない
        if confirmPasswordText != passwordText { return false }
        
        return true
    }
}

#Preview {
    RegisterView()
}
