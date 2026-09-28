# GitWorktreeCleaner

macOS用git worktree管理アプリ(SwiftUI)。アプリ本体(`GitWorktreeCleaner.xcodeproj`)はほぼ空で、実装は `Packages/`(単一の`Package.swift`を持つSwiftPMローカルパッケージ)に置く。開発時は `make open` で `.xcworkspace` を開く。

## モジュール構成

新しいSPMパッケージは作らず、`Packages/Package.swift` にターゲットを足していく。

```
Models                      deps無し。Worktree, BranchList, GitWorktreeParser
Localization                deps無し。Constant(Localizable.xcstrings)
GitWorktreeServiceClient    → GitWorktreeServiceLive
UserDefaultsClient          → UserDefaultsLive
WorktreeFeature             Views + ViewModels。上記すべてに依存

ModelsTests                 → Models
GitWorktreeServiceLiveTests → GitWorktreeServiceLive, Models
WorktreeFeatureTests        → WorktreeFeature, Models, GitWorktreeServiceClient, UserDefaultsClient
```

- `WorktreeFeature` 配下は `<Name>/<Name>View.swift` + `<Name>/<Name>ViewModel.swift` のペアがフォルダ単位(`MainScreen/`, `RepositoryList/`, `WorktreeList/`, `MergeTargetBranchesEditor/`)。ViewModelを持たない部品(`StatusTagView`, `RepositoryItemView`, `WorktreeItemView`, `EmptyStateView`)はフォルダ化せずルート直下。命名規則は後述の「命名規則」参照。
- `WorktreeFeature` の `public` APIは `MainScreen` のみで、他はすべて `internal` にする。ViewModelのテスト(`WorktreeFeatureTests`)は同一パッケージ内の `.testTarget` から `@testable import WorktreeFeature` で書く。
- 新しい外部SPM依存を追加するときは、ネットワーク解決が発生する旨を伝えたうえでユーザーに確認してから `dependencies:` に足す。`swift-dependencies` の推移依存である `swift-issue-reporting` はトップレベルの `dependencies:` に明示追加済み(理由は「ビルド上の注意点」参照)。

## DIパターン(swift-dependencies): Client / Live

外部依存(git CLI, UserDefaultsなど)は**汎用の「Domain」「Data」モジュールにまとめず**、依存ごとに `<Name>Client`(IF)/`<Name>Live`(実装)の2モジュールに分割する。

- `<Name>Client`: `@DependencyClient` でクロージャの束を宣言し(型には必ず `@Sendable` を付ける)、`DependencyValues` extensionを生やす。エラー型・結果型もここに置く。
- `<Name>Live`: `extension <Name>Client: DependencyKey { public static let liveValue = ... }`。実際の重い処理(Process実行、UserDefaultsアクセスなど)はここに閉じ込める。

```swift
// Client
@DependencyClient
public struct FooClient: Sendable {
    public var doThing: @Sendable (_ input: String) throws -> String
}
extension FooClient: TestDependencyKey {
    public static let testValue = Self()
}
extension DependencyValues {
    public var fooClient: FooClient {
        get { self[FooClient.self] }
        set { self[FooClient.self] = newValue }
    }
}

// Live
extension FooClient: DependencyKey {
    public static let liveValue = Self(doThing: { ... })
}
```

ViewModel側は `@Dependency(\.fooClient) private var foo` で参照する。クロージャ呼び出しは常に位置引数(`foo.doThing(x)`)で、型宣言の `_ input:` ラベルは呼び出し時には使えない。

`GitWorktreeService` はこの形で `GitWorktreeServiceClient`/`GitWorktreeServiceLive` に分割済み。他の外部I/Oを追加するときもこのペアを踏襲する。

**注意**: `<Name>Live` はどのSwiftファイルからも `import` されない(`@Dependency` はClient型しか見ない)。それでも `WorktreeFeature` の `Package.swift` の `dependencies:` には明示的に含めること。含めないと `liveValue` の適合がリンクされず、実行時に `testValue`(unimplemented)にフォールバックする。

## テスト方針

- **テストの実行は `swift build`/`swift test` ではなく `xcodebuild test` で行う。**

  ```
  xcodebuild -workspace GitWorktreeCleaner.xcworkspace -scheme GitWorktreeCleaner -destination 'platform=macOS' test
  ```

  `GitWorktreeCleaner.xcscheme`(共有スキーム)のTest Actionに `WorktreeFeatureTests`/`ModelsTests`/`GitWorktreeServiceLiveTests`(いずれも`Packages/`側のSPMテストターゲット)と `GitWorktreeCleanerTests`/`GitWorktreeCleanerUITests` をすべて登録済みなので、このコマンド一発で全テストが実行される。`swift test` は `Packages/` 配下のSPMテストしか実行できずアプリ側テストが漏れるため使わない。
