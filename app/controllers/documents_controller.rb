class DocumentsController < ApplicationController
  before_action :require_login
  
  def index
    @documents = current_user.documents.includes(:repository)
  end

  def new
    @document = current_user.documents.new
    @repositories = current_user.repositories
    
    # repository_idパラメータが渡された場合は事前選択
    if params[:repository_id].present?
      @document.repository_id = params[:repository_id]
    end
  end

  def create
    @document = current_user.documents.new(document_params)
    
    # 基本タイトルを設定
    @document.title = "PR ##{@document.pull_request_number} 変更内容"
    
    if @document.pull_request_number.present?
      begin
        # GitHub APIで情報取得を試みる
        pr_data = get_git_diff(@document.repository.url, @document.pull_request_number)
        @document.content = generate_document_content(pr_data)
        # 差分データを構造化して保存
        @document.diff_data = extract_diff_data(pr_data).to_json
      rescue => e
        # APIエラーの場合はサンプルドキュメントを作成
        Rails.logger.warn "ドキュメント生成エラー: #{e.message}"
        @document.content = create_fallback_document(@document)
        @document.diff_data = nil
      end
    else
      @document.content = create_fallback_document(@document)
      @document.diff_data = nil
    end

    if @document.save
      redirect_to document_path(@document), notice: 'ドキュメントが作成されました。'
    else
      @repositories = current_user.repositories
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @document = current_user.documents.find(params[:id])
  end

  private

  def document_params
    params.require(:document).permit(:pull_request_number, :repository_id)
  end

  def get_git_diff(repo_url, pr_number)
    GitService.get_pull_request_diff(repo_url, pr_number)
  end

  def generate_document_content(pr_data)
    if ENV['OPENAI_API_KEY'].present?
      OpenaiService.generate_document(pr_data)
    else
      generate_sample_document(pr_data)
    end
  end

  def extract_diff_data(pr_data)
    return nil unless pr_data[:diff].present?
    
    {
      diff: pr_data[:diff],
      stats: pr_data[:stats] || {},
      urls: pr_data[:urls] || {}
    }
  end
  
  def generate_sample_document(pr_data)
    # エンコーディングの問題を避けるため、各項目を安全に処理
    title = pr_data[:title].to_s.force_encoding('UTF-8') rescue 'タイトルなし'
    body = (pr_data[:body].to_s.force_encoding('UTF-8') rescue 'Pull Requestの説明がありません')
    diff = pr_data[:diff].to_s.force_encoding('UTF-8') rescue '差分を取得できませんでした'
    
    # 差分が非常に長い場合のみ制限をかける
    if diff.length > 10000
      diff = diff.truncate(10000) + "\n\n... (差分が長いため略しています。完全な差分はGitHubで確認してください)"
    end
    
    # 統計情報を取得
    stats = pr_data[:stats] || {}
    urls = pr_data[:urls] || {}
    
    <<~DOC.force_encoding('UTF-8')
      # Pull Request変更内容
      
      ## タイトル
      #{title}
      
      ## 詳細
      #{body.empty? ? 'Pull Requestの説明がありません' : body}
      
      ## 変更統計
      - コミット数: #{stats[:commits] || 'N/A'}
      - 追加行数: #{stats[:additions] || 'N/A'}
      - 削除行数: #{stats[:deletions] || 'N/A'}
      - 変更ファイル数: #{stats[:changed_files] || 'N/A'}
      
      ## 変更差分
      ```
      #{diff}
      ```
      
      ## GitHubリンク
      - [Pull RequestをGitHubで確認](#{urls[:html_url]})
      - [差分をGitHubで確認](#{urls[:diff_url]})
      
      ---
      
      **注意**: OpenAI APIキーが設定されていないため、GitHub APIデータを基にしたサンプルドキュメントを表示しています。  
      本格的なAI生成ドキュメントを使用するには、環境変数`OPENAI_API_KEY`を設定してください。
    DOC
  end
  
  def create_fallback_document(document)
    <<~DOC
      # Pull Request ##{document.pull_request_number} 変更内容
      
      ## 概要
      このPull Requestについてのドキュメントです。
      
      ## リポジトリ情報
      - リポジトリ: #{document.repository.name}
      - URL: #{document.repository.url}
      - Pull Request番号: ##{document.pull_request_number}
      
      ## ステータス
      このドキュメントはGitHub APIから情報を取得できなかったため、サンプルドキュメントとして作成されました。
      
      ## 正確な情報を取得するには
      1. GitHubのリポジトリがパブリックであることを確認してください
      2. Pull Request番号が正しいことを確認してください
      3. リポジトリURLが正しい形式であることを確認してください
      
      作成日時: #{Time.current.strftime('%Y-%m-%d %H:%M:%S')}
    DOC
  end
end
