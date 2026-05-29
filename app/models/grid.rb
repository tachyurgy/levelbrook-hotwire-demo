# Grid — an Airtable/spreadsheet-lite. Editable cells are frame-scoped; the
# Total column and the grand total are *formula* cells the server recomputes,
# and broadcasts_refreshes morphs the recalculated cells onto every client.
module Grid
  def self.table_name_prefix = "grid_"

  def self.seed!
    return if Sheet.exists?

    cloud = Sheet.create!(name: "Q3 Cloud Budget", slug: "q3-cloud-budget", unit: "$")
    cloud.rows.create!([
      { label: "Compute (web)",     category: "Compute", qty: 6,  unit_price: 180, position: 0 },
      { label: "Compute (workers)", category: "Compute", qty: 3,  unit_price: 140, position: 1 },
      { label: "Managed Postgres",  category: "Data",    qty: 1,  unit_price: 420, position: 2 },
      { label: "Object storage",    category: "Data",    qty: 1,  unit_price: 95,  position: 3 },
      { label: "CDN / egress",      category: "Network", qty: 1,  unit_price: 160, position: 4 },
      { label: "Observability",     category: "Tooling", qty: 12, unit_price: 22,  position: 5 }
    ])

    launch = Sheet.create!(name: "Launch Forecast", slug: "launch-forecast", unit: "$")
    launch.rows.create!([
      { label: "Trial signups",      category: "Top of funnel", qty: 1200, unit_price: 0,  position: 0 },
      { label: "Paid conversions",   category: "Revenue",       qty: 84,   unit_price: 49, position: 1 },
      { label: "Annual upgrades",    category: "Revenue",       qty: 18,   unit_price: 490, position: 2 },
      { label: "Support cost / mo",  category: "Cost",          qty: 1,    unit_price: 1800, position: 3 }
    ])
  end
end
