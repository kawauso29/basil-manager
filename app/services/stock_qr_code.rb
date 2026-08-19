# 鉢に貼るQRコードのPNGを作る。中身はStock#public_urlから決まるため保存しない。
class StockQrCode
  # 屋外・水濡れを想定して誤り訂正レベルはq、周囲の余白（quiet zone）は4モジュール確保する
  def self.png(stock)
    RQRCode::QRCode.new(stock.public_url, level: :q)
                   .as_png(border_modules: 4, module_px_size: 10)
                   .to_s
  end

  # ラベルシート用。印刷時に画像が未読み込みだと欠けるため、HTMLへ直接埋め込む
  def self.data_uri(stock)
    "data:image/png;base64,#{Base64.strict_encode64(png(stock))}"
  end
end
