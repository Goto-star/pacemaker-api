# frozen_string_literal: true

# PaceMaker AI 自動レビュー（Order 152）
#
# PR diff と CLAUDE.md の「レビュー観点」セクションを読み、Claude API に投げて
# レビュー結果（Markdown）を標準出力へ返す。結果の PR への投稿は呼び出し側の
# ワークフローが `gh pr comment` で行う。
#
# 一般観点（正しさ・N+1・命名・テスト等）は下の GENERAL_CRITERIA に固定で持つ。
# プロジェクト固有観点は CLAUDE.md の該当セクションだけを注入する（CLAUDE.md
# 全体は渡さない）。
module AiReview
  module_function

  # CLAUDE.md でレビュー観点セクションを探す目印。見出し文言が多少変わっても拾えるよう
  # 「## 」見出し かつ この語を含む行を起点にする。
  HEADING_KEYWORD = "レビュー観点"

  # 環境変数で上書きできるが、既定は最も能力の高いモデル。コスト都合で Sonnet / Haiku に
  # 落とす場合は AI_REVIEW_MODEL を指定する（コードは変更不要）。
  DEFAULT_MODEL = "claude-opus-4-8"

  GENERAL_CRITERIA = <<~PROMPT
    あなたは PaceMaker API（Rails 8 API モード）の熟練レビュアーです。
    渡された Git diff をレビューし、日本語で簡潔に指摘してください。

    # 一般観点（必ず確認する）
    - 正しさ：ロジックの誤り、境界条件、nil/例外、データ不整合
    - N+1 クエリやパフォーマンス上の懸念
    - セキュリティ：秘密情報の混入、SQL インジェクション、mass assignment 等
    - 命名・可読性：意図が伝わる命名、責務の分離
    - テスト：振る舞いを検証しているか、観点の抜け漏れがないか

    # 出力形式（厳守）
    - 「## 一般観点」「## PaceMaker規約」の2つの見出しで出力する
    - 各見出しの下に指摘を箇条書きで書く。可能なら `ファイル名:行` を添える
    - 指摘がなければ、その見出しの下に「特になし」とだけ書く
    - 最後に全体への総評を1〜2文で添えてよい
  PROMPT

  # CLAUDE.md 本文から「レビュー観点」セクションの中身（次の見出しまで）を取り出す。
  # 見つからなければ nil を返す。
  def extract_review_guidelines(markdown)
    lines = markdown.lines
    start = lines.index { |line| line.start_with?("## ") && line.include?(HEADING_KEYWORD) }
    return nil unless start

    body = []
    lines[(start + 1)..].each do |line|
      break if line.start_with?("# ") || line.start_with?("## ")

      body << line
    end

    text = body.join.strip
    text.empty? ? nil : text
  end

  # 一般観点（固定）に、注入するプロジェクト固有観点を足した system prompt を組み立てる。
  def build_system_prompt(guidelines)
    prompt = GENERAL_CRITERIA.dup
    return prompt if guidelines.nil? || guidelines.empty?

    prompt + "\n# PaceMaker規約（プロジェクト固有・必ず確認する）\n#{guidelines}\n"
  end

  def build_user_content(diff)
    <<~CONTENT
      以下が今回の PR の diff です。レビューしてください。

      ```diff
      #{diff}
      ```
    CONTENT
  end

  # Claude にレビューを依頼し、本文テキストを返す。client は差し替え可能にしておく。
  def request_review(diff:, guidelines:, model: ENV.fetch("AI_REVIEW_MODEL", DEFAULT_MODEL), client: build_client)
    message = client.messages.create(
      model: model.to_sym,
      max_tokens: 8000,
      thinking: { type: "adaptive" },
      system_: build_system_prompt(guidelines),
      messages: [ { role: "user", content: build_user_content(diff) } ]
    )

    message.content
      .filter_map { |block| block.text if block.type == :text }
      .join("\n")
      .strip
  end

  def build_client
    require "anthropic"
    Anthropic::Client.new # ANTHROPIC_API_KEY を読む
  end

  # CLI エントリポイント。diff ファイルと CLAUDE.md を読み、レビュー結果を標準出力へ。
  def run(diff_path:, claude_md_path:)
    diff = File.read(diff_path)
    if diff.strip.empty?
      warn "diff が空のためレビューをスキップしました。"
      puts "diff に変更がないため、AI レビューはスキップしました。"
      return
    end

    guidelines = extract_review_guidelines(File.read(claude_md_path))
    puts request_review(diff: diff, guidelines: guidelines)
  end
end

if __FILE__ == $PROGRAM_NAME
  repo_root = File.expand_path("../..", __dir__)
  AiReview.run(
    diff_path: ARGV[0] || ENV.fetch("AI_REVIEW_DIFF_FILE"),
    claude_md_path: ENV.fetch("AI_REVIEW_CLAUDE_MD", File.join(repo_root, "CLAUDE.md"))
  )
end
