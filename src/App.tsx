import React from 'react'
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom'
import { SidebarProvider } from './contexts/SidebarContext'
import { ThemeProvider } from './contexts/ThemeContext'
import Sidebar from './components/Sidebar'
import Header from './components/Header'
import Dashboard from './pages/Dashboard'
import UserManagement from './pages/UserManagement'
import ContentModeration from './pages/ContentModeration'
import Analytics from './pages/Analytics'
import Settings from './pages/Settings'
import Login from './pages/Login'
import { AuthProvider } from './contexts/AuthContext'
import ProtectedRoute from './components/ProtectedRoute'

function App() {
  return (
    <ThemeProvider>
      <AuthProvider>
        <Router>
          <div className="min-h-screen bg-background text-foreground">
            <Routes>
              <Route path="/login" element={<Login />} />
              <Route
                path="/*"
                element={
                  <ProtectedRoute>
                    <SidebarProvider>
                      <div className="flex">
                        <Sidebar />
                        <div className="flex-1 flex flex-col">
                          <Header />
                          <main className="flex-1 p-6 overflow-auto bg-background">
                            <Routes>
                              <Route path="/" element={<Dashboard />} />
                              <Route path="/users" element={<UserManagement />} />
                              <Route path="/content" element={<ContentModeration />} />
                              <Route path="/analytics" element={<Analytics />} />
                              <Route path="/settings" element={<Settings />} />
                            </Routes>
                          </main>
                        </div>
                      </div>
                    </SidebarProvider>
                  </ProtectedRoute>
                }
              />
            </Routes>
          </div>
        </Router>
      </AuthProvider>
    </ThemeProvider>
  )
}

export default App
