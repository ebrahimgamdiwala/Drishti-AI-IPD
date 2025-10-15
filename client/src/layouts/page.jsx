"use client"
import App from "../App.jsx"
import SplineBackground from "../components/spline-background.jsx"

export default function Page() {
  return (
    <div className="min-h-[100svh] bg-background relative">
      <SplineBackground />
      <div className="relative z-10">
        <App />
      </div>
    </div>
  )
}
