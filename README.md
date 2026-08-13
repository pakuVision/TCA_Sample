# TCASample

[pointfreeco/swift-composable-architecture](https://github.com/pointfreeco/swift-composable-architecture) の公式サンプルを実際に参照しながら、
写経 → 改変 → テスト作成、という流れで TCA の基本を理解するために作った学習用リポジトリです。

「動くものをコピーする」だけで終わらせないために、各 Reducer には
**なぜその API を使うのか** をコメントとして残しながら進めました。

- Swift 6 / SwiftUI
- The Composable Architecture 1.x (Observation ベースの API)
- Swift Testing (`@Test` / `TestStore`)

`TCASampleApp.swift` のルートを差し替えることで、各サンプルを個別に起動できます。

---

## サンプル一覧と、そこで学んだこと

| サンプル | 主なテーマ |
| --- | --- |
| `Samples/Counter` | `@Reducer` / `State` / `Action` / `Effect` という最小構成 |
| `Samples/Todo` | `IdentifiedArrayOf` + `.forEach` によるコレクションの子 Reducer、`BindingReducer` |
| `Samples/SampleNavigationStack` | `StackState` / `NavigationStack(path:)` によるスタック遷移、`delegate` アクションでの子 → 親通知 |
| `Samples/SyncUps` | `@Shared` による状態共有と永続化、`@Presents` の sheet / alert、`SpeechClient` などの依存注入 |
| `Samples/TicTacToe` | `@Reducer enum` + `.ifCaseLet` による画面そのものの切り替え、`ViewAction` によるアクションの制限 |
| `Samples/WeatherSearch` | `@DependencyClient` による API クライアント、debounce とエフェクトのキャンセル |

---

## 理解を深めたポイント

### 1. 親子 Reducer の合成

用途によって使い分ける、というのが一番の学びでした。

| API | 使う場面 |
| --- | --- |
| `Scope` | 子の状態が必ず存在する場合 |
| `.ifLet(\.$destination, action: \.destination)` | `@Presents` な optional の子（sheet / alert / navigation） |
| `.forEach(\.todos, action: \.todos)` | コレクションの各要素が独立した Store を持つ場合 |
| `.ifCaseLet(\.login, action: \.login)` | enum State で「今どの画面か」を表現する場合 |

```swift
// TicTacToe: ログイン画面とゲーム画面を enum で持つ
@Reducer
public enum TicTacToe {
    case login(Login)
    case newGame(NewGame)

    public static var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .login(.loginResponse(.success(response))) where !response.twoFactorRequired:
                state = .newGame(NewGame.State())
                return .none
            ...
            }
        }
        .ifCaseLet(\.login, action: \.login) { Login() }
        .ifCaseLet(\.newGame, action: \.newGame) { NewGame() }
    }
}
```

### 2. Navigation を「状態」で駆動する

画面遷移も alert もすべて State に落とし込み、View は `$store.scope(...)` で受け取るだけにする、
という TCA の考え方をここで理解しました。

```swift
@Reducer
enum Destination {
    case alert(AlertState<Alert>)
    case edit(SyncUpForm)
}

@Presents var destination: Destination.State?
```

```swift
.alert($store.scope(state: \.destination?.alert, action: \.destination.alert))
.sheet(item: $store.scope(state: \.destination?.edit, action: \.destination.edit)) { ... }
```

### 3. 依存の注入（Dependencies）

`@DependencyClient` で API クライアントを struct として定義しておくと、
本番は `liveValue`、テストではクロージャを差し替えるだけで済みます。

```swift
@DependencyClient
struct WeatherClient {
    var search: @Sendable (_ query: String) async throws -> GeocodingSearch
    var forecast: @Sendable (_ location: GeocodingSearch.Result) async throws -> Forecast
}
```

`continuousClock` / `uuid` / `date` / `dismiss` といった標準の依存も、
テストで制御可能にするために積極的に使うようにしました。

### 4. `@Shared` による状態共有と永続化

SyncUps では、リスト全体を `@Shared` で保持し、
その要素を子 Feature に `Shared<SyncUp>` として渡すことで双方向に同期させています。

```swift
extension SharedKey where Self == FileStorageKey<IdentifiedArrayOf<SyncUp>>.Default {
    static var syncUps: Self {
        Self[.fileStorage(.documentsDirectory.appending(component: "sync-ups.json")), default: []]
    }
}

@Shared(.syncUps) var syncUps        // 親
@Shared var syncUp: SyncUp           // 子（要素へのバインディング）
```

書き込みは `withLock` 経由で行う、という点も実装して初めて腹落ちしました。

### 5. Effect のキャンセルと debounce

検索のようにリクエストが連続する画面では、`CancelID` を使って前のリクエストを破棄します。

```swift
return .run { send in
    await send(.forecastResponse(location.id, Result { try await weatherClient.forecast(location: location) }))
}
.cancellable(id: CancelID.weather, cancelInFlight: true)
```

---

## テスト

`TestStore` を使い、**送ったアクションに対して State がどう変わるか** を 1 ステップずつ検証しています。
エフェクトが返したアクションを `receive` で消費しないとテストが失敗する、という仕組みのおかげで、
「気づかないうちに走っている副作用」がなくなることを体感できました。

```swift
let store = TestStore(initialState: TicTacToe.State.login(Login.State())) {
    TicTacToe.body
} withDependencies: {
    $0.authenticationClient.login = { @Sendable _, _ in
        AuthenticationResponse(token: "test-token", twoFactorRequired: false)
    }
}

await store.send(\.login.view.loginButtonTapped) {
    $0.modify(\.login, yield: { $0.isLoginRequestInFlight = true })
}
await store.receive(\.login.loginResponse.success) {
    $0 = .newGame(NewGame.State())
}
```

タイマー処理は `TestClock` を使い、`await clock.advance(by: .seconds(1))` で時間を進めて検証しています。

テストコードの場所:

- `Samples/TicTacToe/TicTacToeTests/` — ログイン、2 要素認証、ゲーム進行の統合テスト
- `Samples/SyncUps/SyncUpsTests/` — 一覧 / 詳細 / フォーム / 録音（タイマー）
- `Samples/Todo/TodosTests.swift`
