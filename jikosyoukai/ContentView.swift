import SwiftUI
import FirebaseFirestore
import FirebaseStorage
import CoreImage.CIFilterBuiltins

struct ContentView: View {
    // ▼▼▼ Web公開URL (あなたの環境に合わせてください) ▼▼▼
    let baseURL = "https://jikosyoukai-b263c.web.app"
    
    @AppStorage("currentGroupId") var currentGroupId = ""
    @State private var tempGroupId = ""
    @State private var showCreateGroup = false
    
    // ★現在のグループの設定データ（必須項目を知るため）
    @State private var currentGroupConfig: Group?
    
    // データ入力用
    @State private var name = ""
    @State private var inputTag = ""
    @State private var tags: [String] = []
    // ★追加: 詳細項目の入力値をまとめて持つ辞書
    @State private var detailInputs: [String: String] = [:]
    
    // 画像用
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var isUploading = false
    
    // データ表示用
    @State private var profiles: [Profile] = []
    @State private var showAlert = false
    @State private var showQRCode = false
    
    var body: some View {
        if currentGroupId.isEmpty {
            loginView
        } else {
            mainView
        }
    }
    
    // MARK: - A. ログイン画面
    var loginView: some View {
        VStack(spacing: 20) {
            Text("Jikosyoukai")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("グループの合言葉を入力").foregroundColor(.gray)
            TextField("合言葉", text: $tempGroupId)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
                .autocapitalization(.none)
            Button("参加する") {
                if !tempGroupId.isEmpty {
                    currentGroupId = tempGroupId
                    // 参加時にグループ情報を取得する
                    fetchGroupInfo()
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.horizontal)
            
            Divider().padding(.vertical)
            Text("または").font(.caption).foregroundColor(.gray)
            Button("新しいグループを作成する (ホスト)") { showCreateGroup = true }
                .foregroundColor(.blue).underline()
        }
        .sheet(isPresented: $showCreateGroup) { CreateGroupView() }
    }
    
    // MARK: - B. メイン画面 (動的フォーム)
    var mainView: some View {
        NavigationView {
            Form {
                // 1. 招待エリア
                Section(header: Text("招待")) {
                    Button(action: { showQRCode = true }) {
                        HStack { Image(systemName: "qrcode"); Text("QRコードを表示") }
                    }
                }
                
                // 2. プロフィール作成エリア
                Section(header: Text("カードを作成（\(currentGroupConfig?.name ?? currentGroupId)）")) {
                    // 画像選択
                    Button(action: { showImagePicker = true }) {
                        HStack {
                            if let image = selectedImage {
                                Image(uiImage: image).resizable().scaledToFill().frame(width: 60, height: 60).clipShape(Circle())
                            } else {
                                Image(systemName: "camera.circle.fill").resizable().frame(width: 60, height: 60).foregroundColor(.gray)
                            }
                            Text(selectedImage == nil ? "写真を追加" : "写真を変更")
                        }
                    }
                    
                    // --- 必須・基本項目 ---
                    TextField("名前 (必須)", text: $name)
                    
                    // --- ★ここが動的フォームの核心！ ---
                    // カテゴリごとに整理して表示
                    ForEach(Dictionary(grouping: masterProfileFields, by: { $0.category }).sorted(by: { $0.key < $1.key }), id: \.key) { category, fields in
                        DisclosureGroup(category) {
                            ForEach(fields) { field in
                                // この項目が、今のグループで「必須」かどうか判定
                                let isRequired = currentGroupConfig?.requiredFieldIds.contains(field.id) ?? false
                                
                                HStack {
                                    // アイコンとラベル
                                    Image(systemName: field.icon).frame(width: 20).foregroundColor(.gray)
                                    if isRequired {
                                        Text(field.label).bold() + Text(" *").foregroundColor(.red)
                                    } else {
                                        Text(field.label).foregroundColor(.primary)
                                    }
                                    
                                    Spacer()
                                    
                                    // 入力欄 (Dictionaryにバインディング)
                                    TextField("入力", text: Binding(
                                        get: { detailInputs[field.id] ?? "" },
                                        set: { detailInputs[field.id] = $0 }
                                    ))
                                    .multilineTextAlignment(.trailing)
                                }
                            }
                        }
                    }
                    
                    // 自由タグ入力
                    HStack {
                        TextField("自由タグ追加 (例: #サウナ)", text: $inputTag)
                        Button(action: addTag) { Image(systemName: "plus.circle.fill") }.disabled(inputTag.isEmpty)
                    }
                    if !tags.isEmpty {
                        ScrollView(.horizontal) {
                            HStack { ForEach(tags, id: \.self) { tag in Text("#\(tag)").padding(5).background(Color.blue.opacity(0.1)).cornerRadius(5) } }
                        }
                    }
                    
                    // 保存ボタン
                    if isUploading {
                        ProgressView("送信中...")
                    } else {
                        Button("保存して参加") {
                            // バリデーション: 必須項目が埋まっているかチェック
                            if validateRequiredFields() {
                                if let image = selectedImage {
                                    uploadImageAndSaveProfile(image: image)
                                } else {
                                    saveProfile(imageUrl: nil)
                                }
                            }
                        }
                        .disabled(name.isEmpty)
                    }
                }
                
                // 3. リスト表示エリア
                Section(header: Text("メンバーを見る")) {
                    NavigationLink(destination: TikTokSwipeView(profiles: profiles)) {
                        HStack {
                            Image(systemName: "play.rectangle.fill")
                                .foregroundColor(.pink)
                            Text("スワイプモードで見る")
                                .font(.headline)
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                Section {
                    Button("ログアウト") {
                        currentGroupId = ""
                        currentGroupConfig = nil
                        profiles = []
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("メンバー一覧")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showQRCode = true }) { Image(systemName: "qrcode") }
                }
            }
            .onAppear {
                if !currentGroupId.isEmpty {
                    fetchGroupInfo() // グループ設定を取得
                    fetchProfiles()  // メンバーリストを取得
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("完了"), message: Text("保存しました"), dismissButton: .default(Text("OK")))
            }
            .sheet(isPresented: $showQRCode) {
                VStack(spacing: 20) {
                    Text("参加用QRコード").font(.headline)
                    Text(currentGroupConfig?.name ?? currentGroupId).font(.subheadline)
                    if let qrImage = generateQRCode(from: "\(baseURL)/?g=\(currentGroupId)") {
                        Image(uiImage: qrImage).interpolation(.none).resizable().scaledToFit().frame(width: 250, height: 250)
                    }
                    Button("閉じる") { showQRCode = false }
                }.padding()
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage)
            }
        }
    }
    
    // MARK: - ロジック部分
    
    // グループの設定（必須項目など）を取得
    func fetchGroupInfo() {
        let db = Firestore.firestore()
        db.collection("groups").document(currentGroupId).getDocument { doc, error in
            if let doc = doc, doc.exists {
                self.currentGroupConfig = try? doc.data(as: Group.self)
            } else {
                // グループが見つからない場合（古い合言葉など）
                print("Group not found")
            }
        }
    }
    
    // バリデーションチェック
    func validateRequiredFields() -> Bool {
        guard let config = currentGroupConfig else { return true }
        
        for fieldId in config.requiredFieldIds {
            if (detailInputs[fieldId] ?? "").isEmpty {
                // 名前以外の必須項目が空の場合（本来はアラートを出すべきですが簡易的にprint）
                print("必須項目が未入力です: \(fieldId)")
                return false
            }
        }
        return true
    }
    
    func addTag() { if !inputTag.isEmpty { tags.append(inputTag); inputTag = "" } }
    
    func uploadImageAndSaveProfile(image: UIImage) {
        isUploading = true
        guard let imageData = image.jpegData(compressionQuality: 0.5) else { return }
        let storageRef = Storage.storage().reference().child("images/\(UUID().uuidString).jpg")
        storageRef.putData(imageData, metadata: nil) { _, error in
            if let _ = error { isUploading = false; return }
            storageRef.downloadURL { url, _ in
                guard let downloadURL = url else { return }
                saveProfile(imageUrl: downloadURL.absoluteString)
            }
        }
    }
    
    func saveProfile(imageUrl: String?) {
        let db = Firestore.firestore()
        let newProfile = Profile(
            name: name,
            imageUrl: imageUrl,
            groupId: currentGroupId,
            createdAt: Date(),
            details: detailInputs, // ★詳細項目を保存
            tags: tags
        )
        
        do {
            try db.collection("profiles").addDocument(from: newProfile)
            showAlert = true
            // リセット
            name = ""; tags = []; detailInputs = [:]; selectedImage = nil; isUploading = false
        } catch { isUploading = false }
    }
    
    func fetchProfiles() {
        let db = Firestore.firestore()
        db.collection("profiles").whereField("groupId", isEqualTo: currentGroupId).order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, _ in
                guard let documents = snapshot?.documents else { return }
                self.profiles = documents.compactMap { try? $0.data(as: Profile.self) }
            }
    }
    
    func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: String.Encoding.ascii)
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            filter.setValue("M", forKey: "inputCorrectionLevel")
            if let outputImage = filter.outputImage {
                let transform = CGAffineTransform(scaleX: 10, y: 10)
                let scaledImage = outputImage.transformed(by: transform)
                let context = CIContext()
                if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) { return UIImage(cgImage: cgImage) }
            }
        }
        return nil
    }
}

#Preview {
    ContentView()
}
