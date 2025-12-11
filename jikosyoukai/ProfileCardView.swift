import SwiftUI

struct ProfileCardView: View {
    let profile: Profile
    
    // 背景色をランダムにする（画像がない人向け）
    let gradients: [Color] = [.blue, .purple, .orange, .pink, .green]
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // 1. 背景レイヤー (画像 or グラデーション)
            GeometryReader { proxy in
                if let urlString = profile.imageUrl, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .scaledToFill() // 画面いっぱいに埋める
                                .frame(width: proxy.size.width, height: proxy.size.height)
                                .clipped()
                                .overlay(Color.black.opacity(0.3)) // 文字を読みやすくするための暗幕
                        } else {
                            Rectangle().fill(Color.gray.opacity(0.3))
                        }
                    }
                } else {
                    // 画像がない人はグラデーション
                    LinearGradient(gradient: Gradient(colors: [gradients.randomElement()!, .black]), startPoint: .top, endPoint: .bottom)
                }
            }
            .ignoresSafeArea() // 画面の端まで広げる
            
            // 2. 情報レイヤー (手前に表示)
            VStack(alignment: .leading, spacing: 12) {
                Spacer() // 上を空ける
                
                // 名前と学部
                VStack(alignment: .leading, spacing: 4) {
                    Text(profile.name)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(radius: 2)
                    
                    // 学部などの基本情報があれば表示
                    if let faculty = profile.details["faculty"] {
                        Text(faculty)
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                
                // タグ (横スクロール)
                if !profile.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(profile.tags, id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.white.opacity(0.2))
                                    .foregroundColor(.white)
                                    .cornerRadius(20)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.white.opacity(0.5), lineWidth: 1)
                                    )
                            }
                        }
                    }
                }
                
                // 詳細データ (MBTIや趣味などをグリッド表示)
                let keyItems = ["mbti", "birthplace", "hobby", "instagram"] // 表示したい優先項目
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], alignment: .leading, spacing: 10) {
                    ForEach(masterProfileFields.filter { keyItems.contains($0.id) }) { field in
                        if let value = profile.details[field.id], !value.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: field.icon)
                                    .font(.caption)
                                Text(value)
                                    .font(.caption)
                                    .lineLimit(1)
                            }
                            .foregroundColor(.white)
                            .padding(6)
                            .background(Color.black.opacity(0.4))
                            .cornerRadius(8)
                        }
                    }
                }
                
                // ひとこと (Bio)
                if let bio = profile.details["bio"], !bio.isEmpty {
                    Text(bio)
                        .font(.body)
                        .foregroundColor(.white)
                        .lineLimit(3) // 長すぎたら省略
                        .padding(.top, 4)
                }
                
                Spacer().frame(height: 80) // 下のタブバー用スペース
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
}
