# load 'db/data/20260720_create_seed_data.rb'

ActiveRecord::Base.transaction do
  Plant.create!(code: "basil", name: "バジル")
  Plant.create!(code: "takanotsume", name: "鷹の爪")
  Plant.create!(code: "green_shiso", name: "青じそ")
  Plant.create!(code: "red_shiso", name: "赤しそ")
  Plant.create!(code: "italian_parsley", name: "イタリアンパセリ")
  Plant.create!(code: "parsley", name: "パセリ")
  Plant.create!(code: "rosemary", name: "ローズマリー")
  Plant.create!(code: "thyme", name: "タイム")
  Plant.create!(code: "oregano", name: "オレガノ")
  Plant.create!(code: "spider_plant", name: "オリヅルラン")
  Plant.create!(code: "sunflower", name: "ひまわり")
  Plant.create!(code: "azzurro_compact", name: "アズーロコンパクト")
  Plant.create!(code: "sunpatiens", name: "サンパチェンス")
  Plant.create!(code: "surfinia", name: "サフィニア")

  Location.create!(code: "kitchen", name: "キッチン")
  Location.create!(code: "south_gate", name: "南門前")
  Location.create!(code: "west_passage_shade", name: "西通路（日陰）")
  Location.create!(code: "west_passage_sun", name: "西通路（日向）")
  Location.create!(code: "south_passage_sun", name: "南通路（日向）")
end
