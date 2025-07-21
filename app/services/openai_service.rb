class OpenaiService
  def self.generate_document(pr_data)
    client = OpenAI::Client.new(
      access_token: ENV["OPENAI_API_KEY"]
    )
    Rails.logger.info "OPENAI KEY: #{ENV['OPENAI_API_KEY'].present? ? 'FOUND' : 'NOT FOUND'}"

    prompt = build_prompt(pr_data)

    begin
      response = client.chat(
        parameters: {
          model: "gpt-3.5-turbo",
          messages: [
            {
              role: "system",
              content: "あなたはソフトウェア開発のドキュメント作成の専門家です。Pull Requestの変更内容を分析して、わかりやすいドキュメントを日本語で作成してください。"
            },
            {
              role: "user",
              content: prompt
            }
          ],
          max_tokens: 1000,
          temperature: 0.7
        }
      )

      response.dig("choices", 0, "message", "content")
    rescue => e
      raise "OpenAI API呼び出しエラー: #{e.message}"
    end
  end

  private

  def self.build_prompt(pr_data)
    <<~PROMPT
      以下のPull Requestの情報を分析して、変更内容のドキュメントを作成してください。

      ## Pull Request情報
      タイトル: #{pr_data[:title]}
      概要: #{pr_data[:body]}

      ## 変更差分
      ```
      #{pr_data[:diff]}
      ```

      ## 要求事項
      1. 変更の概要
      2. 主な変更点
      3. 影響範囲
      4. 注意点（あれば）

      読みやすく、理解しやすいドキュメントを作成してください。
    PROMPT
  end
end
