import React, { createContext, useContext, useState, useEffect } from 'react';

const AuthContext = createContext(null);

const ALLOWED_EMAIL = 'igandhivishal@gmail.com';
const STORAGE_KEY = 'docusaurus_auth_user';

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}

export default function Root({ children }) {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Check for existing session on mount
    try {
      const savedUser = localStorage.getItem(STORAGE_KEY);
      if (savedUser) {
        const parsedUser = JSON.parse(savedUser);
        // Validate the saved user has the allowed email
        if (parsedUser && parsedUser.email === ALLOWED_EMAIL) {
          setUser(parsedUser);
        } else {
          // Invalid user data, clear it
          localStorage.removeItem(STORAGE_KEY);
        }
      }
    } catch (error) {
      console.error('Error restoring auth session:', error);
      localStorage.removeItem(STORAGE_KEY);
    }
    setLoading(false);
  }, []);

  const login = (credentialResponse) => {
    try {
      // Decode JWT token from Google Identity Services
      const payload = JSON.parse(atob(credentialResponse.credential.split('.')[1]));
      const email = payload.email;
      
      if (email === ALLOWED_EMAIL) {
        const userData = {
          email: payload.email,
          name: payload.name,
          picture: payload.picture,
          sub: payload.sub, // Google's unique user ID
        };
        setUser(userData);
        localStorage.setItem(STORAGE_KEY, JSON.stringify(userData));
        return { success: true };
      } else {
        console.warn('Unauthorized email attempted login:', email);
        return { 
          success: false, 
          error: 'Access denied. This account is not authorized.' 
        };
      }
    } catch (error) {
      console.error('Error processing login:', error);
      return { 
        success: false, 
        error: 'Login failed. Please try again.' 
      };
    }
  };

  const logout = () => {
    setUser(null);
    localStorage.removeItem(STORAGE_KEY);
    
    // Sign out from Google as well
    if (typeof window !== 'undefined' && window.google?.accounts) {
      window.google.accounts.id.disableAutoSelect();
    }
  };

  const value = {
    user,
    loading,
    login,
    logout,
    isAuthenticated: !!user,
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
}
