import Navbar from "../components/navbar.jsx"
import SplineBackground from "../components/spline-background.jsx"

export default function MainLayout({ children, translucentNav = false, isHomePage = false }) {
  return (
    <div className="min-h-screen bg-background text-foreground relative">
      {/* Global Spline background for non-homepage pages only */}
      {!isHomePage && <SplineBackground />}
      <Navbar translucent={translucentNav} />
      <main className={`relative z-10 ${isHomePage ? '' : 'pt-16'}`}>{children}</main>
    </div>
  )
}
