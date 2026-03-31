import React, { useEffect, useState } from 'react';
import { useAuth } from '@site/src/theme/Root';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import styles from './styles.module.css';

export default function LoginPage() {
  const { login } = useAuth();
  const { siteConfig } = useDocusaurusContext();
  const [error, setError] = useState(null);
  const [scriptLoaded, setScriptLoaded] = useState(false);

  const googleClientId = siteConfig.customFields?.googleClientId;

  useEffect(() => {
    // Load Google Identity Services script
    if (typeof window === 'undefined') return;

    // Check if script already exists
    if (document.getElementById('google-gsi-script')) {
      setScriptLoaded(true);
      return;
    }

    const script = document.createElement('script');
    script.id = 'google-gsi-script';
    script.src = 'https://accounts.google.com/gsi/client';
    script.async = true;
    script.defer = true;
    script.onload = () => setScriptLoaded(true);
    script.onerror = () => setError('Failed to load Google Sign-In');
    
    document.body.appendChild(script);

    return () => {
      // Cleanup script on unmount
      const existingScript = document.getElementById('google-gsi-script');
      if (existingScript) {
        document.body.removeChild(existingScript);
      }
    };
  }, []);

  useEffect(() => {
    // Initialize Google Sign-In button once script is loaded
    if (!scriptLoaded || !googleClientId || typeof window === 'undefined') return;

    try {
      window.google.accounts.id.initialize({
        client_id: googleClientId,
        callback: handleCredentialResponse,
        auto_select: false,
        cancel_on_tap_outside: false,
      });

      // Render the sign-in button
      window.google.accounts.id.renderButton(
        document.getElementById('google-signin-button'),
        {
          theme: 'filled_black',
          size: 'large',
          width: '100%',
          text: 'signin_with',
          shape: 'rectangular',
        }
      );
    } catch (err) {
      console.error('Error initializing Google Sign-In:', err);
      setError('Failed to initialize sign-in. Please refresh the page.');
    }
  }, [scriptLoaded, googleClientId]);

  const handleCredentialResponse = (response) => {
    setError(null);
    const result = login(response);
    
    if (!result.success) {
      setError(result.error);
    }
  };

  return (
    <div className={styles.loginContainer}>
      <div className={styles.loginCard}>
        <h1 className={styles.title}>Authentication Required</h1>
        <p className={styles.description}>
          This documentation is private. Please sign in with Google to continue.
        </p>

        {!googleClientId && (
          <div className={styles.error}>
            <strong>Configuration Error:</strong> Google Client ID not configured.
          </div>
        )}

        {error && (
          <div className={styles.error}>
            {error}
          </div>
        )}

        <div id="google-signin-button" className={styles.buttonContainer}>
          {!scriptLoaded && (
            <div className={styles.loading}>Loading sign-in...</div>
          )}
        </div>

        <p className={styles.note}>
          Only authorized accounts can access this documentation.
        </p>
      </div>
    </div>
  );
}
