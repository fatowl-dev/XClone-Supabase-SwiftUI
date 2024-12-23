//
//  Models.swift
//  XClone
//
//  Created by fatowl on 2024/12/21.
//
import Foundation

// ポストのデータを格納する
struct Post: Codable {
    var id: Int?
    var user_id: String?
    var content: String
    var created_at: Date?
    var image_url: String?
}

// ユーザープロフィール
struct Profile: Codable {
    var id: Int?
    var user_id: String
    var nickname: String?
    var created_at: Date?
    var updated_at: Date?
}

// いいね
struct Like: Codable {
    var id: Int?
    var post_id: Int?
    var user_id: String?
    var created_at: Date?
}
