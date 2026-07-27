import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "image"]

  open(event) {
    this.imageTarget.src = event.params.url
    this.imageTarget.alt = event.params.alt
    this.dialogTarget.showModal()
  }

  close() {
    this.dialogTarget.close()
  }

  closeOnBackdrop(event) {
    if (event.target === this.dialogTarget) this.close()
  }

  reset() {
    this.imageTarget.removeAttribute("src")
    this.imageTarget.alt = ""
  }
}
