import { Controller } from "@hotwired/stimulus"
import { post } from "@rails/request.js"

// Live per-field validation. On blur, POSTs the whole form to the validate
// endpoint with the focused field name; the server stream-replaces just that
// field's frame with the real model errors. No duplicated client rules.
export default class extends Controller {
  static values = { url: String }

  async check(event) {
    const field = event.params.field
    const formData = new FormData(this.element)
    formData.append("field", field)

    await post(this.urlValue, {
      body: formData,
      responseKind: "turbo-stream"
    })
  }
}
