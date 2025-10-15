"use client"
import { BrowserRouter, Routes, Route, useLocation } from "react-router-dom"
import { AnimatePresence, motion } from "framer-motion"

import MainLayout from "./layouts/main-layout.jsx"
import Home from "./pages/home.jsx"
import Login from "./pages/login.jsx"
import Signup from "./pages/signup.jsx"
import UserDashboard from "./pages/user-dashboard.jsx"
import RelativeDashboard from "./pages/relative-dashboard.jsx"
import AdminDashboard from "./pages/admin-dashboard.jsx"
import ForgotPassword from "./pages/forgot-password.jsx"

function AnimatedRoutes() {
  const location = useLocation()
  return (
    <AnimatePresence mode="wait">
      <Routes location={location} key={location.pathname}>
        <Route
          path="/"
          element={
            <motion.div
              initial={{ clipPath: "circle(0% at 50% 0)" }}
              animate={{ clipPath: "circle(150% at 50% 0)" }}
              exit={{ clipPath: "circle(0% at 50% 0)" }}
              transition={{ duration: 0.5, ease: "easeInOut" }}
            >
              <MainLayout translucentNav isHomePage>
                <Home />
              </MainLayout>
            </motion.div>
          }
        />
        <Route
          path="/login"
          element={
            <motion.div 
              initial={{ clipPath: "circle(0% at 50% 0)" }}
              animate={{ clipPath: "circle(150% at 50% 0)" }}
              exit={{ clipPath: "circle(0% at 50% 0)" }}
              transition={{ duration: 0.5, ease: "easeInOut" }}
            >
              <MainLayout translucentNav>
                <Login />
              </MainLayout>
            </motion.div>
          }
        />
        <Route
          path="/signup"
          element={
            <motion.div 
              initial={{ clipPath: "circle(0% at 50% 0)" }}
              animate={{ clipPath: "circle(150% at 50% 0)" }}
              exit={{ clipPath: "circle(0% at 50% 0)" }}
              transition={{ duration: 0.5, ease: "easeInOut" }}
            >
              <MainLayout translucentNav>
                <Signup />
              </MainLayout>
            </motion.div>
          }
        />
        <Route
          path="/dashboard"
          element={
            <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}>
              <MainLayout>
                <UserDashboard />
              </MainLayout>
            </motion.div>
          }
        />
        <Route
          path="/relative"
          element={
            <motion.div
              initial={{ clipPath: "circle(0% at 50% 0)" }}
              animate={{ clipPath: "circle(150% at 50% 0)" }}
              exit={{ clipPath: "circle(0% at 50% 0)" }}
              transition={{ duration: 0.5, ease: "easeInOut" }}
            >
              <MainLayout>
                <RelativeDashboard />
              </MainLayout>
            </motion.div>
          }
        />
        <Route
          path="/admin"
          element={
            <motion.div
              initial={{ clipPath: "circle(0% at 50% 0)" }}
              animate={{ clipPath: "circle(150% at 50% 0)" }}
              exit={{ clipPath: "circle(0% at 50% 0)" }}
              transition={{ duration: 0.5, ease: "easeInOut" }}
            >
              <MainLayout>
                <AdminDashboard />
              </MainLayout>
            </motion.div>
          }
        />
        <Route
          path="/forgot-password"
          element={
            <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}>
              <MainLayout translucentNav>
                <ForgotPassword />
              </MainLayout>
            </motion.div>
          }
        />
        
      </Routes>
    </AnimatePresence>
  )
}

export default function App() {
  return (
    <BrowserRouter>
      <AnimatedRoutes />
    </BrowserRouter>
  )
}
