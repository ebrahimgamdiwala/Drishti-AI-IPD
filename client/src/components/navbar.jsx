"use client"

import React from "react"
import { Link, NavLink, useNavigate } from "react-router-dom"
import { AnimatePresence } from "framer-motion"
import { motion } from "framer-motion"
import AnimatedButton from "./animated-button"
import { Home, User, Users, ShieldAlert, LogIn, LogOut, UserCircle } from "lucide-react"

const baseNavItems = [
  { to: "/", label: "Home", icon: Home },
  { to: "/dashboard", label: "User", icon: User },
  { to: "/relative", label: "Relative", icon: Users },
  { to: "/admin", label: "Admin", icon: ShieldAlert },
]

export default function Navbar({ translucent = false }) {
  const [scrolled, setScrolled] = React.useState(false)
  const [open, setOpen] = React.useState(false)
  const [isLoggedIn, setIsLoggedIn] = React.useState(false)
  const [userData, setUserData] = React.useState(null)
  const navigate = useNavigate()

  React.useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 8)
    onScroll()
    window.addEventListener("scroll", onScroll, { passive: true })
    return () => window.removeEventListener("scroll", onScroll)
  }, [])

  // Check for authentication token on component mount
  React.useEffect(() => {
    const checkAuth = async () => {
      try {
        const token = localStorage.getItem('token')
        if (token) {
          setIsLoggedIn(true)
          // Fetch profile from server
          try {
            const res = await fetch('/api/users/me', {
              headers: { 'Authorization': `Bearer ${token}` }
            })
            if (res.ok) {
              const json = await res.json()
              setUserData({ name: json.user?.name || 'User', email: json.user?.email || '' })
            } else {
              setUserData({ name: 'User' })
            }
          } catch (e) {
            setUserData({ name: 'User' })
          }
        } else {
          setIsLoggedIn(false)
          setUserData(null)
        }
      } catch (e) {
        setIsLoggedIn(false)
        setUserData(null)
      }
    }
    
    checkAuth()
    // Listen for storage events (in case user logs in/out in another tab)
    window.addEventListener('storage', checkAuth)
    return () => window.removeEventListener('storage', checkAuth)
  }, [])

  const handleLogout = () => {
    try {
      localStorage.removeItem('token')
      setIsLoggedIn(false)
      setUserData(null)
      navigate('/')
    } catch (e) {
      console.error('Logout error:', e)
    }
  }

  // Dynamically build nav items based on auth state
  const navItems = [
    ...baseNavItems,
    ...(isLoggedIn 
          ? [{ 
          label: userData?.name || "Account", 
          icon: UserCircle,
          dropdown: true,
          items: [
            { label: userData?.email || '', onClick: null, icon: null },
            { label: "Logout", onClick: handleLogout, icon: LogOut }
          ]
        }] 
      : [{ to: "/login", label: "Login", icon: LogIn }]
    )
  ]

  const bgClass = scrolled || !translucent ? "bg-background/70 backdrop-blur-md" : "bg-transparent"

  return (
    <header className={`fixed inset-x-0 top-0 z-50 ${bgClass} border-b border-foreground/10 rounded-full mx-4 mt-2 shadow-lg shadow-primary/20`} role="banner">
      <nav
        className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between rounded-full"
        aria-label="Main Navigation"
      >
        <Link to="/" className="flex items-center gap-2">
          <span className="inline-block h-3 w-3 rounded-full bg-primary" aria-hidden="true" />
          <span className="heading font-semibold text-lg">Drishti AI</span>
        </Link>

        <div className="hidden md:flex items-center gap-3">
          {navItems.map((item, index) => {
            const Icon = item.icon
            
            // Handle dropdown menu for user account
            if (item.dropdown) {
              return (
                <div key={`dropdown-${index}`} className="relative group">
                  <AnimatedButton
                    as="div"
                    className="px-4 py-2 text-base rounded-full border border-foreground/20 flex items-center gap-2 bg-foreground/5 hover:bg-foreground/10"
                  >
                    <Icon size={18} />
                    {item.label}
                  </AnimatedButton>
                  
                  <div className="absolute right-0 mt-2 w-48 rounded-md shadow-lg bg-background/90 backdrop-blur-md border border-foreground/20 opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all duration-200 z-50">
                    <div className="py-1">
                      {item.items.map((subItem, subIndex) => {
                        const SubIcon = subItem.icon
                        return (
                          <button
                            key={`dropdown-item-${subIndex}`}
                            className="w-full text-left px-4 py-2 flex items-center gap-2 hover:bg-foreground/10"
                            onClick={subItem.onClick}
                          >
                            {SubIcon && <SubIcon size={16} />}
                            {subItem.label}
                          </button>
                        )
                      })}
                    </div>
                  </div>
                </div>
              )
            }
            
            // Regular nav link
            return (
              <NavLink key={item.to} to={item.to}>
                {({ isActive }) => (
                  <AnimatedButton
                    as="div"
                    className={`px-4 py-2 text-base rounded-full border border-foreground/20 flex items-center gap-2 ${
                      isActive ? "bg-primary text-background" : "bg-foreground/5 hover:bg-foreground/10"
                    }`}
                  >
                    <Icon size={18} />
                    {item.label}
                  </AnimatedButton>
                )}
              </NavLink>
            )
          })}
        </div>

        <button
          aria-label="Toggle menu"
          aria-expanded={open}
          className="md:hidden rounded-full border border-foreground/20 px-3 py-2 bg-foreground/5"
          onClick={() => setOpen((v) => !v)}
        >
          <span className="sr-only">Open menu</span>
          <div className="h-0.5 w-5 bg-foreground mb-1" />
          <div className="h-0.5 w-4 bg-foreground mb-1" />
          <div className="h-0.5 w-6 bg-foreground" />
        </button>
      </nav>

      <AnimatePresence>
        {open && (
          <motion.div
            initial={{ height: 0, opacity: 0 }}
            animate={{ height: "auto", opacity: 1 }}
            exit={{ height: 0, opacity: 0 }}
            className="md:hidden overflow-hidden border-t border-foreground/10"
          >
            <div className="px-4 py-3 flex flex-col gap-2 bg-background/80 backdrop-blur-md">
              {navItems.map((item, index) => {
                // Handle dropdown items for mobile
                if (item.dropdown) {
                  return (
                    <React.Fragment key={`mobile-dropdown-${index}`}>
                      <div className="px-4 py-2 rounded-full border text-sm bg-foreground/5 border-foreground/20">
                        {item.label}
                      </div>
                      {item.items.map((subItem, subIndex) => (
                        <button
                          key={`mobile-dropdown-item-${subIndex}`}
                          onClick={() => {
                            subItem.onClick();
                            setOpen(false);
                          }}
                          className="px-6 py-2 rounded-full border text-sm bg-foreground/5 hover:bg-foreground/10 border-foreground/20 ml-2"
                        >
                          {subItem.label}
                        </button>
                      ))}
                    </React.Fragment>
                  );
                }
                
                // Regular nav items
                return (
                  <NavLink key={item.to} to={item.to} onClick={() => setOpen(false)}>
                    {({ isActive }) => (
                      <div
                        className={`px-4 py-2 rounded-full border text-sm ${
                          isActive
                            ? "bg-primary text-background border-foreground/20"
                            : "bg-foreground/5 hover:bg-foreground/10 border-foreground/20"
                        }`}
                      >
                        {item.label}
                      </div>
                    )}
                  </NavLink>
                );
              })}
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </header>
  )
}
