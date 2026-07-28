import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "environment",
    "locationRow",
    "locationCheckbox",
    "stockRow",
    "stockCheckbox",
    "selectionCount",
    "submit",
    "emptyState"
  ]

  connect() {
    this.filter()
  }

  filter() {
    const environment = this.environmentTargets.find((input) => input.checked)?.value

    this.locationRowTargets.forEach((row) => {
      const available = row.dataset.environment === environment
      const checkbox = row.querySelector(
        '[data-bulk-action-filter-target~="locationCheckbox"]'
      )

      row.hidden = !available
      checkbox.disabled = !available
    })

    const locationIds = this.selectedLocationIds
    let visibleCount = 0

    this.stockRowTargets.forEach((row) => {
      const visible = row.dataset.environment === environment &&
        (locationIds.length === 0 || locationIds.includes(row.dataset.locationId))
      const checkbox = row.querySelector(
        '[data-bulk-action-filter-target~="stockCheckbox"]'
      )

      row.hidden = !visible
      checkbox.disabled = !visible
      if (visible) visibleCount += 1
    })

    this.emptyStateTarget.hidden = visibleCount > 0
    this.updateSelection()
  }

  selectAll() {
    this.visibleCheckboxes.forEach((checkbox) => {
      checkbox.checked = true
    })
    this.updateSelection()
  }

  clearAll() {
    this.visibleCheckboxes.forEach((checkbox) => {
      checkbox.checked = false
    })
    this.updateSelection()
  }

  updateSelection() {
    const selectedCount = this.visibleCheckboxes.filter((checkbox) => checkbox.checked).length
    this.selectionCountTarget.textContent = `${selectedCount}株を選択中`
    this.submitTarget.value = `選択した${selectedCount}株に記録`
    this.submitTarget.disabled = selectedCount === 0
  }

  get visibleCheckboxes() {
    return this.stockCheckboxTargets.filter((checkbox) => !checkbox.disabled)
  }

  get selectedLocationIds() {
    return this.locationCheckboxTargets
      .filter((checkbox) => !checkbox.disabled && checkbox.checked)
      .map((checkbox) => checkbox.value)
  }
}
