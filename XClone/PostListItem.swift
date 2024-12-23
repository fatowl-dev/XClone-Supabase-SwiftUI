//
//  PostListItem.swift
//  XClone
//
//  Created by fatowl on 2024/12/21.
//

import SwiftUI

struct PostListItem: View {
    let post : Post
    @State var nickname = ""
    @State var content = ""
    @State var createdAt = ""
    @State var isLiked = false
    @State var likeCount = 0
    
    init(post: Post) {
        self.post = post
    }
    
    var body: some View {
        VStack {
            //ニックネームと投稿時間
            HStack {
                Text("\(nickname)")
                    .foregroundStyle(.blue)
                    .fontWeight(.bold)
                Spacer()
                Text("\(createdAt)")
                    .foregroundStyle(.blue)
                    .fontWeight(.thin)
            }
            //本文
            HStack {
                Text(content)
                Spacer()
            }
            //画像
            if let imageUrl = post.image_url {
                AsyncImage(url: URL(string: imageUrl)) { phase in
                    phase.image?.resizable()
                }
                .scaledToFit()
            }
            // いいねボタン
            HStack {
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .foregroundStyle(.red).onTapGesture {
                        Task {
                            await likeTapped()
                        }
                    }
                Text("\(likeCount)")
                    .foregroundStyle(.red)
                Spacer()
            }
            .padding()
        }
        .onAppear {
            setup()
        }
    }
    
    // 初期状態を作る
    func setup() {
        let supabase = SupabaseService.instance
        
        // 本文
        content = post.content
        
        // 投稿時間
        guard let createdAt = post.created_at else { return }
        self.createdAt = createdAt.formatted()

        // ユーザーのニックネーム
        guard let userId = post.user_id else { return }
        Task {
            do {
                let profile = try await supabase.getProfile(userId: userId)
                if let nickname = profile?.nickname {
                    await MainActor.run {
                        self.nickname = nickname
                    }
                } else {
                    await MainActor.run {
                        self.nickname = "名無しさん"
                    }
                }
            } catch {
                print(error)
            }
        }
        
        //　いいねの状態
        guard let postId = post.id else { return }
        Task {
            do {
                guard let currentUserId = try await supabase.getCurrentUser()?.id.uuidString else { return }
                isLiked = try await supabase.isLiked(postId: postId, userId: currentUserId)
                likeCount = try await supabase.getLikeCount(postId: postId)
            } catch {
                print(error)
            }
        }
    }
    
    // いいねボタンをタップしたときの処理
    func likeTapped() async {
        let supabase = SupabaseService.instance
        
        if isLiked {
            do {
                // いいねの消去
                let user = try await supabase.getCurrentUser()
                guard let userId = user?.id.uuidString else {
                    print("could not get current user")
                    return
                }
                
                guard let postId = post.id else {
                    // ここはありえないはず
                    print("post id is nil")
                    return
                }
                
                try await supabase.removeLike(postId: postId, userId: userId)
                likeCount = try await supabase.getLikeCount(postId: postId)
                isLiked = false
            } catch {
                print(error)
            }
        } else {
            // いいねの追加
            do {
                let user = try await supabase.getCurrentUser()
                guard let userId = user?.id.uuidString else {
                    print("could not get current user")
                    return
                }
                
                guard let postId = post.id else {
                    // ここはありえないはず
                    print("post id is nil")
                    return
                }
                
                try await supabase.addLike(postId: postId, userId: userId)
                likeCount = try await supabase.getLikeCount(postId: postId)
                isLiked = true
            } catch {
                print(error)
            }

        }
    }
}

#Preview {
    PostListItem(post: Post(id: 0, user_id: "userid", content: "test", created_at: Date()))
}
