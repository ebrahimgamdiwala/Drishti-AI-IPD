"use client"

import React from "react"
import GlassCard from "../components/glass-card.jsx"

function Stat({ label, value }) {
  return (
    <div className="glass rounded-xl p-4 border border-foreground/20">
      <p className="text-sm text-muted">{label}</p>
      <p className="heading text-2xl font-semibold mt-1">{value}</p>
    </div>
  )
}

export default function AdminDashboard() {
  const [tab, setTab] = React.useState("Relatives")

  return (
    <div className="mx-auto max-w-7xl px-6 py-10 space-y-6">
      <div className="grid md:grid-cols-3 gap-4">
        <Stat label="Total Users" value="1,248" />
        <Stat label="Active Alerts" value="7" />
        <Stat label="Recent Detections" value="132" />
      </div>

      <GlassCard className="p-4">
        <div className="flex items-center gap-2">
          {["Relatives", "Emergency"].map((t) => (
            <button
              key={t}
              onClick={() => setTab(t)}
              className={`px-4 py-2 rounded-full border border-foreground/20 ${
                tab === t ? "bg-primary text-background" : "bg-foreground/5 hover:bg-foreground/10"
              }`}
            >
              {t}
            </button>
          ))}
        </div>

        <div className="mt-4">
          {tab === "Relatives" ? (
            <div className="space-y-2">
              <div className="glass rounded-lg p-3 border border-foreground/20 flex items-center justify-between">
                <p className="text-sm">Approve new relative accounts</p>
                <button className="px-3 py-1.5 rounded-full bg-accent text-background border border-foreground/20">
                  Review
                </button>
              </div>
              <div className="glass rounded-lg p-3 border border-foreground/20 flex items-center justify-between">
                <p className="text-sm">Manage linked profiles</p>
                <button className="px-3 py-1.5 rounded-full bg-foreground/5 border border-foreground/20 hover:bg-foreground/10">
                  Open
                </button>
              </div>
            </div>
          ) : (
            <div className="space-y-2">
              <div className="glass rounded-lg p-3 border border-foreground/20 flex items-center justify-between">
                <p className="text-sm">Emergency response workflows</p>
                <button className="px-3 py-1.5 rounded-full bg-foreground/5 border border-foreground/20 hover:bg-foreground/10">
                  Configure
                </button>
              </div>
              <div className="glass rounded-lg p-3 border border-foreground/20 flex items-center justify-between">
                <p className="text-sm">Escalation contacts</p>
                <button className="px-3 py-1.5 rounded-full bg-primary text-background border border-foreground/20">
                  Edit
                </button>
              </div>
            </div>
          )}
        </div>
      </GlassCard>
    </div>
  )
}
