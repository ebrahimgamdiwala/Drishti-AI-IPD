"use client"
import React from "react"
import Spline from "@splinetool/react-spline"

export default function SplineBackground({ 
  scene = "https://prod.spline.design/cPH3NUuayeOwN-Xk/scene.splinecode",
  enableInteraction = true
}) {
  const wrapperRef = React.useRef(null)
  const splineRef = React.useRef(null)
  const [isLoaded, setIsLoaded] = React.useState(false)

  const handleLoad = React.useCallback((splineApp) => {
    splineRef.current = splineApp
    setIsLoaded(true)
    console.debug('Spline scene loaded successfully')
  }, [])

  // Prevent the Spline from zooming on wheel scroll while allowing the page to scroll.
  // We stop propagation of wheel events so Spline's internal wheel handler doesn't receive them.
  React.useEffect(() => {
    const el = wrapperRef.current
    if (!el) return

    const onWheel = (e) => {
      // don't prevent default (so page can still scroll) — just stop other listeners
      e.stopPropagation()
      // also stop immediate propagation to be extra sure
      if (typeof e.stopImmediatePropagation === 'function') e.stopImmediatePropagation()
    }

    el.addEventListener('wheel', onWheel, { capture: true, passive: true })

    return () => el.removeEventListener('wheel', onWheel, { capture: true })
  }, [])

  return (
    <div 
      ref={wrapperRef} 
      className="absolute inset-0"
      style={{
        // Hide watermark at bottom
        maskImage: 'linear-gradient(to bottom, black 0%, black 88%, transparent 100%)',
        WebkitMaskImage: 'linear-gradient(to bottom, black 0%, black 88%, transparent 100%)',
        zIndex: 1
      }}
    >
      <Spline 
        scene={scene} 
        onLoad={handleLoad}
        style={{ 
          width: '100%', 
          height: '100%',
          pointerEvents: enableInteraction ? 'auto' : 'none'
        }}
      />
      
      {/* Subtle overlay to improve text readability */}
      <div 
        className="absolute inset-0 bg-gradient-to-b from-black/5 via-transparent to-black/20 pointer-events-none z-10" 
        aria-hidden="true" 
      />

      {/* Watermark cover: visually hides the spline watermark at bottom-right
          Uses pointer-events-none so it doesn't block interactions with the canvas */}
      <div
        className="absolute right-4 bottom-4 w-36 h-12 bg-background pointer-events-none z-20 rounded-md"
        aria-hidden="true"
      />
      
    </div>
  )
}

