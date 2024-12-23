//
//  CreatePostView.swift
//  XClone
//
//  Created by fatowl on 2024/12/22.
//

import SwiftUI
import PhotosUI

struct CreatePostView: View {
    @Binding var isPresented: Bool
    @State private var inputText: String = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isCominucaing: Bool = false
    @State private var isShowingAlert: Bool = false
    
    var body: some View {
        VStack {
            if isCominucaing {
                // 通信中はインジケーターを表示
                ProgressView()
            } else {
                Text("ポストを作成する")
                    .font(.title)
                
                TextEditor(text: $inputText)
                    .padding(2)
                    .frame(height: 200)
                    .border(.primary, width: 2)
                    .overlay(alignment: .topLeading) {
                        if inputText.isEmpty {
                            Text("ここに文字を入力してください。")
                                .allowsHitTesting(false)
                                .foregroundStyle(.secondary)
                                .padding(8)
                        }
                    }
                Image(uiImage: selectedImage ?? UIImage())
                    .resizable()
                    .scaledToFit()
                    .frame(height: 100)
                HStack {
                    PhotosPicker(selection: $selectedItem) {
                        HStack {
                            Image(systemName: "photo.artframe")
                            Text("画像を選択")
                        }
                        .padding(6)
                        .foregroundStyle(.white)
                        .background(.blue)
                        .cornerRadius(10)
                    }
                    Spacer()
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
                        isCominucaing = true
                        Task {
                            await createPost(content: inputText)
                            // ポストがデータベースにすぐに反映されないので一秒待ってから戻る
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                isPresented = false
                                isCominucaing = false
                            }
                        }
                    } label: {
                        Text("投稿する")

                    }
                    .padding(6)
                    .foregroundStyle(.white)
                    .background(Color.accentColor)
                    .cornerRadius(10)
                    .disabled(!validate())
                }
            }
        }
        .padding()
        // ピッカーから画像が選ばれたとき
        .onChange(of: selectedItem) {
            Task {
                await onImagePicked()
            }
        }
        .alert("エラー", isPresented: $isShowingAlert) {
        } message: {
            Text("ポストの投稿に失敗しました")
        }
    }
    
    func createPost(content: String) async {
        let supabase = SupabaseService.instance
        
        do {
            guard let user = try await supabase.getCurrentUser() else {
                isShowingAlert = true
                return
            }

            // 画像が選択されていたらアップロードする
            var imageUrl: String? = nil
            if let image = selectedImage {
                let url = try await supabase.uploadImage(image: image)
                imageUrl = url
            }
            
            try await supabase.addPost(userId: user.id.uuidString, content: content, imageUrl: imageUrl)

        } catch {
            isShowingAlert = true
            print(error)
        }
    }
    
    func validate() -> Bool {
        if inputText.isEmpty { return false }
        return true
    }
    
    func onImagePicked() async {
        guard let data = try? await selectedItem?.loadTransferable(type: Data.self) else { return }
        guard let uiImage = UIImage(data: data) else { return }
        await MainActor.run {
            selectedImage = uiImage
        }
    }
}

#Preview {
    CreatePostView(isPresented: .constant(true))
}
