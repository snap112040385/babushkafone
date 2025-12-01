import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container"]

  connect() {
    // Prevent body scroll when modal is open
    this.bodyScrollLock = () => {
      document.body.style.overflow = 'hidden'
    }
    this.bodyScrollUnlock = () => {
      document.body.style.overflow = ''
    }
  }

  open() {
    this.containerTarget.classList.remove("hidden")
    this.bodyScrollLock()
  }

  close(event) {
    // Close if clicking on backdrop or close button
    if (event.target === this.containerTarget || event.currentTarget.dataset.action === "click->modal#close") {
      this.containerTarget.classList.add("hidden")
      this.bodyScrollUnlock()
    }
  }

  closeWithKeyboard(event) {
    if (event.code === "Escape") {
      this.containerTarget.classList.add("hidden")
      this.bodyScrollUnlock()
    }
  }

  disconnect() {
    this.bodyScrollUnlock()
  }
}
