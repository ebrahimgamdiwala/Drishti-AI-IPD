"use client"

import React from "react"

const constraints = { video: { facingMode: "environment" }, audio: false }

function useAsyncEffect(effect, deps) {
  React.useEffect(() => {
    let cleanup
    const run = async () => {
      cleanup = await effect()
    }
    run()
    return () => {
      if (typeof cleanup === "function") cleanup()
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, deps)
}

export default function CameraFeed({ className = "", onReady }) {
  const videoRef = React.useRef(null)
  const canvasRef = React.useRef(null)

  useAsyncEffect(async () => {
    try {
      const stream = await navigator.mediaDevices.getUserMedia(constraints)
      if (videoRef.current) {
        videoRef.current.srcObject = stream
        await videoRef.current.play()
        onReady?.()
      }
      return () => {
        stream.getTracks().forEach((t) => t.stop())
      }
    } catch (err) {
      console.error("[v0] Camera error:", err)
    }
  }, [])

  // Expose capture function via ref
  React.useImperativeHandle(
    CameraFeed.ref,
    () => ({
      captureFrame: () => {
        const video = videoRef.current
        const canvas = canvasRef.current
        if (!video || !canvas) return null
        canvas.width = video.videoWidth
        canvas.height = video.videoHeight
        const ctx = canvas.getContext("2d")
        ctx.drawImage(video, 0, 0, canvas.width, canvas.height)
        return canvas.toDataURL("image/jpeg", 0.9)
      },
    }),
    [],
  )

  // Alternative: return capture function as method on element ref
  const captureFrame = React.useCallback(() => {
    const video = videoRef.current
    const canvas = canvasRef.current
    if (!video || !canvas) return null
    canvas.width = video.videoWidth
    canvas.height = video.videoHeight
    const ctx = canvas.getContext("2d")
    ctx.drawImage(video, 0, 0, canvas.width, canvas.height)
    return canvas.toDataURL("image/jpeg", 0.9)
  }, [])

  return (
    <div className={`relative overflow-hidden rounded-xl ${className}`}>
      <video
        ref={videoRef}
        className="w-full h-full object-cover rounded-xl shadow-lg shadow-primary/30 z-10"
        playsInline
        muted
        autoPlay
        aria-label="Live camera preview"
      />
      <canvas ref={canvasRef} className="hidden" />
      {/* Provide captureFrame for parent via render prop pattern as well */}
      <div className="sr-only" aria-hidden="true" data-capture-provider>
        {/* Parent can query this component via ref + captureFrame */}
      </div>
      {/* Expose captureFrame function through a prop callback if needed (no DOM value) */}
    </div>
  )
}
