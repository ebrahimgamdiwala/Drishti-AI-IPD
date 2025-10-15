"use client"
import { motion } from "framer-motion"
import { useEffect, useState } from "react"

export default function GlassCard({ children, className = "", tint = "foreground/5", ...props }) {
  const [rotation, setRotation] = useState(0)
  
  useEffect(() => {
    const interval = setInterval(() => {
      setRotation(prev => (prev + 1) % 360)
    }, 50)
    
    return () => clearInterval(interval)
  }, [])
  
  return (
    <motion.div
      initial={{ opacity: 0, y: 12, scale: 0.98 }}
      whileInView={{ opacity: 1, y: 0, scale: 1 }}
      viewport={{ once: true, amount: 0.2 }}
      transition={{ duration: 0.35 }}
      className={`glass rounded-xl bg-${tint} ${className} relative overflow-hidden shadow-lg shadow-primary/30`}
      style={{
        position: 'relative',
        borderWidth: '2px',
        borderStyle: 'solid',
        borderImage: `conic-gradient(from ${rotation}deg, transparent, rgba(120, 220, 255, 0.3) 20%, rgba(120, 220, 255, 0.6) 25%, rgba(120, 220, 255, 0.3) 30%, transparent 40%) 1`
      }}
      {...props}
    >
      <div className="relative z-10">
        {children}
      </div>
    </motion.div>
  )
}
