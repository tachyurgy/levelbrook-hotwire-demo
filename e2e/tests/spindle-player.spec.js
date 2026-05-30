const { test, expect } = require("@playwright/test")

// Spindle's persistent player. The player bar lives in the layout and is
// data-turbo-permanent, so Turbo preserves the exact DOM node (and its Web
// Audio Stimulus controller) across navigations — the music never re-mounts.
// We prove "same node survives navigation" by tagging the element and checking
// the tag (and the loaded track title) persist after a Turbo visit.
test.describe("Spindle persistent player", () => {
  test("the player element survives Turbo navigation", async ({ page }) => {
    await page.goto("/spindle")

    // Open the first album and start a track.
    await page.locator('a[href^="/spindle/albums/"]').first().click()
    await expect(page).toHaveURL(/\/spindle\/albums\//)

    const firstTrack = page.locator('[data-controller="spindle-play"]').first()
    const trackTitle = (
      await page.locator("li", { has: firstTrack }).locator("span.truncate.font-medium").first().textContent()
    ).trim()

    await firstTrack.click()
    const playerTitle = page.locator('#spindle_player [data-synth-target="title"]')
    await expect(playerTitle).toHaveText(trackTitle)

    // Tag the live player node, then navigate away via a Turbo link.
    await page.locator("#spindle_player").evaluate((el) => (el.dataset.e2eMarker = "kept"))
    await page.getByRole("link", { name: /All albums/i }).click()
    await expect(page).toHaveURL(/\/spindle\/?$|\/spindle\/albums$/)

    // Permanent element: same node (marker intact) and the track is still loaded.
    const player = page.locator("#spindle_player")
    await expect(player).toHaveAttribute("data-e2e-marker", "kept")
    await expect(player.locator('[data-synth-target="title"]')).toHaveText(trackTitle)
  })
})
