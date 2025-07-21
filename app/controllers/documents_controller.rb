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
        diff = get_git_diff(@document.repository.url, @document.pull_request_number)
        @document.content = generate_document_content(diff)
      rescue => e
        # APIエラーの場合はサンプルドキュメントを作成
        Rails.logger.warn "ドキュメント生成エラー: #{e.message}"
        @document.content = create_fallback_document(@document)
      end
    else
      @document.content = create_fallback_document(@document)
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
  
  def generate_sample_document(pr_data)
    # エンコーディングの問題を避けるため、各項目を安全に処理
    title = pr_data[:title].to_s.force_encoding('UTF-8') rescue 'タイトルなし'
    body = (pr_data[:body].to_s.force_encoding('UTF-8') rescue 'Pull Requestの説明がありません')
    diff = pr_data[:diff].to_s.force_encoding('UTF-8').truncate(500) rescue '差分を取得できませんでした'
    
    <<~DOC.force_encoding('UTF-8')
      # Pull Request変更内容
      
      ## 概要
      #{title}
      
      ## 説明
      #{body.empty? ? 'Pull Requestの説明がありません' : body}
      
      ## 変更差分
      ```
      #{diff}
      ```
      
      注意: OpenAI APIキーが設定されていないため、GitHub APIデータを基にしたサンプルドキュメントを表示しています。
      本格的なAI生成ドキュメントを使用するには、環境変数OPENAI_API_KEYを設定してください。
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
