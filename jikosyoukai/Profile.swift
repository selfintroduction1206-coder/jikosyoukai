import Foundation
import FirebaseFirestore // Firestoreを使えるようにする

// ユーザーの自己紹介データ
struct Profile: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String            // 名前（これだけはシステム必須）
    var imageUrl: String?       // アイコン画像
    var groupId: String         // 所属グループ
    var createdAt: Date         // 作成日
    
    // ★追加: その他の詳細データ（MBTIや学部など全部ここに入れます）
    // キー: "mbti", 値: "ENTP" のように保存されます
    var details: [String: String]
    
    // 自由タグ（ハッシュタグ用）は残しておくと便利です
    var tags: [String]
}
