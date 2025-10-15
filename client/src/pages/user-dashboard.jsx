"use client"

import React from "react"
import Spline from "@splinetool/react-spline"
import GlassCard from "../components/glass-card.jsx"
import VoiceInput from "../components/voice-input.jsx"
import ResponseReader from "../components/response-reader.jsx"
import CameraFeed from "../components/camera-feed.jsx"
import summaryAPI from "../lib/summaryAPI"
import { initialAssistantPrompt } from "../lib/assistantPrompts"

export default function UserDashboard() {
  const cameraRef = React.useRef(null)
  const [transcript, setTranscript] = React.useState("")
  const [question, setQuestion] = React.useState("")
  const [response, setResponse] = React.useState("")
  const [chat, setChat] = React.useState([])
  const [sending, setSending] = React.useState(false)
  const [sessionId, setSessionId] = React.useState(null)
  const [lastImage, setLastImage] = React.useState(null)

  // Spacebar handler for snapshot
  React.useEffect(() => {
    const onKey = async (e) => {
      if (e.code === "Space") {
        // Don't trigger when user is typing in an input/textarea or a contentEditable element
        const active = document.activeElement;
        const tag = active?.tagName?.toLowerCase();
        const isTyping = tag === 'input' || tag === 'textarea' || active?.isContentEditable;
        if (isTyping) return;

        // If a request is already in flight, ignore repeated space presses
        if (sending) return;

        e.preventDefault()
        await handleAnalyze()
      }
    }
    window.addEventListener("keydown", onKey)
    return () => window.removeEventListener("keydown", onKey)
    // include sending so the handler can check in-flight state
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [question, transcript, sending])

  const captureImageDataUrl = React.useCallback(() => {
    // Access internal capture function via DOM or fallback:
    // We attached a hidden input storing capture callback; simpler: query the instance method (we added a functional one)
    const el = cameraRef.current
    if (!el) return null
    // Walk DOM to find hidden input storing function — but better: we exposed a closure capture in component. For simplicity,
    // we’ll query the video canvas approach by calling a function via dataset is not trivial.
    // Alternative: render prop approach was avoided; replicate capture here through a small workaround:
    try {
      const video = el.querySelector("video")
      const canvas = document.createElement("canvas")
      if (!video || !video.videoWidth) return null
      canvas.width = video.videoWidth
      canvas.height = video.videoHeight
      const ctx = canvas.getContext("2d")
      ctx.drawImage(video, 0, 0, canvas.width, canvas.height)
      const dataUrl = canvas.toDataURL("image/jpeg", 0.9)
      return dataUrl
    } catch (err) {
      console.error("[v0] Snapshot error:", err)
      return null
    }
  }, [])

  // Simple deterministic string hash (djb2) for quick checksums
  const hashString = React.useCallback((str) => {
    let hash = 5381
    for (let i = 0; i < str.length; i++) {
      hash = ((hash << 5) + hash) + str.charCodeAt(i) // hash * 33 + c
      hash = hash & 0xffffffff
    }
    // convert to unsigned hex
    return (hash >>> 0).toString(16)
  }, [])

  const handleAnalyze = React.useCallback(async (capturedTranscript = null) => {
    const img = captureImageDataUrl()
    if (!img) {
      console.warn("[v0] No image captured.")
      return
    }
    // show preview for user
      try {
        setLastImage(img)
      } catch (e) {}
  // Extract MIME and strip data URL prefix to hash and send exactly what server receives
  const mimeMatch = (img || '').match(/^data:([^;]+);base64,/) || []
  const imageMime = mimeMatch[1] || 'image/jpeg'
  const base64OnlyClient = (img || '').replace(/^data:[^;]+;base64,/, '')
  const imageHash = hashString(base64OnlyClient || '')
    // use existing sessionId to retain context across follow-ups
    let currentSessionId = sessionId
    if (!currentSessionId) {
      currentSessionId = `${Date.now()}-${Math.random().toString(36).slice(2,9)}`
      setSessionId(currentSessionId)
    }

    const userPrompt = capturedTranscript || question || transcript || ''
    // Ensure the user's question is prominently featured in the prompt
    const prompt = userPrompt 
      ? `${initialAssistantPrompt}\n\nUser question: "${userPrompt}"\n\nIMPORTANT: Answer the above question specifically about the image.`
      : initialAssistantPrompt
    setSending(true)
    try {
  const { data } = await summaryAPI.model.analyze({ image: img, prompt, sessionId: currentSessionId, imageHash, imageMime })
      // expose server hash to UI if present
      if (data?.serverImageHash) {
        const serverSample = data?.serverBase64Sample ? ` sample(${data.serverBase64Sample.length}): ${data.serverBase64Sample}` : ''
        setChat((prev) => [...prev, { role: 'system', content: `Image hash client/server: ${imageHash} / ${data.serverImageHash}${serverSample}` }])
      }
  const aiRaw = data?.response || data?.answer || (data?.message ?? "No response from model.")
  const ai = typeof aiRaw === 'string' ? aiRaw : (aiRaw && typeof aiRaw === 'object' ? JSON.stringify(aiRaw) : String(aiRaw))
      // if server saved the image, include where it is stored
      if (data?.savedImageUrl) {
        setChat((prev) => [...prev, { role: 'system', content: `Image saved to: ${data.savedImageUrl}` }])
      }
    setResponse(ai)
  const safeUserPrompt = (typeof userPrompt === 'string' && userPrompt) ? userPrompt : String(userPrompt || 'Describe the scene')
  setChat((prev) => [...prev, { role: "user", content: safeUserPrompt }, { role: "assistant", content: ai }])
    } catch (err) {
      console.error("[v0] Analyze error:", err)
      // Detect timeout (axios uses code 'ECONNABORTED' for timeouts)
      if (err?.code === 'ECONNABORTED' || (err?.message && err.message.toLowerCase().includes('timeout'))) {
  const aiTimeout = 'The request timed out. The model may be busy — try again or increase server timeout.'
  setResponse(aiTimeout)
  const safeUserPromptTO = (typeof userPrompt === 'string' && userPrompt) ? userPrompt : String(userPrompt || 'Describe the scene')
  setChat((prev) => [...prev, { role: 'user', content: safeUserPromptTO }, { role: 'assistant', content: aiTimeout }])
        setSending(false)
        return
      }
  let ai = err?.response?.data?.error || err?.message || "There was an error contacting the analysis service."
  if (ai && typeof ai === 'object') ai = JSON.stringify(ai)
      // Common auth error returned by server: "No token provided"
      if (ai && ai.toString().toLowerCase().includes('no token')) {
        ai = "Not authenticated. Please sign in so the assistant can process images."
        try { localStorage.removeItem('token') } catch (e) {}
      }
  setResponse(ai)
  const safeUserPromptErr = (typeof userPrompt === 'string' && userPrompt) ? userPrompt : String(userPrompt || 'Describe the scene')
  setChat((prev) => [...prev, { role: "user", content: safeUserPromptErr }, { role: "assistant", content: ai }])
    } finally {
      setSending(false)
    }
  }, [captureImageDataUrl, question, transcript])

  return (
    <div className="relative min-h-[100svh]">
      {/* Background provided by MainLayout -> SplineBackground */}

      <div className="mx-auto max-w-7xl px-6 py-10 space-y-6">
        <div className="grid lg:grid-cols-3 gap-6">
          <GlassCard className="p-4 lg:col-span-2">
            <div className="flex items-center justify-between mb-3">
              <h3 className="heading font-semibold">Live Camera Feed</h3>
              <button
                onClick={handleAnalyze}
                className="px-4 py-2 rounded-full bg-primary text-background border border-foreground/20"
                disabled={sending}
              >
                {sending ? "Analyzing…" : "Capture & Analyze"}
              </button>
            </div>
            <div className="flex items-center gap-2 mb-3">
              <button
                onClick={() => {
                  setChat([])
                  setResponse("")
                  setSessionId(null)
                }}
                className="px-3 py-1 rounded-full border border-foreground/20 bg-foreground/5"
              >
                New session
              </button>
            </div>
            <div ref={cameraRef}>
              <CameraFeed className="aspect-video bg-foreground/5" />
            </div>
            {lastImage && (
              <div className="mt-3 flex items-center gap-3">
                <div className="text-sm">Last capture:</div>
                <img src={lastImage} alt="Last capture preview" className="w-28 h-20 object-cover rounded-md border" />
              </div>
            )}
          </GlassCard>

          <div className="space-y-6">
            <VoiceInput 
              onHotword={() => {
                // When hotword is detected, capture image but don't analyze yet
                const img = captureImageDataUrl();
                if (img) {
                  setLastImage(img);
                  // The voice-input component will handle listening for the question
                  // and will call handleAnalyze with the transcript when done
                }
              }} 
              onTranscript={(text) => {
                setTranscript(text);
                // If we're in capturing mode (after hotword), the component will call handleAnalyze
                // with the transcript when silence is detected
                if (text && text.trim() !== "") {
                  handleAnalyze(text);
                }
              }} 
            />
            <GlassCard className="p-4">
              <label className="text-sm mb-2 block">Ask a question (optional)</label>
              <div className="flex gap-2">
                <input
                  value={question}
                  onChange={(e) => setQuestion(e.target.value)}
                  onKeyDown={(e) => {
                    if (e.key === 'Enter') {
                      e.preventDefault()
                      // trigger capture & analyze when Enter pressed
                      handleAnalyze()
                    }
                  }}
                  placeholder="What is ahead of me?"
                  className="flex-1 rounded-lg bg-foreground/5 border border-foreground/20 px-3 py-2 outline-none focus:border-primary"
                />
                <button
                  onClick={() => handleAnalyze()}
                  disabled={sending}
                  className="px-4 py-2 rounded-lg bg-primary text-background border border-foreground/20"
                  aria-label="Send question and capture image"
                >
                  {sending ? 'Sending…' : 'Send'}
                </button>
              </div>
            </GlassCard>
          </div>
        </div>

        <div className="grid lg:grid-cols-3 gap-6">
          <ResponseReader text={response} className="lg:col-span-2" />
          <GlassCard className="p-4">
            <h3 className="heading font-semibold">Context</h3>
            <div className="mt-3 space-y-2 max-h-[280px] overflow-auto pr-1">
              {chat.length === 0 && (
                <p className="text-sm text-muted">No messages yet. Your conversation will appear here.</p>
              )}
              {chat.map((m, i) => (
                <div key={i} className={`text-sm ${m.role === "user" ? "text-foreground" : "text-muted"}`}>
                  <span className="px-2 py-0.5 rounded-full text-xs border border-foreground/20 mr-2">{m.role}</span>
                  {m.content}
                </div>
              ))}
            </div>
          </GlassCard>
        </div>
      </div>
    </div>
  )
}
