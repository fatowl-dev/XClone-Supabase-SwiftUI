//
//  SupabaseService.swift
//  XClone
//
//  Created by fatowl on 2024/12/21.
//
import Foundation
import Supabase
import PhotosUI


// Supabaseとやり取りするシングルトンクラス
final class SupabaseService {
    static let instance = SupabaseService()
    
    private let supabase: SupabaseClient
    private let config = SupabaseConfig()
    
    private init() {
        supabase = SupabaseClient(
            supabaseURL: config.projectUrl,
            supabaseKey: config.apiKey
        )
    }
    
    // Dateがうまくデコードできないので対応するデコーダ
    private func customDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()

        // 小数点がある場合のフォーマッタ
        let isoFormatterWithFraction = ISO8601DateFormatter()
        isoFormatterWithFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        // 小数点がない場合のフォーマッタ
        let isoFormatterWithoutFraction = ISO8601DateFormatter()
        isoFormatterWithoutFraction.formatOptions = [.withInternetDateTime]

        // カスタムデコード
        decoder.dateDecodingStrategy = .custom { decoder -> Date in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            // 小数秒ありのフォーマッターでデコードを試みる
            if let date = isoFormatterWithFraction.date(from: dateString) {
                return date
            }

            // 小数秒なしのフォーマッターでデコードを試みる
            if let date = isoFormatterWithoutFraction.date(from: dateString) {
                return date
            }

            // どちらのフォーマットでもデコードできない場合はエラー
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format")
        }
        return decoder
    }

    func loginWithEmail(email: String, password: String)  async throws {
        try await supabase.auth.signIn(email: email, password: password)
    }

    func registerWithEmail(email: String, password: String) async throws {
        try await supabase.auth.signUp(email: email, password: password)
    }

    func logout() async throws {
        try await supabase.auth.signOut()
    }

    func getCurrentUser() async throws -> User? {
        return supabase.auth.currentUser
    }

    func addPost(userId: String, content: String, imageUrl: String?) async throws {
        let post = Post(id: nil, user_id: userId, content: content, created_at: nil, image_url: imageUrl)
        try await supabase.from("post")
            .insert(post)
            .execute()
    }
    
    func addProfile(userId: String) async throws {
        let profile = Profile(id: nil, user_id: userId, nickname: nil, created_at: nil, updated_at: nil)
        try await supabase.from("profile")
            .insert(profile)
            .execute()
    }
        
    func updateProfile(userId: String, nickname: String) async throws {
        let data: [String: String] = [
            "nickname": nickname,
            // [String: Any]型だとエンコードできないためsupabaseが対応しているISO8601Formatの文字列に変換する
            "updated_at": Date().ISO8601Format()
        ]
        try await supabase.from("profile")
            .update(data)
            .eq("user_id", value: userId)
            .execute()
    }
    
    func getProfile(userId: String) async throws -> Profile? {
        let data = try await supabase.from("profile")
            .select()
            .eq("user_id", value: userId)
            .execute()
            .data
                
        let decoder = customDecoder()
        let profiles = try decoder.decode([Profile].self, from: data)
        if profiles.isEmpty {
            return nil
        }
    
        return profiles[0]
    }
    
    func addLike(postId: Int, userId: String) async throws {
        try await supabase.from("like")
            .insert(Like(post_id: postId, user_id: userId))
            .execute()
    }
    
    func removeLike(postId: Int, userId: String) async throws {
        try await supabase.from("like")
            .delete()
            .eq("post_id", value: postId)
            .eq("user_id", value: userId)
            .execute()
    }
    
    func getLikeCount(postId: Int) async throws -> Int {
        let response = try await supabase.from("like")
            .select(count: .exact)
            .eq("post_id", value: postId)
            .execute()

        guard let count = response.count else {
            return 0
        }
        
        return count
    }
    
    // 指定したユーザーがいいねしているかどうかをチェック
    func isLiked(postId: Int, userId: String) async throws -> Bool {
        let response = try await supabase.from("like")
            .select(count: .exact)
            .eq("post_id", value: postId)
            .eq("user_id", value: userId)
            .execute()
        
        if let count = response.count {
            if count > 0 {
                return true
            }
        }
        return false
    }
    
    // 指定した時間以前のポストデータを指定個数分だけ取得する
    func fetchPosts(startDate: Date, count: Int) async throws -> [Post] {
        let data = try await supabase.from("post")
            .select()
            .lte("created_at", value: startDate)
            .order("created_at", ascending: false)
            .limit(count)
            .execute()
            .data

        let decoder = customDecoder()
        let posts = try decoder.decode([Post].self, from: data)
        
        return posts
    }
    
    
    // 画像をアップロードしてURLを返す
    func uploadImage(image: UIImage) async throws -> String {
        // 大きすぎるとサーバーの制限でアップロードできないので
        // 長辺に最大値を指定して比率を変えずにダウンスケールする
        // 論理サイズなので端末によって解像度が変わってしまうバグが有る
        let maxLength: Double = 200
        var uploadImage = image
        if image.size.width > maxLength || image.size.height > maxLength {
            var scaledImageSize = CGSize()
            let rate = Double(image.size.width) / Double(image.size.height)
            
            if rate > 1.0 {
                scaledImageSize.width = maxLength
                scaledImageSize.height = scaledImageSize.width / rate
            } else {
                scaledImageSize.height = maxLength
                scaledImageSize.width = scaledImageSize.height * rate
            }
            
            let renderer = UIGraphicsImageRenderer(size: scaledImageSize)
            uploadImage = renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: scaledImageSize))
            }
        }

        // 画像をJPEGデータに変換
        guard let imageData = uploadImage.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "ImageError", code: 1, userInfo: [NSLocalizedDescriptionKey: "画像データの変換に失敗しました"])
        }
        
        // バケットを参照
        let storage = supabase.storage.from("pictures")
        
        // ファイルパスを指定
        let fileName = UUID().uuidString
        let filePath = "uploads/\(fileName)"
        
        // アップロード処理
        try await storage.upload(filePath, data: imageData, options: FileOptions(contentType: "image/jpeg"))
        
        
        return "\(config.projectUrl)/storage/v1/object/public/pictures/\(filePath)"
    }


}
