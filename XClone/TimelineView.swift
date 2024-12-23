//
//  Timeline.swift
//  XClone
//
//  Created by fatowl on 2024/12/21.
//

import SwiftUI

struct TimelineView: View {
    @StateObject var viewModel = InfiniteScrollViewModel()
    
    @Binding var isLoggedIn: Bool
    @State var isShowingCreatePostView = false
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Button {
                        isShowingCreatePostView = true
                    } label: {
                        Text("ポスト")
                    }
                    .padding(5)
                    .foregroundStyle(.white)
                    .background(Color.blue)
                    .cornerRadius(10)
                    
                    NavigationLink {
                        ProfileView()
                    } label: {
                        Text("プロフィール")
                            .padding(5)
                            .foregroundStyle(.white)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    Button {
                        Task {
                            await logout()
                        }
                    } label: {
                        Text("ログアウト")
                            .padding(5)
                            .foregroundStyle(.white)
                            .background(Color.orange)
                            .cornerRadius(10)
                    }
                }
                List(viewModel.items.indices, id: \.self) { index in
                    PostListItem(post: viewModel.items[index])
                        .onAppear {
                            viewModel.loadMoreDataIfNeeded(currentIndex: index)
                        }
                }
            }
            .sheet(isPresented: $isShowingCreatePostView) {
                CreatePostView(isPresented: $isShowingCreatePostView)
            }
            // CreatePostViewが閉じられたときに更新
            .onChange(of: isShowingCreatePostView) { _, isShowing in
                if !isShowing {
                    viewModel.reload()
                }
            }
        }
        .navigationTitle(Text("タイムライン"))
        .overlay(
            // データの読み込み中にインジケーターを表示
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                }
            },
            alignment: .bottom
        )
    }
    
    func logout() async {
        let supabase = SupabaseService.instance
        do {
            try await supabase.logout()
            await MainActor.run {
                isLoggedIn = false
            }
        } catch {
            print(error)
        }
    }
}

// 無限スクロールビューの状態を管理するクラス
class InfiniteScrollViewModel: ObservableObject {
    @Published var items: [Post] = []
    @Published var isLoading = false

    private var currentPage = 1
    private var hasMoreData = true

    init() {
        loadMoreData()
    }

    // 状態を初期化して最新情報を取得
    func reload() {
        items = []
        isLoading = false
        currentPage = 1
        hasMoreData = true
        loadMoreData()
    }
    
    // 最後のデータ付近が表示されたら次のデータをロードする
    func loadMoreDataIfNeeded(currentIndex: Int) {
        guard !isLoading && hasMoreData else { return }

        // 最後の数アイテムに近づいたら次のデータを取得
        if currentIndex >= items.count - 3 {
            loadMoreData()
        }
    }

    // 次のデータをロードする(20個)
    private func loadMoreData() {
        guard !isLoading && hasMoreData else { return }
        
        isLoading = true

        Task {
            do {
                let supabase = SupabaseService.instance
                guard let startDate = items.isEmpty ? Date() : items.last?.created_at else { return }
                let newPosts = try await supabase.fetchPosts(startDate: startDate, count: 20)
                await MainActor.run {
                    self.items.append(contentsOf: newPosts)
                    self.isLoading = false
                    self.currentPage += 1
                }
            } catch {
                print(error)
            }
        }
    }
}

#Preview {
    TimelineView(isLoggedIn: .constant(true))
}
