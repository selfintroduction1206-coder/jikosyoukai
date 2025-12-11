import SwiftUI

struct TikTokSwipeView: View {
    let profiles: [Profile]
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0) { // 隙間なく並べる
                ForEach(profiles) { profile in
                    ProfileCardView(profile: profile)
                        .containerRelativeFrame(.vertical) // 1つのViewを画面の高さに合わせる
                }
            }
        }
        .scrollTargetBehavior(.paging) // ページ単位でスナップさせる魔法の修飾子
        .ignoresSafeArea()
    }
}
