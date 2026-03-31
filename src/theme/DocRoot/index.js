import React, { useEffect, useState } from 'react';
import DocRoot from '@theme-original/DocRoot';
import { useAuth } from '@site/src/theme/Root';
import LoginPage from '@site/src/components/LoginPage';

// Simple wrapper to prevent React Strict Mode double rendering
function AuthGuard({ children, fallback }) {
  const [mounted, setMounted] = useState(false);
  
  useEffect(() => {
    setMounted(true);
  }, []);
  
  // Prevent hydration mismatch by not rendering until mounted
  if (!mounted) {
    return (
      <div style={{ 
        display: 'flex', 
        justifyContent: 'center', 
        alignItems: 'center', 
        minHeight: '100vh',
        background: 'var(--ifm-background-color, #1b1b1d)',
        color: 'var(--ifm-font-color-base, #e3e3e3)'
      }}>
        Loading...
      </div>
    );
  }
  
  return children;
}

export default function DocRootWrapper(props) {
  const { user, loading } = useAuth();

  // Show loading state while checking session
  if (loading) {
    return (
      <div style={{ 
        display: 'flex', 
        justifyContent: 'center', 
        alignItems: 'center', 
        minHeight: '100vh',
        background: 'var(--ifm-background-color, #1b1b1d)',
        color: 'var(--ifm-font-color-base, #e3e3e3)'
      }}>
        Loading...
      </div>
    );
  }

  // If not authenticated, show login page
  if (!user) {
    return (
      <AuthGuard>
        <LoginPage />
      </AuthGuard>
    );
  }

  // User is authenticated, show the docs
  return (
    <AuthGuard>
      <DocRoot {...props} />
    </AuthGuard>
  );
}
