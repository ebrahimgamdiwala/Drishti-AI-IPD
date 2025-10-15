"use client"

export default function ForgotPassword() {
  return (
    <div className="min-h-[70svh] flex items-center justify-center px-6">
      <div className="glass w-full max-w-md rounded-2xl border border-foreground/20 p-6">
        <h2 className="heading text-2xl font-semibold mb-1">Forgot password</h2>
        <p className="text-sm text-muted mb-6">We’ll send you a reset link.</p>

        <form className="space-y-4" onSubmit={(e) => e.preventDefault()}>
          <div>
            <label className="text-sm mb-1 block">Email</label>
            <input
              type="email"
              required
              className="w-full rounded-lg bg-foreground/5 border border-foreground/20 px-3 py-2 outline-none focus:border-primary"
              placeholder="you@example.com"
            />
          </div>
          <button
            type="submit"
            className="w-full rounded-full py-2 bg-primary text-background border border-foreground/20"
          >
            Send reset link
          </button>
        </form>

        <p className="text-xs text-muted mt-3">Resend support is a placeholder pending backend integration.</p>
      </div>
    </div>
  )
}
