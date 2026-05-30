const { test, expect } = require("@playwright/test")

// Per-field live validation: blur a field and the server stream-replaces just
// that field's frame with the real ActiveModel errors — one source of
// validation truth, shared with the eventual submit.
test.describe("Live signup validation", () => {
  test("blurring an invalid field shows the server-rendered error", async ({ page }) => {
    await page.goto("/signups/new")

    // A reserved subdomain is rejected by the model's custom validation.
    const subdomain = page.locator("#signup_subdomain")
    await subdomain.fill("admin")
    await subdomain.blur()

    const frame = page.locator("#signup_field_subdomain")
    await expect(frame).toContainText(/already taken/i)
  })

  test("a valid field reports looks good", async ({ page }) => {
    await page.goto("/signups/new")
    const name = page.locator("#signup_workspace_name")
    await name.fill("Acme Platform")
    await name.blur()
    await expect(page.locator("#signup_field_workspace_name")).toContainText(/looks good/i)
  })
})
