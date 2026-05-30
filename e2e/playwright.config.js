// @ts-check
const { defineConfig, devices } = require("@playwright/test")
const path = require("path")

// The Rails app lives one directory up from this e2e/ folder.
const RAILS_ROOT = path.resolve(__dirname, "..")
const PORT = process.env.E2E_PORT || "3001"
const BASE_URL = `http://127.0.0.1:${PORT}`

// Boot the dev server (Solid Queue in-process so Pulse jobs run; Solid Cable is
// DB-backed so Action Cable / Turbo Streams work with no Redis), but only after
// the database is prepared and reseeded to a deterministic state.
const SERVER_CMD = [
  "bin/rails db:prepare",
  "bin/rails runner e2e/reset_seed.rb",
  "bin/rails tailwindcss:build",
  `SOLID_QUEUE_IN_PUMA=1 PORT=${PORT} bin/rails server -p ${PORT}`,
].join(" && ")

module.exports = defineConfig({
  testDir: "./tests",
  fullyParallel: false, // one shared Rails DB — keep specs serialized
  workers: 1,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  timeout: 30_000,
  expect: { timeout: 10_000 },
  reporter: [["list"], ["html", { open: "never" }]],
  use: {
    baseURL: BASE_URL,
    trace: "retain-on-failure",
    screenshot: "only-on-failure",
    actionTimeout: 10_000,
  },
  projects: [
    { name: "chromium", use: { ...devices["Desktop Chrome"] } },
  ],
  webServer: {
    command: SERVER_CMD,
    cwd: RAILS_ROOT,
    url: `${BASE_URL}/up`,
    timeout: 120_000,
    reuseExistingServer: !process.env.CI,
    stdout: "pipe",
    stderr: "pipe",
  },
})
