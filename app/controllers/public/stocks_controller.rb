# 購入者が鉢のQRコードから開く、認証なし・読み取り専用の公開ページ。
# 管理画面のbefore_actionを引き継がないよう、ApplicationControllerではなく
# ActionController::Baseを直接継承する。
module Public
  class StocksController < ActionController::Base
    layout "public"

    def show
      @stock = Stock.published
                    .includes(:plant, production_lot: :source_stock)
                    .find_by(public_token: params[:token])

      # 未公開の株と存在しないトークンは区別せず、どちらも同じ404を返す
      render :not_found, status: :not_found if @stock.nil?
    end
  end
end
