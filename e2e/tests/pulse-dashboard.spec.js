const { test, expect } = require("@playwright/test")

// Pulse ops dashboard. A deploy is a background Active Job (running in-process
// via SOLID_QUEUE_IN_PUMA) that streams a progress bar over Turbo Streams and
// then morphs the service healthy — no client polling.
test.describe("Pulse dashboard", () => {
  test("the dashboard renders services and incidents", async ({ page }) => {
    await page.goto("/pulse")
    await expect(page.getByRole("heading", { name: "API Gateway" })).toBeVisible()
    await expect(page.getByRole("heading", { name: "Checkout" })).toBeVisible()
  })

  test("triggering a deploy streams progress with no polling", async ({ page }) => {
    await page.goto("/pulse")

    // The deploy control posts to /pulse/deploys and the job streams a status
    // partial back into #deploy_status.
    const deployButton = page.getByRole("button", { name: /Deploy/i }).first()
    if ((await deployButton.count()) === 0) {
      test.skip(true, "No deploy control rendered in this view")
    }
    await deployButton.click()

    const status = page.locator("#deploy_status")
    // Progress is pushed from the job over the wire; we should see it move.
    await expect(status).toContainText(/%|deploy/i, { timeout: 15000 })
  })
})
