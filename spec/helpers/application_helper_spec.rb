require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "サマリの関連リンク" do
    it "植物とロケーションを読点区切りのリンクにする" do
      plant = Plant.create!(name: "リンク対象植物", code: "linked-plant", prefix: "LPT")
      location = Location.create!(name: "リンク対象場所", code: "linked-location", prefix: "LLC")

      expect(helper.admin_plant_links([ plant ])).to include(
        admin_plant_path(plant),
        plant.name
      )
      expect(helper.admin_location_links([ location ])).to include(
        admin_location_path(location),
        location.name
      )
    end
  end

  describe "#expandable_thumbnail" do
    it "拡大表示用のStimulusパラメータを設定する" do
      thumbnail = helper.expandable_thumbnail(
        "/images/small.jpg",
        "/images/large.jpg",
        alt: "バジル"
      )

      expect(thumbnail).to include('data-action="image-modal#open"')
      expect(thumbnail).to include('data-image-modal-url-param="/images/large.jpg"')
      expect(thumbnail).to include('data-image-modal-alt-param="バジル"')
      expect(thumbnail).to include('class="thumbnail"')
    end
  end
end
