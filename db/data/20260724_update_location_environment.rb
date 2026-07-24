# load 'db/data/20260724_update_location_environment.rb'

ActiveRecord::Base.transaction do
  outdoor_location_codes = [
    "south_gate",
    "west_passage_shade",
    "west_passage_sun",
    "south_passage_sun"
  ]

  Location.where(code: outdoor_location_codes).find_each do |location|
    location.update!(environment: :outdoor)
  end
end
