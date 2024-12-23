//
//  SupabaseConfig.swift
//  XClone
//
//  Created by fatowl on 2024/12/21.
//
import Foundation

struct SupabaseConfig {
    let apiKey: String
    let projectUrl: URL
    
    init() {
        // プロジェクト内のplistのパスを取得
        guard let path = Bundle.main.path(forResource: "supabase_config", ofType: "plist") else {
            fatalError("supabase_config.plist not found")
        }
        
        // plistファイルを読み込む
        guard let xml = FileManager.default.contents(atPath: path) else {
            fatalError( "Failed to load supabase_config.plist")
        }
        
        // plistの内容をパースして辞書型で取得
        guard let data = try? PropertyListSerialization.propertyList(from: xml, options: [], format: nil) as? [String: Any] else {
            fatalError("Failed to parse supabase_config.plist")
        }
        
        guard let unwrappedApiKey = data["APIKey"] as? String else {
            fatalError( "APIKey not found in supabase_config.plist")
        }
        
        guard let unwrappedProjectUrl = data["ProjectURL"] as? String else {
            fatalError( "ProjectURL not found in supabase_config.plist")
        }
        
        guard let url = URL(string: unwrappedProjectUrl) else {
            fatalError( "ProjectURL is not URL")
        }
        
        self.apiKey = unwrappedApiKey
        self.projectUrl = url
    }
}

