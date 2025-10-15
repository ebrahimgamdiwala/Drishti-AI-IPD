"use client"

import React from 'react'
import summaryAPI from '../lib/summaryAPI'

// Initial detailed system prompt for Ollama
const initialPrompt = `You are Drishti, an AI assistant whose primary user is a blind or visually impaired person. Your role is to:
- Provide clear, concise, and accessible descriptions of visual content.
- Offer step-by-step guidance for interacting with physical spaces, apps, and interfaces.
- Use non-visual cues (time estimates, spatial directions like "to your left/right") and avoid referencing visuals without description.
- Ask clarifying questions when information is missing, and confirm before making assumptions that could impact safety.
- Be empathetic, patient, and prioritize the user's autonomy and privacy.

When describing images, include:
- The overall scene summary (one concise sentence).
- Key objects, people, and their actions, including approximate positions and relationships.
- Any text present (transcribe) and styling cues if relevant (e.g., "a red sign that says 'STOP'").
- Confidence estimates for uncertain details.

Always adapt your level of detail based on the user's follow-up requests.`

export default function OllamaPage() {
  const [prompt, setPrompt] = React.useState(initialPrompt)
  const [response, setResponse] = React.useState(null)
  const [loading, setLoading] = React.useState(false)
  const [health, setHealth] = React.useState(null)
  const [error, setError] = React.useState(null)

  React.useEffect(() => {
    fetchHealth()
  }, [])

  const fetchHealth = async () => {
    try {
      const { data } = await summaryAPI.model.health()
      setHealth(data)
    } catch (err) {
      setHealth({ available: false, error: err?.message || 'Health check failed' })
    }
  }

  const handleAnalyze = async () => {
    setError(null)
    setLoading(true)
    try {
      // For now send prompt without image; the analyze endpoint requires image+prompt in production
      const { data } = await summaryAPI.model.analyze({ image: null, prompt })
      setResponse(data)
    } catch (err) {
      setError(err?.response?.data?.error || err?.message || 'Analysis failed')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="p-6">
      <h1 className="text-2xl font-semibold mb-4">Ollama Assistant</h1>

      <div className="mb-4">
        <h2 className="font-medium">Model Health</h2>
        <pre className="bg-foreground/5 p-3 rounded mt-2">{JSON.stringify(health, null, 2)}</pre>
      </div>

      <div className="mb-4">
        <h2 className="font-medium">Prompt</h2>
        <textarea value={prompt} onChange={(e) => setPrompt(e.target.value)} rows={10} className="w-full p-3 rounded bg-foreground/5" />
      </div>

      <div className="flex gap-2 mb-4">
        <button onClick={handleAnalyze} disabled={loading} className="px-4 py-2 bg-primary text-background rounded">{loading ? 'Analyzing...' : 'Analyze'}</button>
        <button onClick={() => setPrompt(initialPrompt)} className="px-4 py-2 border rounded">Reset Prompt</button>
      </div>

      {error && <div className="text-rose-400">{error}</div>}

      {response && (
        <div>
          <h2 className="font-medium">Response</h2>
          <pre className="bg-foreground/5 p-3 rounded mt-2">{JSON.stringify(response, null, 2)}</pre>
        </div>
      )}
    </div>
  )
}
