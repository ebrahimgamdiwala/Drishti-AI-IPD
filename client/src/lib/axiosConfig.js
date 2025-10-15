import axios from 'axios'

const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL || '',
  timeout: Number(import.meta.env.VITE_API_TIMEOUT) || 300000,
  withCredentials: true,
  headers: {
    'Content-Type': 'application/json',
  },
})

// Optional: response interceptor to handle common errors
api.interceptors.response.use(
  (res) => res,
  (err) => {
    // normalize error shape
    return Promise.reject(err)
  },
)

// Request interceptor to attach Authorization header when a token exists in localStorage
api.interceptors.request.use(
  (config) => {
    try {
      const token = localStorage.getItem('token')
      if (token) {
        config.headers = config.headers || {}
        config.headers.Authorization = `Bearer ${token}`
      }
    } catch (e) {
      // ignore
    }
    return config
  },
  (err) => Promise.reject(err),
)

export default api
