# load 'db/data/20260720_create_seed_data.rb'

ActiveRecord::Base.transaction do
  Plant.create!(code: "basil", name: "バジル", prefix: "BSL")
  Plant.create!(code: "takanotsume", name: "鷹の爪", prefix: "TKN")
  Plant.create!(code: "green_shiso", name: "青じそ", prefix: "GSH")
  Plant.create!(code: "red_shiso", name: "赤しそ", prefix: "RSH")
  Plant.create!(code: "italian_parsley", name: "イタリアンパセリ", prefix: "ITP")
  Plant.create!(code: "parsley", name: "パセリ", prefix: "PRS")
  Plant.create!(code: "rosemary", name: "ローズマリー", prefix: "RSM")
  Plant.create!(code: "thyme", name: "タイム", prefix: "THY")
  Plant.create!(code: "oregano", name: "オレガノ", prefix: "ORG")
  Plant.create!(code: "spider_plant", name: "オリヅルラン", prefix: "SPL")
  Plant.create!(code: "sunflower", name: "ひまわり", prefix: "SNF")
  Plant.create!(code: "azzurro_compact", name: "アズーロコンパクト", prefix: "AZC")
  Plant.create!(code: "sunpatiens", name: "サンパチェンス", prefix: "SNP")
  Plant.create!(code: "surfinia", name: "サフィニア", prefix: "SRF")

  Location.create!(code: "kitchen", name: "キッチン", prefix: "KTC")
  Location.create!(code: "south_gate", name: "南門前", prefix: "SGT")
  Location.create!(code: "west_passage_shade", name: "西通路（日陰）", prefix: "WSH")
  Location.create!(code: "west_passage_sun", name: "西通路（日向）", prefix: "WSU")
  Location.create!(code: "south_passage_sun", name: "南通路（日向）", prefix: "SSU")
end
