# 購入者が鉢のQRコードから開く、認証なし・読み取り専用の公開ページ。
# 管理画面のbefore_actionを引き継がないよう、ApplicationControllerではなく
# ActionController::Baseを直接継承する。
module Public
  class StocksController < ActionController::Base
    layout "public"

    def show
      # Stockはすべて常時公開とし、公開・非公開の切り替えは持たない。
      # URLを知っている購入者だけが開けることを前提にする。
      @stock = Stock.includes(:plant, production_lot: :source_stock)
                    .find_by(public_token: params[:token])

      render :not_found, status: :not_found if @stock.nil?
    end
  end
end
