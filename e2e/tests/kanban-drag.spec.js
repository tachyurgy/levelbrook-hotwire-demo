const { test, expect } = require("@playwright/test")

// The marquee Hotwire flow: a SortableJS drop PUTs the card's new column +
// position, the server reorders, and the Project's broadcasts_refreshes morphs
// every connected board.
//
// SortableJS uses the native HTML5 drag-and-drop API, and a real OS drag cannot
// be synthesized in headless Chromium (the browser won't begin a native drag
// from synthetic input, so SortableJS's onEnd never fires). So we trigger the
// exact request the drop handler makes — a PUT to the card's data-position-url,
// the same payload sortable_controller.js sends — and then assert the part that
// is actually Hotwire: the server reorders and broadcasts_refreshes MORPHS the
// board live (here and in a second tab), and the move survives a reload.
async function dropCardIntoColumn(page, cardText, targetColumnName, position = 0) {
  return await page.evaluate(
    async ({ cardText, targetColumnName, position }) => {
      const card = [...document.querySelectorAll(".column-cards a")].find((a) =>
        a.textContent.includes(cardText)
      )
      if (!card) throw new Error(`card not found: ${cardText}`)
      const url = card.dataset.positionUrl

      const targetSection = [...document.querySelectorAll("section")].find(
        (s) => s.querySelector("h3")?.textContent.trim() === targetColumnName
      )
      const columnId = targetSection.querySelector(".column-cards").dataset.columnId
      const token = document.querySelector('meta[name="csrf-token"]')?.content

      const res = await fetch(url, {
        method: "PUT",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": token,
          Accept: "text/vnd.turbo-stream.html, text/html",
        },
        body: JSON.stringify({ column_id: columnId, position }),
      })
      return res.status
    },
    { cardText, targetColumnName, position }
  )
}

test.describe("Workspace Kanban", () => {
  test("a drop reorders server-side, morphs the board live, and persists", async ({ page }) => {
    await page.goto("/projects/platform")

    const cardText = "Document the morph-vs-append decision"
    const todo = page.locator('section:has(h3:has-text("To Do"))')
    const done = page.locator('section:has(h3:has-text("Done"))')

    // Starts in To Do, not Done.
    await expect(todo.locator("a", { hasText: cardText })).toBeVisible()
    await expect(done.locator("a", { hasText: cardText })).toHaveCount(0)

    const status = await dropCardIntoColumn(page, cardText, "Done")
    expect(status).toBe(204)

    // No reload: the originating tab is subscribed to the project's refresh
    // stream, so broadcasts_refreshes morphs the card into Done in place.
    await expect(done.locator("a", { hasText: cardText })).toBeVisible({ timeout: 15000 })

    // And it's authoritative — reload pulls the new position from the database.
    await page.reload()
    await expect(
      page.locator('section:has(h3:has-text("Done"))').locator("a", { hasText: cardText })
    ).toBeVisible()
  })

  test("a move broadcasts the morph live to a second tab", async ({ browser }) => {
    const a = await browser.newPage()
    const b = await browser.newPage()
    await a.goto("/projects/platform")
    await b.goto("/projects/platform")
    await b.waitForTimeout(1000) // let tab B subscribe to the project stream

    const cardText = "Investigate flaky cable reconnect"
    const status = await dropCardIntoColumn(a, cardText, "Done")
    expect(status).toBe(204)

    // Tab B never issued the request or reloaded — the morph arrives over Turbo
    // Streams / Action Cable.
    const bDone = b.locator('section:has(h3:has-text("Done"))')
    await expect(bDone.locator("a", { hasText: cardText })).toBeVisible({ timeout: 15000 })

    await a.close()
    await b.close()
  })
})
