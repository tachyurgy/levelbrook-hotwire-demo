const { test, expect } = require("@playwright/test")

// The portfolio front door: one card per Showcase app, each a Turbo link into
// the running product.
test.describe("Gallery", () => {
  test("lists the three showcase apps and routes into one", async ({ page }) => {
    await page.goto("/")

    for (const name of ["Workspace", "Relay", "Forge"]) {
      await expect(page.getByRole("heading", { name, exact: true })).toBeVisible()
    }

    // Clicking Workspace opens its dashboard (a Turbo navigation, no full reload).
    await page.getByRole("heading", { name: "Workspace", exact: true }).click()
    await expect(page).toHaveURL(/\/workspace$/)
    // The themeable product shell is now present.
    await expect(page.locator("aside, nav").first()).toBeVisible()
  })
})
