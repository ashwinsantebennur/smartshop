import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  connect() {
    this.timeout = null
    this.liveSearchEnabled = this.element.dataset.liveSearch === "true"
  }

  search() {
    if (!this.liveSearchEnabled) return
    clearTimeout(this.timeout)
    const query = this.inputTarget.value.trim()
    if (query.length < 3) return
    this.timeout = setTimeout(() => this.submitSearch(query), 400)
  }

  submitSearch(query) {
    const url = `/search?q=${encodeURIComponent(query)}&live=true`
    fetch(url, {
      headers: {
        "Accept": "text/vnd.turbo-stream.html",
        "X-Requested-With": "XMLHttpRequest"
      }
    })
    .then(r => r.text())
    .then(html => Turbo.renderStreamMessage(html))
    .catch(e => console.error("Search error:", e))
  }
}