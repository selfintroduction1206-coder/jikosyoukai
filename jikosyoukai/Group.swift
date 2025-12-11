import Foundation
import FirebaseFirestore

// --- A. 標準項目のマスター定義 ---
struct ProfileField: Identifiable, Hashable {
    let id: String      // システム保存用のキー (例: "mbti")
    let label: String   // 画面表示名 (例: "MBTI")
    let icon: String    // SF Symbolsのアイコン名
    let category: String // カテゴリ (表示のグループ分け用)
}

// 網羅的なマスターリスト
let masterProfileFields: [ProfileField] = [
    // MARK: - 基本情報
    ProfileField(id: "faculty", label: "学部・学科", icon: "building.columns", category: "基本"),
    ProfileField(id: "grade", label: "学年", icon: "graduationcap", category: "基本"),
    ProfileField(id: "age", label: "年齢", icon: "number.circle", category: "基本"),
    ProfileField(id: "birthday", label: "誕生日", icon: "calendar", category: "基本"),
    ProfileField(id: "blood_type", label: "血液型", icon: "drop.fill", category: "基本"),
    ProfileField(id: "birthplace", label: "出身地", icon: "map", category: "基本"),
    ProfileField(id: "residence", label: "居住形態 (一人暮らし等)", icon: "house", category: "基本"),
    ProfileField(id: "height", label: "身長", icon: "ruler", category: "基本"),
    ProfileField(id: "circle", label: "サークル・部活", icon: "sportscourt", category: "基本"),
    ProfileField(id: "parttime", label: "バイト・職業", icon: "banknote", category: "基本"),

    // MARK: - 診断・タイプ (Z世代トレンド)
    ProfileField(id: "mbti", label: "MBTI (16タイプ)", icon: "sparkles", category: "診断・タイプ"),
    ProfileField(id: "enneagram", label: "エニアグラム", icon: "9.circle", category: "診断・タイプ"),
    ProfileField(id: "personal_color", label: "パーソナルカラー", icon: "paintpalette", category: "診断・タイプ"),
    ProfileField(id: "skeleton", label: "骨格診断", icon: "figure.stand", category: "診断・タイプ"),
    ProfileField(id: "zodiac", label: "星座", icon: "star", category: "診断・タイプ"),
    ProfileField(id: "animal_fortune", label: "動物占い", icon: "pawprint", category: "診断・タイプ"),
    ProfileField(id: "bunkei_rikei", label: "文系 vs 理系", icon: "book.closed", category: "診断・タイプ"),

    // MARK: - ライフスタイル・価値観
    ProfileField(id: "morning_night", label: "朝型・夜型", icon: "sun.max", category: "ライフスタイル"),
    ProfileField(id: "holiday", label: "休日の過ごし方", icon: "chair.lounge", category: "ライフスタイル"),
    ProfileField(id: "reply_speed", label: "返信速度", icon: "bubble.left.and.bubble.right", category: "ライフスタイル"),
    ProfileField(id: "alcohol", label: "お酒", icon: "wineglass", category: "ライフスタイル"),
    ProfileField(id: "smoking", label: "喫煙", icon: "lungs", category: "ライフスタイル"),
    ProfileField(id: "food_like", label: "好きな食べ物", icon: "hand.thumbsup", category: "ライフスタイル"),
    ProfileField(id: "food_dislike", label: "嫌いな食べ物", icon: "hand.thumbsdown", category: "ライフスタイル"),
    ProfileField(id: "money_sense", label: "金銭感覚 (奢り/割り勘)", icon: "yensign.circle", category: "ライフスタイル"),
    ProfileField(id: "footwork", label: "フットワークの軽さ", icon: "figure.run", category: "ライフスタイル"),

    // MARK: - 推し・カルチャー
    ProfileField(id: "oshi", label: "最推し", icon: "heart.fill", category: "推し・趣味"),
    ProfileField(id: "artist", label: "好きなアーティスト", icon: "music.mic", category: "推し・趣味"),
    ProfileField(id: "youtuber", label: "好きなYouTuber", icon: "play.rectangle.fill", category: "推し・趣味"),
    ProfileField(id: "game", label: "プレイ中のゲーム", icon: "gamecontroller", category: "推し・趣味"),
    ProfileField(id: "movie", label: "人生最高の映画", icon: "film", category: "推し・趣味"),
    ProfileField(id: "sauna", label: "サウナ・銭湯", icon: "flame", category: "推し・趣味"),
    ProfileField(id: "cafe", label: "よく行くカフェ・スタバ", icon: "cup.and.saucer", category: "推し・趣味"),
    
    // MARK: - SNS・リンク
    ProfileField(id: "instagram", label: "Instagram ID", icon: "camera", category: "SNS・リンク"),
    ProfileField(id: "x_twitter", label: "X (Twitter) ID", icon: "at", category: "SNS・リンク"),
    ProfileField(id: "tiktok", label: "TikTok ID", icon: "music.note", category: "SNS・リンク"),
    ProfileField(id: "github", label: "GitHub ID", icon: "terminal", category: "SNS・リンク"),
    ProfileField(id: "portfolio", label: "ポートフォリオURL", icon: "link", category: "SNS・リンク"),

    // MARK: - スキル・資格
    ProfileField(id: "programming", label: "使用言語 (Python等)", icon: "desktopcomputer", category: "スキル"),
    ProfileField(id: "tools", label: "使えるツール (Adobe等)", icon: "pencil.and.outline", category: "スキル"),
    ProfileField(id: "qualification", label: "保有資格", icon: "medal", category: "スキル"),

    // MARK: - アイスブレイク (大喜利)
    ProfileField(id: "manual", label: "私の取扱説明書", icon: "book", category: "Q&A"),
    ProfileField(id: "zombie", label: "ゾンビが溢れたらどうする？", icon: "exclamationmark.shield", category: "Q&A"),
    ProfileField(id: "last_meal", label: "地球最後の日何食べる？", icon: "fork.knife.circle", category: "Q&A"),
    ProfileField(id: "fetish", label: "実は〇〇フェチ", icon: "eye", category: "Q&A"),
    ProfileField(id: "dream", label: "将来の夢", icon: "cloud", category: "Q&A")
]

// --- B. グループの設計図 ---
struct Group: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var ownerId: String
    var requiredFieldIds: [String] // 必須項目のIDリスト
    var createdAt: Date
}
