"use client"

import React from "react"
import { motion } from "framer-motion"
import { Link, useNavigate } from "react-router-dom"
import summaryAPI from "../lib/summaryAPI"

const roles = ["User", "Relative", "Admin"]

export default function Signup() {
  const [role, setRole] = React.useState("User")
  const [firstName, setFirstName] = React.useState("")
  const [lastName, setLastName] = React.useState("")
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
      const name = `${firstName || ''} ${lastName || ''}`.trim()
      if (!name) throw new Error('Name is required')

      // normalize role to server-expected values
      const normRole = (role || 'User').toLowerCase()

      await summaryAPI.auth.signup({
        name,
        email,
        password,
        role: normRole,
      })
      // After successful signup redirect to login page
      navigate("/login")
    } catch (err) {
      const msg = err?.response?.data?.error || err?.response?.data?.message || err.message || 'Signup failed'
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
          className="glass w-full max-w-lg rounded-2xl border border-foreground/20 p-6"
        >
          <h2 className="heading text-2xl font-semibold mb-1">Create account</h2>
          <p className="text-sm text-muted mb-6">Choose your role and sign up</p>

          <div className="grid grid-cols-3 gap-2 mb-4">
            {roles.map((r) => {
              const active = r === role
              return (
                <button
                  key={r}
                  type="button"
                  onClick={() => setRole(r)}
                  className={`rounded-xl px-3 py-2 border ${
                    active
                      ? "bg-primary text-background border-foreground/20"
                      : "bg-foreground/5 hover:bg-foreground/10 border-foreground/20"
                  }`}
                  aria-pressed={active}
                >
                  {r}
                </button>
              )
            })}
          </div>

          <form className="space-y-4" onSubmit={handleSubmit}>
            <div className="grid md:grid-cols-2 gap-3">
              <div>
                <label className="text-sm mb-1 block">First name</label>
                <input
                  value={firstName}
                  onChange={(e) => setFirstName(e.target.value)}
                  className="w-full rounded-lg bg-foreground/5 border border-foreground/20 px-3 py-2 outline-none focus:border-primary"
                />
              </div>
              <div>
                <label className="text-sm mb-1 block">Last name</label>
                <input
                  value={lastName}
                  onChange={(e) => setLastName(e.target.value)}
                  className="w-full rounded-lg bg-foreground/5 border border-foreground/20 px-3 py-2 outline-none focus:border-primary"
                />
              </div>
            </div>
            <div>
              <label className="text-sm mb-1 block">Email</label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                className="w-full rounded-lg bg-foreground/5 border border-foreground/20 px-3 py-2 outline-none focus:border-primary"
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
              />
            </div>
            {error && <div className="text-sm text-rose-400">{error}</div>}
            <button
              type="submit"
              disabled={loading}
              className="w-full rounded-full py-2 bg-primary text-background border border-foreground/20 disabled:opacity-60"
            >
              {loading ? `Signing up...` : `Sign Up as ${role}`}
            </button>
          </form>

          <p className="text-sm text-muted mt-4">
            Have an account?{" "}
            <Link to="/login" className="underline hover:text-foreground">
              Sign in
            </Link>
          </p>
        </motion.div>
      </div>
    </div>
  )
}