- ロジックはViewModel/Liveに置き、Viewの`@State`/body内に直書きしない。
- ViewModelのテストは `withDependencies { $0.xxxClient.method = { ... } } operation: { ... }` でモックを注入する(`Packages/Tests/WorktreeFeatureTests/`参照)。
- `@Sendable`クロージャ内でテスト側の可変状態を記録するときは `TestSupport.swift` の `Box<Value>`(`@unchecked Sendable`)を使う。
- `Task { ... }` の非同期更新を検証するときは同ファイルの `waitUntil(timeout:_:)` でポーリングする。
- 純粋な計算ロジック(gitを呼ばないもの)は専用の型に切り出してテストする(例: `GitWorktreeServiceLive/MergedWorktreePaths.swift`)。

## アーキテクチャ: 1 View : 1 ViewModel

- Viewは自分専用の `@StateObject` ViewModelを1つだけ持つ。**他のViewが所有するViewModelインスタンスを共有しない。**
- 複数の子View(例: サイドバーと詳細ペイン)が同じ状態(選択中のリポジトリなど)を必要とする場合、その状態は親のコーディネーター(`MainScreen`)が自分のViewModel(`MainViewModel`)に持ち、`Binding`/クロージャで子に渡す。
- View+ViewModelのペアは `WorktreeFeature/<Name>/` フォルダにまとめる(例: `RepositoryList/RepositoryListView.swift` + `RepositoryList/RepositoryListViewModel.swift`)。ViewModelを持たない部品(`StatusTagView`, `RepositoryItemView`, `WorktreeItemView`, `EmptyStateView`)はフォルダ化せずルート直下に置く。
- 「Store」はDIのClient/Live命名(`UserDefaultsClient`など)と衝突しやすいので、ViewModelの名前としては避ける。

### 命名規則

- **画面単位は `Screen`、部品単位は `View`。** 最上位コーディネーター(`MainScreen`)と、独自ViewModelを持つ自己完結したモーダル/シート(`MergeTargetBranchesEditorScreen`)は `Screen`。それ以外の、他のView/Screenの中で使われる部品は `View` で統一する(`RepositoryItemView`, `StatusTagView`)。「Row」「Tag」だけで終わらせない。
- **複数形の裸の名前は避け `<単数形>List` にする。** コレクションを表すプロパティ・引数・クロージャは `repositories`→`repositoryList`、`mergeTargetBranches`→`mergeTargetBranchList` のように統一する(Array/Set問わず)。例外は動詞+目的語の関数名(`listWorktrees`, `persistRepositories`)と既存のLocalization API(`mergeTargetSummary(branches:)`)。迷ったら「一覧を表す名詞かどうか」で判断する。
- **UserDefaultsのキー文字列はリネームしない。** Swift定数名(`repositoriesKey`→`repositoryListKey`)は上記ルールに合わせてよいが、文字列リテラルの値(`"GitWorktreeCleaner.repositories"`)を変えると既存ユーザーの永続化データが読めなくなるので変更しない。

## ビルド上の注意点

- `xcodebuild`(Xcode初回オープンも同様)はswift-dependenciesのマクロ(`DependenciesMacrosPlugin`)の信頼確認を求める。ヘッドレスビルドでは `-skipMacroValidation` を付ける(`Makefile` の `zip` 参照)。
- `xcodebuild test` は、swift-dependencies経由の深い推移依存(`IssueReporting`)がXcodeの動的パッケージフレームワークとリンクできず失敗することがある(`swift build`/`swift test`とアプリ本体ビルドは問題ない)。対処済み: `Packages/Package.swift` の `dependencies:` に `swift-issue-reporting` をトップレベルで追加し、`@DependencyClient` マクロを使う `GitWorktreeServiceClient`/`UserDefaultsClient` ターゲットへ `.product(name: "IssueReporting", package: "swift-issue-reporting")` を明示的に足すことでリンクエラーは解消する(重複ターゲット名の衝突などは発生しない)。
- `xcodebuild test` でSPMパッケージ側のテスト(`WorktreeFeatureTests`など)も実行するには、対象のテストターゲットをXcodeスキームのTest Actionに含める必要がある。ローカルパッケージのターゲットは自動生成スキームではテスト対象にならないため、共有スキーム(`GitWorktreeCleaner.xcodeproj/xcshareddata/xcschemes/GitWorktreeCleaner.xcscheme`)を作成し、`TestAction`の`Testables`に `container:Packages` 参照で明示的に追加している。新しいSPMテストターゲットを足したときは、このスキームファイルにも `TestableReference` を追加すること。
- `xcodebuild` を実行すると、`<Name>View.swift`+`<Name>ViewModel.swift` のペアがXcodeによって勝手にサブフォルダへ移動され、gitインデックスにもステージされることがある(`swift build`では起きない)。実行のたびに `git status` とファイル配置を確認する。
- ローカルパッケージ解決は `.xcodeproj` 単体でも動くが、`Packages/` をナビゲータに出すため通常は `.xcworkspace` を開く。

## その他

- コミットメッセージは日本語・prefixなし・粗めの粒度(例: 「マージ済みworktreeの検出・削除推奨機能を実装」)。詳細は `/commit` スキル参照。
