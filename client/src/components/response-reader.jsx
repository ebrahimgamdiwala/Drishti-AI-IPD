"use client"

import React from "react"

export default function ResponseReader({ text = "", className = "" }) {
  const [speaking, setSpeaking] = React.useState(false)

  const speak = React.useCallback(() => {
    if (!("speechSynthesis" in window)) {
      console.warn("[v0] SpeechSynthesis not supported.")
      return
    }
    window.speechSynthesis.cancel()
    if (!text) return
    const utter = new SpeechSynthesisUtterance(text)
    utter.onstart = () => setSpeaking(true)
    utter.onend = () => setSpeaking(false)
    window.speechSynthesis.speak(utter)
  }, [text])

  const stop = React.useCallback(() => {
    window.speechSynthesis.cancel()
    setSpeaking(false)
  }, [])

  React.useEffect(() => {
    // Auto speak on text change
    if (text) speak()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [text])

  return (
    <div className={`glass rounded-xl p-4 border border-foreground/20 ${className}`}>
      <div className="flex items-center justify-between">
        <p className="heading font-semibold">Response</p>
        <div className="flex items-center gap-2">
          <button
            className="px-3 py-2 rounded-full border border-foreground/20 bg-foreground/5 hover:bg-foreground/10"
            onClick={speak}
          >
            Play
          </button>
          <button
            className="px-3 py-2 rounded-full border border-foreground/20 bg-foreground/5 hover:bg-foreground/10"
            onClick={stop}
          >
            {speaking ? "Stop" : "Stop"}
          </button>
        </div>
      </div>
      <div className="mt-3 text-sm text-pretty">{text || "Awaiting response..."}</div>
    </div>
  )
}
