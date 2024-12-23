//
//  ContentView.swift
//  XClone
//
//  Created by fatowl on 2024/12/19.
//

import SwiftUI

struct LoginView : View {
    @Binding var isLoggedIn : Bool
    @State private var emailText = "user@example.com"
    @State private var passwordText = "12345678"
    @State private var isCommunicating : Bool = false
    @State private var isShowingAlert : Bool = false
    
    var body: some View {
        if isCommunicating {
            //通信中はインジケーターを表示
            ProgressView()
        } else {
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
                    Button {
                        isCommunicating = true
                        Task {
                            await loginWithEmail(email: emailText, password: passwordText)
                        }
                    } label: {
                        Text("ログイン")
                            .padding(6)
                            .foregroundStyle(.white)
                            .background(.blue)
                            .cornerRadius(10)
                    }
                    .padding()
                    
                    
                    NavigationLink(destination: RegisterView()) {
                        Text("新規登録")
                            .padding(6)
                            .foregroundStyle(.white)
                            .background(.blue)
                            .cornerRadius(10)
                    }
                    .padding()
                    
                }
                .padding()
                .navigationTitle(Text("XCloneにログイン"))
                .navigationBarBackButtonHidden(true)
                .alert("エラー", isPresented: $isShowingAlert) {
                } message: {
                    Text("ログインに失敗しました")
                }
            }
        }
    }
    
    func loginWithEmail(email: String, password: String) async {
        do {
            let supabase = SupabaseService.instance
            try await supabase.loginWithEmail(email: emailText, password: passwordText)
            await MainActor.run {
                isLoggedIn = true
            }
        } catch {
            isShowingAlert = true
            print(error)
        }
        await MainActor.run {
            isCommunicating = false
        }
    }
}

#Preview {
    LoginView(isLoggedIn: MainView().$isLoggedIn)
}
