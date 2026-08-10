module ApplicationHelper
  def expandable_thumbnail(thumbnail_path, expanded_image_path, alt: "")
    label = alt.presence || "画像"

    button_tag(
      type: "button",
      class: "thumbnail-button",
      aria: { label: "#{label}を拡大表示" },
      data: {
        action: "image-modal#open",
        image_modal_url_param: url_for(expanded_image_path),
        image_modal_alt_param: label
      }
    ) do
      image_tag(thumbnail_path, class: "thumbnail", alt: alt)
    end
  end
end
