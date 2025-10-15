"use client"
import { motion } from "framer-motion"
import GlassCard from "../components/glass-card.jsx"
import AnimatedButton from "../components/animated-button.jsx"
import SplineBackground from "../components/spline-background.jsx"
import { Link } from "react-router-dom"

export default function Home() {
  return (
    <div className="relative w-full min-h-screen">
      {/* Hero with Spline background */}
      <section className="relative h-screen w-full overflow-hidden">
        {/* Spline background layer */}
        <div className="absolute inset-0 z-0">
          <SplineBackground />
        </div>

        {/* Content layer (let pointer events pass through to Spline) */}
        <div className="absolute inset-0 flex flex-col items-start justify-center px-12 z-20 pointer-events-none">
          <div className="max-w-md">
            <h1 className="heading text-5xl md:text-7xl font-bold mb-4 text-balance text-white drop-shadow-[0_0_10px_rgba(255,255,255,0.7)]">Drishti AI</h1>
            <p className="text-lg md:text-2xl text-white max-w-2xl mb-8 drop-shadow-[0_0_8px_rgba(255,255,255,0.7)]">
              Vision Beyond Sight — empowering the visually impaired with AI-driven assistance.
            </p>
            <AnimatedButton
              className="px-6 py-3 bg-foreground/10 hover:bg-foreground/20 rounded-full pointer-events-auto"
              onClick={() => document.getElementById("features")?.scrollIntoView({ behavior: "smooth" })}
            >
              Explore Features
            </AnimatedButton>
            <div className="mt-4">
              <Link to="/signup" className="text-sm text-white underline hover:text-foreground pointer-events-auto">
                Get Started
              </Link>
            </div>
          </div>
        </div>
      </section>

      {/* Features */}
      <section id="features" className="mx-auto max-w-6xl px-6 py-20">
        <div className="grid md:grid-cols-3 gap-6">
          <GlassCard className="p-6">
            <motion.div initial={{ scale: 0.95 }} whileHover={{ scale: 1.02 }}>
              <div className="h-10 w-10 rounded-full bg-primary/20 border border-primary/40 flex items-center justify-center mb-3">
                <span className="sr-only">Voice</span>
                <div className="h-3 w-3 rounded-full bg-primary" />
              </div>
              <h3 className="heading font-semibold mb-2">Voice Interaction</h3>
              <p className="text-sm text-muted">Hands-free control with hotword detection and natural commands.</p>
            </motion.div>
          </GlassCard>

          <GlassCard className="p-6">
            <motion.div initial={{ scale: 0.95 }} whileHover={{ scale: 1.02 }}>
              <div className="h-10 w-10 rounded-full bg-accent/20 border border-accent/40 flex items-center justify-center mb-3">
                <span className="sr-only">Image</span>
                <div className="h-3 w-3 rounded-full bg-accent" />
              </div>
              <h3 className="heading font-semibold mb-2">Image Recognition</h3>
              <p className="text-sm text-muted">Capture scenes to receive rich, accessible descriptions in seconds.</p>
            </motion.div>
          </GlassCard>

          <GlassCard className="p-6">
            <motion.div initial={{ scale: 0.95 }} whileHover={{ scale: 1.02 }}>
              <div className="h-10 w-10 rounded-full bg-foreground/10 border border-foreground/30 flex items-center justify-center mb-3">
                <span className="sr-only">Realtime</span>
                <div className="h-3 w-3 rounded-full bg-foreground" />
              </div>
              <h3 className="heading font-semibold mb-2">Real-time Assistance</h3>
              <p className="text-sm text-muted">Continuous guidance through live camera feed and voice.</p>
            </motion.div>
          </GlassCard>
        </div>
      </section>

      {/* How It Works */}
      <section className="py-20 px-6 bg-gradient-to-b from-background/50 to-background">
        <div className="max-w-6xl mx-auto">
          <motion.div 
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
            className="text-center mb-16"
          >
            <h2 className="heading text-4xl md:text-5xl font-bold mb-4">How Drishti AI Works</h2>
            <p className="text-lg text-muted max-w-2xl mx-auto">
              Our AI-powered assistant provides seamless interaction through voice commands and visual recognition.
            </p>
          </motion.div>

          <div className="grid md:grid-cols-3 gap-8">
            <motion.div 
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6, delay: 0.1 }}
              className="text-center"
            >
              <GlassCard className="p-8 h-full">
                <div className="w-16 h-16 rounded-full bg-primary/20 border border-primary/40 flex items-center justify-center mx-auto mb-6">
                  <span className="text-2xl">🎤</span>
                </div>
                <h3 className="heading text-xl font-semibold mb-4">Step 1: Voice Activation</h3>
                <p className="text-muted">
                  Simply say "Hey Drishti" to activate the assistant. No need to touch anything - just speak naturally.
                </p>
              </GlassCard>
            </motion.div>

            <motion.div 
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6, delay: 0.2 }}
              className="text-center"
            >
              <GlassCard className="p-8 h-full">
                <div className="w-16 h-16 rounded-full bg-accent/20 border border-accent/40 flex items-center justify-center mx-auto mb-6">
                  <span className="text-2xl">📷</span>
                </div>
                <h3 className="heading text-xl font-semibold mb-4">Step 2: Capture Scene</h3>
                <p className="text-muted">
                  The camera captures your surroundings and our AI analyzes the scene in real-time.
                </p>
              </GlassCard>
            </motion.div>

            <motion.div 
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6, delay: 0.3 }}
              className="text-center"
            >
              <GlassCard className="p-8 h-full">
                <div className="w-16 h-16 rounded-full bg-foreground/10 border border-foreground/30 flex items-center justify-center mx-auto mb-6">
                  <span className="text-2xl">🔊</span>
                </div>
                <h3 className="heading text-xl font-semibold mb-4">Step 3: Audio Description</h3>
                <p className="text-muted">
                  Receive detailed, contextual descriptions of your environment through clear audio feedback.
                </p>
              </GlassCard>
            </motion.div>
          </div>
        </div>
      </section>

      {/* Testimonials */}
      <section className="py-20 px-6">
        <div className="max-w-6xl mx-auto">
          <motion.div 
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
            className="text-center mb-16"
          >
            <h2 className="heading text-4xl md:text-5xl font-bold mb-4">What Users Say</h2>
            <p className="text-lg text-muted max-w-2xl mx-auto">
              Hear from the community about how Drishti AI has transformed their daily experience.
            </p>
          </motion.div>

          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
            <motion.div 
              initial={{ opacity: 0, scale: 0.9 }}
              whileInView={{ opacity: 1, scale: 1 }}
              transition={{ duration: 0.5, delay: 0.1 }}
            >
              <GlassCard className="p-6 h-full">
                <div className="flex items-center mb-4">
                  <div className="w-12 h-12 rounded-full bg-primary/20 flex items-center justify-center mr-4">
                    <span className="text-lg font-bold">S</span>
                  </div>
                  <div>
                    <h4 className="font-semibold">Sarah M.</h4>
                    <p className="text-sm text-muted">Teacher</p>
                  </div>
                </div>
                <p className="text-sm text-muted italic">
                  "Drishti AI has given me independence I never thought possible. Navigation and daily tasks are so much easier now."
                </p>
              </GlassCard>
            </motion.div>

            <motion.div 
              initial={{ opacity: 0, scale: 0.9 }}
              whileInView={{ opacity: 1, scale: 1 }}
              transition={{ duration: 0.5, delay: 0.2 }}
            >
              <GlassCard className="p-6 h-full">
                <div className="flex items-center mb-4">
                  <div className="w-12 h-12 rounded-full bg-accent/20 flex items-center justify-center mr-4">
                    <span className="text-lg font-bold">M</span>
                  </div>
                  <div>
                    <h4 className="font-semibold">Michael R.</h4>
                    <p className="text-sm text-muted">Student</p>
                  </div>
                </div>
                <p className="text-sm text-muted italic">
                  "The voice recognition is incredibly accurate. It understands my needs and responds instantly."
                </p>
              </GlassCard>
            </motion.div>

            <motion.div 
              initial={{ opacity: 0, scale: 0.9 }}
              whileInView={{ opacity: 1, scale: 1 }}
              transition={{ duration: 0.5, delay: 0.3 }}
            >
              <GlassCard className="p-6 h-full">
                <div className="flex items-center mb-4">
                  <div className="w-12 h-12 rounded-full bg-foreground/10 flex items-center justify-center mr-4">
                    <span className="text-lg font-bold">A</span>
                  </div>
                  <div>
                    <h4 className="font-semibold">Alex K.</h4>
                    <p className="text-sm text-muted">Professional</p>
                  </div>
                </div>
                <p className="text-sm text-muted italic">
                  "Game-changer for my work environment. The real-time descriptions help me navigate complex spaces confidently."
                </p>
              </GlassCard>
            </motion.div>
          </div>
        </div>
      </section>

      {/* Call to Action */}
      <section className="py-20 px-6 bg-gradient-to-t from-background/50 to-background">
        <div className="max-w-4xl mx-auto text-center">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
          >
            <GlassCard className="p-12">
              <h2 className="heading text-4xl md:text-5xl font-bold mb-6">
                Ready to Experience Vision Beyond Sight?
              </h2>
              <p className="text-lg text-muted mb-8 max-w-2xl mx-auto">
                Join thousands of users who have already discovered the freedom that Drishti AI provides. 
                Start your journey today with our easy-to-use platform.
              </p>
              <div className="flex flex-col sm:flex-row gap-4 justify-center">
                <Link to="/signup">
                  <AnimatedButton className="px-8 py-3 bg-primary hover:bg-primary/80 text-primary-foreground rounded-full font-semibold">
                    Get Started Free
                  </AnimatedButton>
                </Link>
                <AnimatedButton 
                  className="px-8 py-3 bg-transparent border border-foreground/20 hover:bg-foreground/10 rounded-full"
                  onClick={() => document.getElementById("features")?.scrollIntoView({ behavior: "smooth" })}
                >
                  Learn More
                </AnimatedButton>
              </div>
            </GlassCard>
          </motion.div>
        </div>
      </section>
    </div>
  )
}
