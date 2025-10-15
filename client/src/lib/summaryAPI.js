import api from './axiosConfig'

const summaryAPI = {
  auth: {
    signup: (payload) => api.post('/api/auth/signup', payload),
    login: (payload) => api.post('/api/auth/login', payload),
    verifyEmail: (payload) => api.post('/api/auth/verify-email', payload),
    forgotPassword: (payload) => api.post('/api/auth/forgot-password', payload),
    resetPassword: (payload) => api.post('/api/auth/reset-password', payload),
  },
  model: {
    analyze: (payload) => api.post('/api/model/analyze', payload),
    identify: (payload) => api.post('/api/model/identify', payload),
    health: () => api.get('/api/model/health'),
  },
  // Add more domains here: users, alerts, model, etc.
}

export default summaryAPI
