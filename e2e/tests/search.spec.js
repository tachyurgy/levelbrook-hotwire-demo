const { test, expect } = require("@playwright/test")

// Debounced live search: the form auto-submits into a Turbo Frame as you type,
// and the URL advances so results are shareable / back-button-able.
test.describe("Live search", () => {
  test("debounced typing filters issues into the results frame", async ({ page }) => {
    await page.goto("/search")

    await page.getByPlaceholder("Search titles and descriptions…").fill("morph")

    const results = page.locator("#search_results")
    await expect(results).toContainText(/result/i)
    await expect(results.getByText(/morph/i).first()).toBeVisible()

    // The URL advanced with the query (shareable / back-button-able).
    await expect(page).toHaveURL(/q=morph/)
  })

  test("a query with no matches shows the empty state", async ({ page }) => {
    await page.goto("/search")
    await page.getByPlaceholder("Search titles and descriptions…").fill("zzxqnomatch")
    await expect(page.locator("#search_results")).toContainText(/No issues match/i)
  })
})
