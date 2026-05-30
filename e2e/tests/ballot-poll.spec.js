const { test, expect } = require("@playwright/test")

// Ballot live polls. Clicking an option bumps the bar optimistically on the
// client, then the server records the vote and the room's broadcasts_refreshes
// morphs the authoritative tally back. After a reload the persisted count
// proves the vote reached the server (not just the optimistic UI).
test.describe("Ballot polls", () => {
  test("voting is optimistic and persists on the server", async ({ page }) => {
    await page.goto("/ballot")
    await expect(page).toHaveURL(/\/ballot\/rooms\//)

    const firstOption = page.locator('[data-poll-target="option"]').first()
    const countEl = firstOption.locator("[data-count]")
    const before = parseInt((await countEl.textContent()).trim(), 10)

    await firstOption.click()

    // Optimistic bump applied immediately on the client.
    await expect(countEl).toHaveText(String(before + 1))
    // Voting locks the buttons (one vote per browser, tracked in localStorage).
    await expect(firstOption).toBeDisabled()

    // Reload: the count now comes straight from the database.
    await page.reload()
    const persisted = page.locator('[data-poll-target="option"]').first().locator("[data-count]")
    await expect(persisted).toHaveText(String(before + 1))
  })
})
