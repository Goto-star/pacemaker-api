# PaceMaker API

独学者向け学習管理アプリのバックエンド（Rails 8 API）。
可処分時間 × 理解度をもとに、忘却曲線に沿って学習スケジュールを動的に組み替える。

フロントエンド（Next.js）は別リポジトリ。本リポジトリは **API のみ** を提供する。

## 特徴

- **動的スケジューリング**：SM-2 を参考にした独自ロジックで、次回復習日・推定定着度・1日の学習プランを算出する。
- **優先度づけ**：復習 → 締切間近の新規 → 通常の新規、の固定順で「今日やること」を組み立てる。
- **理解度は ★1〜3 の3段階**：★3 は復習間隔を大きく伸ばし、★1 は間隔をリセットする。
- **サービス層集約**：ビジネスロジックは `app/services/` の PORO に集約し、コントローラ・モデルは薄く保つ。

## 技術スタック

| 分類 | 採用技術 |
|------|----------|
| 言語 / FW | Ruby 3.3 / Rails 8（API モード） |
| DB | PostgreSQL 16 |
| 認証 | Google OAuth 2.0（omniauth）→ 独自 JWT セッショントークン |
| テスト | RSpec / FactoryBot |
| Lint | RuboCop（rails-omakase） |
| セキュリティ | Brakeman / bundler-audit |
| インフラ | Docker / Docker Compose、Kamal（デプロイ）、Puma + Thruster |
| その他 | Solid Queue / Solid Cache / Solid Cable、rack-cors |

## アーキテクチャ

ビジネスロジック、とりわけスケジューリングは **サービス層（PORO）に集約** する。

- **コントローラ**：「受け取る → service を呼ぶ → 返す」だけ。fat controller にしない。
- **モデル**：バリデーション・アソシエーション・スコープのみ。ロジックを持たせない。
- **サービス**：`app/services/` 配下の PORO。サービス間の依存は引数で渡し、グローバルステートに依存しない。

### ドメインモデル

- **User** … 学習者。Google アカウントに紐づく。
- **Material** … 教材（書名・総量・締切など）。`has_many :study_units`
- **StudyUnit** … 章ユニット（所属教材・タイトル・推定所要時間・並び順）。
- **StudyLog** … 学習ログ（学習日・理解度 ★1〜3・所要時間）。
- **ReviewSchedule** … 復習予定（予定日・復習回数・完了フラグ）。

### スケジューリングエンジン（`app/services/scheduling/`）

| クラス | 役割 |
|--------|------|
| `ReviewScheduler` | ★評価と復習回数から次回復習日を算出（SM-2 参考） |
| `RetentionEstimator` | 学習ログから推定定着度（0.0〜1.0）を算出 |
| `DailyPlanner` | 可処分時間に対し、優先度順に当日のユニットを詰め込む |
| `PaceCalculator` | 締切から逆算して1日あたりのノルマを算出 |
| `ReviewRecorder` | 学習ログ記録＋次回復習予定の更新をまとめて実行 |
| `TodayPlanBuilder` | ユーザーの学習状況から `DailyPlanner` の入力を組み立てて当日プランを生成 |
| `RetentionListBuilder` | ユニット別の推定定着度一覧を生成 |

### 認証（`app/services/authentication/`）

- `GoogleUserResolver` … OAuth コールバックから User を解決 / 作成。
- `JsonWebToken` … 独自セッショントークン（JWT）の発行・検証。
- `DevelopmentUserResolver` … development 環境専用のログイン用ユーザー解決。

フロントは PaceMaker 独自の JWT のみを保持し、保護 API には `Authorization: Bearer <token>` を付与する。

## API エンドポイント

業務エンドポイントは JWT 認証必須（`Authorization: Bearer <token>`）。

### 認証・ユーザー

| メソッド | パス | 説明 |
|----------|------|------|
| GET | `/auth/:provider/callback` | Google OAuth コールバック。JWT を発行 |
| POST | `/auth/development/login` | development 限定のテストログイン |
| GET | `/auth/failure` | OAuth 失敗時 |
| GET | `/me` | 現在のユーザー情報 |

### 教材・章ユニット

| メソッド | パス | 説明 |
|----------|------|------|
| GET / POST | `/materials` | 教材の一覧 / 作成 |
| PATCH / DELETE | `/materials/:id` | 教材の更新 / 削除 |
| GET / POST | `/materials/:material_id/study_units` | 章ユニットの一覧 / 作成 |
| PATCH / DELETE | `/materials/:material_id/study_units/:id` | 章ユニットの更新 / 削除 |

### 学習・スケジュール

| メソッド | パス | 説明 |
|----------|------|------|
| POST | `/units/:id/review` | ★評価付きで学習ログを記録し、次回復習予定を更新 |
| GET | `/today_plan` | 当日の学習プラン（優先度順）。`?available_minutes=` で可処分時間を指定（既定 60 分） |
| GET | `/retentions` | ユニット別の推定定着度一覧 |

### ヘルスチェック

| メソッド | パス | 説明 |
|----------|------|------|
| GET | `/health`, `/up` | 稼働確認 |

## セットアップ

### Docker（推奨）

```bash
docker compose up --build
# web: http://localhost:3000 / db: PostgreSQL 16 (5432)
```

初回起動時に `bin/rails db:prepare` が実行される。

### ローカル

```bash
bundle install
bin/rails db:prepare
bin/rails server
```

### 環境変数

development では `.env`（`dotenv-rails` で読み込み）に設定する。秘密情報はコミットしない。

| 変数 | 用途 |
|------|------|
| `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` | Google OAuth 2.0 |
| `FRONTEND_ORIGIN` | CORS 許可オリジン（フロントの URL） |

秘密情報は Rails credentials または環境変数で管理する。

## テスト・Lint

```bash
bundle exec rspec          # テスト（RSpec）
bundle exec rubocop        # Lint（rails-omakase）
bin/brakeman               # 静的セキュリティ解析
bundle exec bundler-audit  # 依存 gem の脆弱性監査
```

## PaceMaker 固有ルール

一般的な間隔反復（SM-2）と異なる点があるため注意。

- **定着度**：ラベルは「定着度」で統一（「節約率」とは書かない）。節約率の近似値として扱い、厳密計測はしない。
- **理解度評価は ★1〜3 の3段階**（SM-2 標準の 0〜5 quality ではない）。★3 は復習間隔を伸ばし、★1 はリセット。
- **優先度は固定順**：復習 → 締切間近の新規 → 通常の新規。

## ディレクトリ構成（抜粋）

```
app/
├── controllers/        # 薄いコントローラ（認証は Authenticatable concern）
├── models/             # User / Material / StudyUnit / StudyLog / ReviewSchedule
└── services/
    ├── authentication/ # JWT 発行・OAuth ユーザー解決
    └── scheduling/     # スケジューリングエンジン（PORO 群）
spec/                   # RSpec（requests / services / models）
```

## 関連ドキュメント

- [`CLAUDE.md`](CLAUDE.md) … AI エージェント / 開発者向けのコーディング規約・レビュー観点。
- [`AGENTS.md`](AGENTS.md) … エージェント運用に関する補足。
