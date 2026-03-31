import React from 'react';
import { useAuth } from '@site/src/theme/Root';
import styles from './styles.module.css';

export default function LogoutButton() {
  const { user, logout } = useAuth();

  if (!user) {
    return null;
  }

  return (
    <div className={styles.logoutContainer}>
      <div className={styles.userInfo}>
        {user.picture && (
          <img 
            src={user.picture} 
            alt={user.name} 
            className={styles.avatar}
          />
        )}
        <span className={styles.userName}>{user.name}</span>
      </div>
      <button 
        onClick={logout}
        className={styles.logoutButton}
      >
        Sign Out
      </button>
    </div>
  );
}
