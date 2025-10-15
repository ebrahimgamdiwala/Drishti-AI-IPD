import { motion } from "framer-motion"

export default function AnimatedButton({ children, className = "", as = "button", ...props }) {
  const Comp = motion[as] || motion.button
  return (
    <Comp
      whileHover={{ scale: 1.04, y: -1 }}
      whileTap={{ scale: 0.98 }}
      className={`rounded-full border border-foreground/20 bg-foreground/5 text-foreground ${className}`}
      {...props}
    >
      {children}
    </Comp>
  )
}