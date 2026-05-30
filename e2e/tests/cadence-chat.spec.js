const { test, expect } = require("@playwright/test")

// Cadence chat. A sent message append-broadcasts (broadcast_append_to) to every
// subscriber over Action Cable / Turbo Streams — so a message typed in one tab
// shows up in another with no reload. This is the marquee realtime proof.
test.describe("Cadence chat", () => {
  test("a posted message appears in the sender's feed", async ({ page }) => {
    await page.goto("/channels/general")
    const body = `hello from playwright ${Date.now()}`

    await page.getByPlaceholder(/Message #general/i).fill(body)
    await page.getByRole("button", { name: "Send" }).click()

    await expect(page.locator("#messages")).toContainText(body)
  })

  test("a message broadcasts live to a second tab (no reload)", async ({ browser }) => {
    const a = await browser.newPage()
    const b = await browser.newPage()
    await a.goto("/channels/general")
    await b.goto("/channels/general")

    // Give Action Cable a moment to subscribe both tabs.
    await b.waitForTimeout(800)

    const body = `cross-tab broadcast ${Date.now()}`
    await a.getByPlaceholder(/Message #general/i).fill(body)
    await a.getByRole("button", { name: "Send" }).click()

    // Tab B never submitted or reloaded — the message arrives over the wire.
    await expect(b.locator("#messages")).toContainText(body, { timeout: 15000 })

    await a.close()
    await b.close()
  })
})
