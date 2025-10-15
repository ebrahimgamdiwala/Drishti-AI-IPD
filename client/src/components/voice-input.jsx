"use client"

import React from "react"

const SpeechRecognition = typeof window !== "undefined" && (window.SpeechRecognition || window.webkitSpeechRecognition)

export default function VoiceInput({ onHotword, onTranscript, className = "", hotword = "drishti" }) {
  const [listening, setListening] = React.useState(false)
  const recognitionRef = React.useRef(null)

  const start = React.useCallback(() => {
    if (!SpeechRecognition) {
      console.warn("[v0] SpeechRecognition not supported in this browser.")
      return
    }
    const recognition = new SpeechRecognition()
    recognition.lang = "en-US"
    recognition.continuous = true
    recognition.interimResults = true

    recognition.onresult = (event) => {
      let transcript = ""
      for (let i = event.resultIndex; i < event.results.length; i++) {
        transcript += event.results[i][0].transcript
      }
      const clean = transcript.toLowerCase()
      onTranscript?.(clean)
      if (clean.includes(hotword.toLowerCase())) {
        onHotword?.()
      }
    }
    recognition.onend = () => {
      if (listening) recognition.start()
    }
    recognition.onerror = (e) => console.error("[v0] Speech error:", e)

    recognitionRef.current = recognition
    recognition.start()
    setListening(true)
  }, [onHotword, onTranscript, hotword, listening])

  const stop = React.useCallback(() => {
    recognitionRef.current?.stop()
    setListening(false)
  }, [])

  React.useEffect(() => {
    return () => {
      recognitionRef.current?.stop()
    }
  }, [])

  return (
    <div className={`glass rounded-xl p-4 border border-foreground/20 ${className}`}>
      <div className="flex items-center justify-between">
        <div>
          <p className="heading font-semibold">Voice Input</p>
          <p className="text-sm text-muted">Say “Drishti” or press Space to capture.</p>
        </div>
        <div className="flex items-center gap-2">
          <button
            className={`px-4 py-2 rounded-full border border-foreground/20 ${
              listening ? "bg-accent text-background" : "bg-foreground/5 hover:bg-foreground/10"
            }`}
            onClick={listening ? stop : start}
          >
            {listening ? "Stop" : "Start"}
          </button>
        </div>
      </div>
    </div>
  )
}
