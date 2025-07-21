class GitService
  def self.get_pull_request_diff(repo_url, pr_number)
    # GitHub APIを使用してPull Request情報を取得
    # 例: GitHubリポジトリの場合
    if repo_url.include?('github.com')
      get_github_pr_diff(repo_url, pr_number)
    else
      raise "サポートされていないリポジトリタイプです"
    end
  end

  private

  def self.get_github_pr_diff(repo_url, pr_number)
    # GitHubリポジトリのURLからowner/repoを抽出
    # 様々なGitHubのURL形式に対応
    # https://github.com/owner/repo
    # https://github.com/owner/repo.git
    # git@github.com:owner/repo.git
    
    if repo_url.include?('github.com')
      # HTTPSまたはSSH形式のURL
      if repo_url.match(/github\.com[\/:]([^\/]+)\/([^\/\s]+)/)
        match = repo_url.match(/github\.com[\/:]([^\/]+)\/([^\/\s]+)/)
        owner = match[1]
        repo = match[2].gsub(/\.git$/, '').gsub(/\/$/, '') # 末尾の.gitと/を除去
        Rails.logger.info "GitHub API呼び出し: owner=#{owner}, repo=#{repo}, pr=#{pr_number}"
      else
        raise "GitHubリポジトリURLの形式が正しくありません: #{repo_url}"
      end
    else
      raise "GitHubリポジトリではありません: #{repo_url}"
    end
    
    # GitHub APIを使用してPull Request差分を取得
    # 実際の実装では適切な認証とエラーハンドリングが必要
    begin
      require 'net/http'
      require 'json'
      
      uri = URI("https://api.github.com/repos/#{owner}/#{repo}/pulls/#{pr_number}")
      Rails.logger.info "GitHub API URL: #{uri}"
      
      # HTTPリクエストの設定
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Get.new(uri)
      request['Accept'] = 'application/vnd.github.v3+json'
      request['User-Agent'] = 'Git-Docser/1.0'
      
      response = http.request(request)
      Rails.logger.info "GitHub APIレスポンスコード: #{response.code}"
      
      if response.code == '200'
        # レスポンスボディを適切にエンコーディング
        response_body = response.body.force_encoding('UTF-8')
        pr_data = JSON.parse(response_body)
        
        # 差分を取得
        diff_uri = URI("https://api.github.com/repos/#{owner}/#{repo}/pulls/#{pr_number}.diff")
        diff_http = Net::HTTP.new(diff_uri.host, diff_uri.port)
        diff_http.use_ssl = true
        diff_request = Net::HTTP::Get.new(diff_uri)
        diff_request['Accept'] = 'application/vnd.github.v3.diff'
        diff_request['User-Agent'] = 'Git-Docser/1.0'
        
        diff_response = diff_http.request(diff_request)
        Rails.logger.info "差分APIレスポンスコード: #{diff_response.code}"
        
        if diff_response.code == '200'
          # 差分データも適切にエンコーディング
          diff_body = diff_response.body.force_encoding('UTF-8')
          return {
            title: pr_data['title'] || 'タイトルなし',
            body: pr_data['body'] || '説明なし', 
            diff: diff_body
          }
        else
          raise "差分の取得に失敗しました (コード: #{diff_response.code})"
        end
      else
        error_msg = "Pull Request情報の取得に失敗しました (コード: #{response.code})"
        if response.code == '404'
          error_msg += " - リポジトリまたはPull Requestが見つかりません"
        elsif response.code == '403'
          error_msg += " - APIレート制限またはアクセスが拒否されました"
        end
        raise error_msg
      end
    rescue => e
      raise "GitHub API呼び出しエラー: #{e.message}"
    end
  end
end
