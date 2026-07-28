require "rails_helper"

RSpec.describe Stock, type: :model do
  describe "#display_name" do
    it "ラベルと管理コードを表示する" do
      stock = Stock.new(label: "親株", code: "BAS-001")

      expect(stock.display_name).to eq("親株 / BAS-001")
    end

    it "ラベルが未設定の場合は管理コードだけを表示する" do
      stock = Stock.new(code: "BAS-001")

      expect(stock.display_name).to eq("BAS-001")
    end
  end
end
