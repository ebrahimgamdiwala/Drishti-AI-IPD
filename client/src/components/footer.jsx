import { Github, Linkedin, Mail, Globe } from "lucide-react"
import { Link } from "react-router-dom"

export default function Footer() {
  return (
    <footer className="bg-background/80 backdrop-blur-sm border-t border-foreground/10 py-8 mt-12 relative z-10">
      <div className="container mx-auto px-4">
        <div className="flex flex-col md:flex-row justify-between items-center">
          <div className="mb-6 md:mb-0">
            <Link to="/" className="flex items-center gap-2">
              <span className="inline-block h-3 w-3 rounded-full bg-primary" aria-hidden="true" />
              <span className="heading font-semibold text-lg">Drishti AI</span>
            </Link>
            <p className="mt-2 text-sm text-foreground/70">
              Vision Beyond Sight — Empowering the visually impaired with AI-driven assistance
            </p>
          </div>
          
          <div className="flex flex-col gap-4">
            <h3 className="font-medium text-base">Connect With Us</h3>
            <div className="flex gap-4">
              <a href="https://github.com/drishti-ai" target="_blank" rel="noopener noreferrer" 
                className="p-2 rounded-full bg-foreground/5 hover:bg-foreground/10 transition-colors">
                <Github size={20} />
                <span className="sr-only">GitHub</span>
              </a>
              <a href="https://linkedin.com/company/drishti-ai" target="_blank" rel="noopener noreferrer"
                className="p-2 rounded-full bg-foreground/5 hover:bg-foreground/10 transition-colors">
                <Linkedin size={20} />
                <span className="sr-only">LinkedIn</span>
              </a>
              <a href="mailto:contact@drishti-ai.com"
                className="p-2 rounded-full bg-foreground/5 hover:bg-foreground/10 transition-colors">
                <Mail size={20} />
                <span className="sr-only">Email</span>
              </a>
              <a href="https://drishti-ai.com" target="_blank" rel="noopener noreferrer"
                className="p-2 rounded-full bg-foreground/5 hover:bg-foreground/10 transition-colors">
                <Globe size={20} />
                <span className="sr-only">Website</span>
              </a>
            </div>
          </div>
        </div>
        
        <div className="mt-8 pt-4 border-t border-foreground/10 flex flex-col md:flex-row justify-between items-center">
          <p className="text-sm text-foreground/60">© {new Date().getFullYear()} Drishti AI. All rights reserved.</p>
          <div className="flex gap-4 mt-4 md:mt-0">
            <Link to="/privacy" className="text-sm text-foreground/60 hover:text-foreground">Privacy Policy</Link>
            <Link to="/terms" className="text-sm text-foreground/60 hover:text-foreground">Terms of Service</Link>
          </div>
        </div>
      </div>
    </footer>
  )
}