# Git Docser

Git Docser は、GitHub Pull Request の変更内容から自動でドキュメントを生成する Ruby on Rails アプリケーションです。GitHub API を使用して PR の差分情報を取得し、OpenAI API（オプション）を活用してわかりやすいドキュメントを作成します。

## 機能

- **ユーザー管理**: アカウント作成とログイン機能
- **リポジトリ管理**: GitHub リポジトリの登録・管理
- **PR ドキュメント生成**: Pull Request の変更内容から自動でドキュメントを生成
- **AI による文書生成**: OpenAI API を使用した高品質なドキュメント生成（オプション）
- **GitHub API 連携**: PR 情報、差分、統計情報の自動取得

## 必要な環境

- Ruby 3.2.3+
- Rails 8.0+
- SQLite3
- Bundler 2.6+

## セットアップ

### 1. リポジトリのクローン

```bash
git clone https://github.com/doguto/git-docser.git
cd git-docser
```

### 2. 依存関係のインストール

```bash
bundle install
```

### 3. データベースのセットアップ

```bash
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed  # オプション
```

### 4. 環境変数の設定

OpenAI API を使用する場合（推奨）:

```bash
export OPENAI_API_KEY=your_openai_api_key_here
```

または `.env` ファイルを作成:

```
OPENAI_API_KEY=your_openai_api_key_here
```

**注意**: OpenAI API キーが設定されていない場合も動作しますが、GitHub API データのみを使用したシンプルなドキュメントが生成されます。

### 5. アプリケーションの起動

```bash
bin/rails server
```

アプリケーションは `http://localhost:3000` でアクセスできます。

## 使用方法

### 1. アカウント作成

1. アプリケーションにアクセス
2. 新規ユーザー登録
3. ログイン

### 2. リポジトリの登録

1. 「リポジトリ」ページでリポジトリを追加
2. GitHub リポジトリの名前と URL を入力
   - 例: `https://github.com/username/repository`

### 3. ドキュメント生成

1. 「ドキュメント」ページで新規作成
2. 対象リポジトリと Pull Request 番号を指定
3. ドキュメントが自動生成されます

#### 生成されるドキュメントの内容

- Pull Request のタイトルと概要
- 変更統計（追加行数、削除行数、変更ファイル数など）
- 変更差分の詳細
- GitHub へのリンク
- AI による解説（OpenAI API 使用時）

## 設定

### 環境変数

| 変数名 | 説明 | 必須 |
|--------|------|------|
| `OPENAI_API_KEY` | OpenAI API キー | いいえ |
| `RAILS_ENV` | Rails 環境（production/development/test） | いいえ |

### GitHub リポジトリ要件

- パブリックリポジトリである必要があります
- GitHub API のレート制限にご注意ください

## 開発

### ローカル開発環境のセットアップ

```bash
# 依存関係のインストール
bundle install

# データベースのセットアップ
bin/rails db:setup

# 開発サーバーの起動
bin/rails server
```

### コードの品質チェック

```bash
# RuboCop（コードスタイル）
bin/rubocop

# Brakeman（セキュリティ）
bin/brakeman
```

## デプロイ

### Docker を使用したデプロイ

アプリケーションは Docker 対応しています:

```bash
docker build -t git-docser .
docker run -p 3000:3000 -e OPENAI_API_KEY=your_key git-docser
```

### Kamal を使用したデプロイ

Kamal 設定ファイルが含まれています:

```bash
bin/kamal setup
bin/kamal deploy
```

## トラブルシューティング

### よくある問題

1. **GitHub API エラー**
   - リポジトリ URL が正しいか確認
   - Pull Request 番号が存在するか確認
   - API レート制限に達していないか確認

2. **OpenAI API エラー**
   - API キーが正しく設定されているか確認
   - API キーに十分なクレジットがあるか確認

3. **依存関係エラー**
   - Ruby と Bundler のバージョンを確認
   - `bundle install` を再実行

## ライセンス

このプロジェクトのライセンス情報については、LICENSE ファイルを参照してください。

## 貢献

バグ報告や機能要望は GitHub の Issues からお願いします。Pull Request も歓迎します。
