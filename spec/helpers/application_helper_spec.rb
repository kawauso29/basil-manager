require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
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
