namespace :qr do
  desc "指定した株の公開ページQRコードを tmp/qr/ST-<株ID>.png へ出力する（例: bin/rails \"qr:generate[52]\"）"
  task :generate, [ :stock_id ] => :environment do |_task, args|
    # 本番の公開ページのドメイン。別の環境で試すときだけ PUBLIC_BASE_URL で上書きする。
    # ここを変えると、すでに印刷したQRコードは読めなくなるので注意する。
    base_url = ENV.fetch("PUBLIC_BASE_URL", "https://web--basil-manager--46tkrhjqfnyq.code.run")

    stock = Stock.find_by(id: args[:stock_id])
    abort "ST-#{args[:stock_id]} が見つかりません" if stock.nil?
    warn "ST-#{stock.id} には商品形態が未設定です。このままでは育て方が表示されません。" if stock.product_type.blank?

    url = "#{base_url.chomp('/')}/p/#{stock.public_token}"
    # 屋外・水濡れを想定して誤り訂正レベルはq、周囲の余白（quiet zone）は4モジュール確保する
    png = RQRCode::QRCode.new(url, level: :q).as_png(border_modules: 4, module_px_size: 10)

    output_path = Rails.root.join("tmp/qr/ST-#{stock.id}.png")
    FileUtils.mkdir_p(output_path.dirname)
    File.binwrite(output_path, png.to_s)

    puts "#{url} -> #{output_path}（#{png.width}x#{png.height}px）"
  end
end
