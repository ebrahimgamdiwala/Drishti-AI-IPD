"use client"

import React from "react"
import GlassCard from "../components/glass-card.jsx"
import CameraFeed from "../components/camera-feed.jsx"
import { toast } from "../components/ui/use-toast.js"
import summaryAPI from "../lib/summaryAPI"

export default function RelativeDashboard() {
  const [relatives, setRelatives] = React.useState([])
  const [loading, setLoading] = React.useState(true)
  const [showCamera, setShowCamera] = React.useState(false)
  const [currentUserId, setCurrentUserId] = React.useState(null)
  const [newRelative, setNewRelative] = React.useState({
    name: "",
    relationship: "",
    notes: ""
  })
  const cameraRef = React.useRef(null)

  // Fetch relatives on component mount
  React.useEffect(() => {
    fetchProfileThenRelatives()
  }, [])

  const fetchProfileThenRelatives = async () => {
    try {
      const token = localStorage.getItem('token')
      if (!token) return fetchRelatives()
      const res = await fetch('/api/users/me', { headers: { 'Authorization': `Bearer ${token}` } })
      if (res.ok) {
        const json = await res.json()
        setCurrentUserId(json.user?._id || null)
      }
    } catch (e) {
      // ignore profile fetch errors
    } finally {
      fetchRelatives()
    }
  }

  const fetchRelatives = async () => {
    try {
      setLoading(true)
      const token = localStorage.getItem('token')
      if (!token) {
        toast({
          title: "Authentication Error",
          description: "Please log in to view relatives",
          variant: "destructive",
        })
        setLoading(false)
        return
      }

      const response = await fetch('/api/known-persons', {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      })
      
      if (response.ok) {
        const data = await response.json()
        setRelatives(Array.isArray(data.knownPersons) ? data.knownPersons : [])
      } else {
        toast({
          title: "Error",
          description: "Failed to fetch relatives",
          variant: "destructive",
        })
      }
    } catch (error) {
      console.error("Error fetching relatives:", error)
      toast({
        title: "Error",
        description: "Failed to fetch relatives",
        variant: "destructive",
      })
    } finally {
      setLoading(false)
    }
  }

  const captureImageDataUrl = React.useCallback(() => {
    const el = cameraRef.current
    if (!el) return null
    
    try {
      const video = el.querySelector("video")
      const canvas = document.createElement("canvas")
      if (!video || !video.videoWidth) return null
      canvas.width = video.videoWidth
      canvas.height = video.videoHeight
      const ctx = canvas.getContext("2d")
      ctx.drawImage(video, 0, 0, canvas.width, canvas.height)
      const dataUrl = canvas.toDataURL("image/jpeg", 0.9)
      return dataUrl
    } catch (err) {
      console.error("Snapshot error:", err)
      return null
    }
  }, [])

  const handleAddRelative = async (e) => {
    e.preventDefault()
    
    if (!newRelative.name || !newRelative.relationship) {
      toast({
        title: "Missing Information",
        description: "Please provide name and relationship",
        variant: "destructive",
      })
      return
    }
    
    const imageData = captureImageDataUrl()
    if (!imageData) {
      toast({
        title: "Error",
        description: "Failed to capture image",
        variant: "destructive",
      })
      return
    }
    
    try {
      const token = localStorage.getItem('token')
      if (!token) {
        toast({
          title: "Authentication Error",
          description: "Please log in to add relatives",
          variant: "destructive",
        })
        return
      }
      
      // Convert base64 to blob for form data
      const base64Response = await fetch(imageData)
      const blob = await base64Response.blob()
      
      const formData = new FormData()
      formData.append('name', newRelative.name)
      formData.append('relationship', newRelative.relationship)
      formData.append('notes', newRelative.notes)
      if (currentUserId) formData.append('forUserId', currentUserId)
      // Backend expects field name 'images' (array); single upload still works
      formData.append('images', blob, 'relative.jpg')
      
      const response = await fetch('/api/known-persons', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`
        },
        body: formData
      })
      
      if (response.ok) {
        toast({
          title: "Success",
          description: "Relative added successfully",
        })
        setNewRelative({
          name: "",
          relationship: "",
          notes: ""
        })
        setShowCamera(false)
        fetchRelatives()
      } else {
        const errorData = await response.json()
        toast({
          title: "Error",
          description: errorData.error || "Failed to add relative",
          variant: "destructive",
        })
      }
    } catch (error) {
      console.error("Error adding relative:", error)
      toast({
        title: "Error",
        description: "Failed to add relative",
        variant: "destructive",
      })
    }
  }

  const handleUploadImages = async (relativeId) => {
    try {
      const token = localStorage.getItem('token')
      if (!token) {
        toast({ title: 'Authentication Error', description: 'Please log in to upload photos', variant: 'destructive' })
        return
      }

      const picker = document.createElement('input')
      picker.type = 'file'
      picker.accept = 'image/*'
      picker.multiple = true
      picker.onchange = async (e) => {
        const files = Array.from(e.target.files || [])
        if (files.length === 0) return
        const form = new FormData()
        files.forEach((f) => form.append('images', f))

        const res = await fetch(`/api/known-persons/${relativeId}/images`, {
          method: 'POST',
          headers: { 'Authorization': `Bearer ${token}` },
          body: form
        })

        if (res.ok) {
          toast({ title: 'Photos added', description: 'Images uploaded successfully' })
          fetchRelatives()
        } else {
          const err = await res.json().catch(() => ({}))
          toast({ title: 'Upload failed', description: err.error || 'Could not upload images', variant: 'destructive' })
        }
      }
      picker.click()
    } catch (error) {
      console.error('Upload images error:', error)
      toast({ title: 'Error', description: 'Failed to upload images', variant: 'destructive' })
    }
  }

  return (
    <div className="mx-auto max-w-7xl px-6 py-10 space-y-6">
      <div className="grid lg:grid-cols-3 gap-6">
        <GlassCard className="p-4 lg:col-span-2">
          <div className="flex items-center justify-between">
            <h3 className="heading font-semibold">My Relatives</h3>
            <button 
              className="px-4 py-2 rounded-full bg-primary text-background border border-foreground/20"
              onClick={() => setShowCamera(!showCamera)}
            >
              {showCamera ? "Cancel" : "Add New Relative"}
            </button>
          </div>
          
          {showCamera && (
            <div className="mt-4">
              <form onSubmit={handleAddRelative} className="space-y-4">
                <div className="grid md:grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm mb-1">Name</label>
                    <input 
                      type="text" 
                      value={newRelative.name}
                      onChange={(e) => setNewRelative({...newRelative, name: e.target.value})}
                      className="w-full p-2 rounded-md bg-foreground/5 border border-foreground/20"
                      placeholder="Relative's name"
                    />
                  </div>
                  <div>
                    <label className="block text-sm mb-1">Relationship</label>
                    <input 
                      type="text" 
                      value={newRelative.relationship}
                      onChange={(e) => setNewRelative({...newRelative, relationship: e.target.value})}
                      className="w-full p-2 rounded-md bg-foreground/5 border border-foreground/20"
                      placeholder="e.g. Parent, Sibling, etc."
                    />
                  </div>
                </div>
                <div>
                  <label className="block text-sm mb-1">Notes (Optional)</label>
                  <textarea 
                    value={newRelative.notes}
                    onChange={(e) => setNewRelative({...newRelative, notes: e.target.value})}
                    className="w-full p-2 rounded-md bg-foreground/5 border border-foreground/20"
                    placeholder="Any additional information"
                    rows={2}
                  />
                </div>
                <div ref={cameraRef}>
                  <label className="block text-sm mb-1">Capture Photo</label>
                  <CameraFeed className="aspect-video bg-foreground/5" />
                </div>
                <div className="flex justify-end">
                  <button 
                    type="submit" 
                    className="px-4 py-2 rounded-full bg-accent text-background border border-foreground/20"
                  >
                    Save Relative
                  </button>
                </div>
              </form>
            </div>
          )}
          
          <div className="mt-4 grid sm:grid-cols-2 lg:grid-cols-3 gap-3">
            {loading ? (
              <div className="col-span-full text-center py-8">Loading relatives...</div>
            ) : relatives.length > 0 ? (
              relatives.map((relative) => (
                <div key={relative._id} className="glass rounded-xl p-3 border border-foreground/20">
                  {relative.images && relative.images.length > 0 && (
                    <div className="mb-2">
                      <img 
                        src={relative.images[0].path.startsWith('http') ? relative.images[0].path : `/api${relative.images[0].path}`} 
                        alt={relative.name} 
                        className="w-full h-32 object-cover rounded-lg"
                      />
                    </div>
                  )}
                  <p className="font-semibold">{relative.name}</p>
                  <p className="text-sm text-muted">{relative.relationship}</p>
                  {relative.notes && <p className="text-xs mt-1">{relative.notes}</p>}
                  <div className="mt-2 flex items-center gap-2">
                    <button
                      onClick={() => handleUploadImages(relative._id)}
                      className="px-3 py-1.5 rounded-full bg-foreground/5 hover:bg-foreground/10 border border-foreground/20 text-sm"
                    >
                      Add Photos
                    </button>
                  </div>
                </div>
              ))
            ) : (
              <div className="col-span-full text-center py-8">
                No relatives added yet. Add your first relative using the button above.
              </div>
            )}
          </div>
        </GlassCard>

        <GlassCard className="p-4">
          <h3 className="heading font-semibold">Alerts</h3>
          <div className="mt-3 space-y-2">
            <div className="glass rounded-lg p-3 border border-foreground/20">
              <p className="text-sm">
                <span className="text-muted">10:22</span> — Close call detected at crosswalk.
              </p>
            </div>
            <div className="glass rounded-lg p-3 border border-foreground/20">
              <p className="text-sm">
                <span className="text-muted">14:05</span> — Obstacle detected on pathway.
              </p>
            </div>
          </div>
        </GlassCard>
      </div>

      <GlassCard className="p-4">
        <h3 className="heading font-semibold">Email Notification Settings</h3>
        <div className="mt-3 space-y-3">
          <div className="flex items-center">
            <input type="checkbox" id="alert-critical" className="mr-2" />
            <label htmlFor="alert-critical" className="text-sm">Critical Alerts</label>
          </div>
          <div className="flex items-center">
            <input type="checkbox" id="alert-warning" className="mr-2" />
            <label htmlFor="alert-warning" className="text-sm">Warning Alerts</label>
          </div>
          <div className="flex items-center">
            <input type="checkbox" id="alert-daily" className="mr-2" />
            <label htmlFor="alert-daily" className="text-sm">Daily Summary</label>
          </div>
        </div>
      </GlassCard>
    </div>
  )
}
