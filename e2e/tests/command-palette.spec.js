const { test, expect } = require("@playwright/test")

// ⌘K command palette: opens on the hotkey, debounces typing into a server-
// rendered Turbo Frame of results (no client search index), Enter visits the
// top result.
test.describe("Command palette", () => {
  test("opens on Cmd+K, server-renders results, Enter navigates", async ({ page }) => {
    await page.goto("/workspace")

    await page.keyboard.press("Meta+k")
    const dialog = page.locator("#command_palette dialog")
    await expect(dialog).toBeVisible()

    await page.locator("#command_palette input").fill("Mobile")

    // Results are fetched from the server and spliced into the frame.
    const firstItem = page.locator('[data-command-palette-target="item"]').first()
    await expect(firstItem).toBeVisible()
    await expect(firstItem).toContainText(/Mobile/i)

    await page.locator("#command_palette input").press("Enter")
    await expect(page).toHaveURL(/\/projects\/mobile$/)
  })
})
