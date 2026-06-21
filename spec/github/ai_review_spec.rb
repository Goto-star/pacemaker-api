require "spec_helper"
require_relative "../../.github/scripts/ai_review"

# AI 自動レビュー（Order 152）の純粋ロジックを検証する。
# Claude API への送信そのものは外部依存・実装詳細のため、ここでは検証しない。
RSpec.describe AiReview do
  describe ".extract_review_guidelines" do
    context "CLAUDE.md にレビュー観点セクションがあるとき" do
      let(:markdown) do
        <<~MD
          ## 9. PaceMaker 固有ルール

          - 定着度で統一する

          ## 10. レビュー観点（AI自動レビュー用）

          - **用語**：定着度で統一されているか
          - **優先度**：固定順を崩していないか

          ## 11. 次のセクション

          - これは含まれない
        MD
      end

      it "そのセクションの本文だけを返す" do
        result = described_class.extract_review_guidelines(markdown)

        expect(result).to eq("- **用語**：定着度で統一されているか\n- **優先度**：固定順を崩していないか")
      end

      it "後続セクションの内容は含めない" do
        expect(described_class.extract_review_guidelines(markdown)).not_to include("次のセクション")
      end
    end

    context "レビュー観点セクションがないとき" do
      it "nil を返す" do
        markdown = "## 1. 概要\n\n- 何かの説明\n"

        expect(described_class.extract_review_guidelines(markdown)).to be_nil
      end
    end

    context "見出しはあるが本文が空のとき" do
      it "nil を返す" do
        markdown = "## レビュー観点\n\n## 次\n- x\n"

        expect(described_class.extract_review_guidelines(markdown)).to be_nil
      end
    end
  end

  describe ".build_system_prompt" do
    it "一般観点と、2つの出力見出しの指示を常に含む" do
      prompt = described_class.build_system_prompt(nil)

      expect(prompt).to include("一般観点")
      expect(prompt).to include("PaceMaker規約")
    end

    it "固有観点が渡されたとき、それを system prompt に注入する" do
      prompt = described_class.build_system_prompt("- 定着度で統一されているか")

      expect(prompt).to include("- 定着度で統一されているか")
    end

    it "固有観点が nil のとき、注入セクションを足さない" do
      prompt = described_class.build_system_prompt(nil)

      expect(prompt).not_to include("プロジェクト固有・必ず確認する")
    end
  end

  describe ".request_review" do
    # API クライアントは差し替え可能。送信内容ではなく「テキストブロックだけを
    # 連結して返す」という結果を検証する。
    it "応答のテキストブロックだけを連結して返す" do
      text_block = double("text", type: :text, text: "## 一般観点\n特になし")
      thinking_block = double("thinking", type: :thinking)
      message = double("message", content: [ thinking_block, text_block ])
      client = double("client", messages: double(create: message))

      result = described_class.request_review(diff: "diff", guidelines: nil, client: client)

      expect(result).to eq("## 一般観点\n特になし")
    end
  end
end
