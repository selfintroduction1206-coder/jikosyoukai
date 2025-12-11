import SwiftUI
import FirebaseCore // ← 1. 追加: ライブラリを読み込む

// 2. 追加: アプリ起動時にFirebaseを叩き起こすためのクラス（AppDelegate）
class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    
    print("🚀 アプリが起動しました！設定を開始します...") // ← 追加
    
    FirebaseApp.configure()
    
    print("🔥 Firebaseの設定が完了しました！") // ← 追加
    
    return true
  }
}

@main
struct SelfIntroApp: App {
    // 3. 追加: 上で作ったクラスをアプリに登録する
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
