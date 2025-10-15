"use client"

import React from "react"
import { motion } from "framer-motion"
import { Link, useNavigate } from "react-router-dom"
import summaryAPI from "../lib/summaryAPI"

export default function Login() {
  const [email, setEmail] = React.useState("")
  const [password, setPassword] = React.useState("")
  const [loading, setLoading] = React.useState(false)
  const [error, setError] = React.useState(null)
  const navigate = useNavigate()

  const handleSubmit = async (e) => {
    e.preventDefault()
    setError(null)
    setLoading(true)
    try {
      // client-side validation
      const trimmedEmail = (email || '').trim().toLowerCase()
      if (!trimmedEmail) throw new Error('Email is required')
      const emailRe = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
      if (!emailRe.test(trimmedEmail)) throw new Error('Invalid email format')
      if (!password || password.length < 6) throw new Error('Password must be at least 6 characters')

      const { data } = await summaryAPI.auth.login({ email: trimmedEmail, password })
      // store token for subsequent requests
      if (data?.token) {
        try {
          localStorage.setItem('token', data.token)
        } catch (e) {}
      }
      // server should ideally return user/session info. For now redirect to dashboard
      navigate("/dashboard")
    } catch (err) {
      // axios error normalization
      const msg = err?.response?.data?.error || err?.response?.data?.message || err.message || 'Login failed'
      setError(msg)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="relative min-h-[100svh]">
      {/* Background provided by MainLayout -> SplineBackground */}

      <div className="min-h-[100svh] flex items-center justify-center px-6">
        <motion.div
          initial={{ opacity: 0, y: 12 }}
          animate={{ opacity: 1, y: 0 }}
          className="glass w-full max-w-md rounded-2xl border border-foreground/20 p-6"
        >
          <h2 className="heading text-2xl font-semibold mb-1">Welcome back</h2>
          <p className="text-sm text-muted mb-6">Sign in to continue</p>

          <form className="space-y-4" onSubmit={handleSubmit}>
            <div>
              <label className="text-sm mb-1 block">Email</label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                className="w-full rounded-lg bg-foreground/5 border border-foreground/20 px-3 py-2 outline-none focus:border-primary"
                placeholder="you@example.com"
              />
            </div>
            <div>
              <label className="text-sm mb-1 block">Password</label>
              <input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                className="w-full rounded-lg bg-foreground/5 border border-foreground/20 px-3 py-2 outline-none focus:border-primary"
                placeholder="••••••••"
              />
            </div>
            {error && <div className="text-sm text-rose-400">{error}</div>}
            <div className="flex items-center justify-between text-sm">
              <Link to="/forgot-password" className="text-muted hover:text-foreground underline">
                Forgot password?
              </Link>
              <button
                type="submit"
                disabled={loading}
                className="px-4 py-2 rounded-full bg-primary text-background border border-foreground/20 disabled:opacity-60"
              >
                {loading ? "Signing in..." : "Sign In"}
              </button>
            </div>
          </form>

          <p className="text-sm text-muted mt-4">
            No account?{" "}
            <Link to="/signup" className="underline hover:text-foreground">
              Sign up
            </Link>
          </p>
        </motion.div>
      </div>
    </div>
  )
}
