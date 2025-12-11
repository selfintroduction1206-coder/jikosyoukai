import SwiftUI
import FirebaseFirestore

struct CreateGroupView: View {
    @Environment(\.dismiss) var dismiss // 画面を閉じる用
    
    @State private var groupName = ""
    // 必須に選ばれた項目のIDを保存するセット
    @State private var selectedRequiredIds: Set<String> = []
    
    @State private var createdGroupId: String? = nil // 作成完了後に表示するID
    @State private var showResult = false
    
    var body: some View {
        NavigationView {
            Form {
                // 1. グループ名の入力
                Section(header: Text("グループ情報")) {
                    TextField("グループ名 (例: 〇〇新歓)", text: $groupName)
                }
                
                // 2. 必須項目の選択
                Section(header: Text("必須項目の設定"), footer: Text("チェックを入れた項目が、メンバー入力時に「必須」になります。それ以外は「任意」として表示されます。")) {
                    
                    // カテゴリごとに分けて表示
                    ForEach(Dictionary(grouping: masterProfileFields, by: { $0.category }).sorted(by: { $0.key < $1.key }), id: \.key) { category, fields in
                        
                        DisclosureGroup(category) {
                            ForEach(fields) { field in
                                Toggle(isOn: Binding(
                                    get: { selectedRequiredIds.contains(field.id) },
                                    set: { isSelected in
                                        if isSelected {
                                            selectedRequiredIds.insert(field.id)
                                        } else {
                                            selectedRequiredIds.remove(field.id)
                                        }
                                    }
                                )) {
                                    HStack {
                                        Image(systemName: field.icon)
                                            .frame(width: 24)
                                            .foregroundColor(.blue)
                                        Text(field.label)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // 3. 作成ボタン
                Section {
                    Button(action: createGroup) {
                        Text("グループを作成してIDを発行")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                    }
                    .listRowBackground(Color.blue)
                    .disabled(groupName.isEmpty)
                }
            }
            .navigationTitle("グループ作成")
            .alert("作成完了", isPresented: $showResult) {
                // 1. コピーボタン (押すとクリップボードにコピーして画面を閉じます)
                Button("合言葉をコピー") {
                    if let id = createdGroupId {
                        UIPasteboard.general.string = id
                    }
                    dismiss()
                }
                
                // 2. 普通の閉じるボタン
                Button("閉じる") { dismiss() }
            } message: {
                Text("グループを作成しました！\n\n合言葉: \(createdGroupId ?? "エラー")\n\nこの合言葉をメンバーに共有してください。")
            }
        }
    }
    
    // --- グループ作成ロジック ---
    func createGroup() {
        let db = Firestore.firestore()
        
        // データの作成
        let newGroup = Group(
            name: groupName,
            ownerId: UIDevice.current.identifierForVendor?.uuidString ?? "unknown",
            requiredFieldIds: Array(selectedRequiredIds),
            createdAt: Date()
        )
        
        do {
            // Firestoreに追加
            let ref = try db.collection("groups").addDocument(from: newGroup)
            
            // 成功したらIDを控えてアラートを出す
            createdGroupId = ref.documentID
            showResult = true
            
        } catch {
            print("作成エラー: \(error.localizedDescription)")
        }
    }
}

#Preview {
    CreateGroupView()
}
