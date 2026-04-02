import React, { useState, useRef, useEffect } from 'react';
import { useAuth } from '@site/src/theme/Root';
import styles from './styles.module.css';

const TOOLS = [
  {
    label: 'VS Code',
    href: 'https://code.tail48fe8.ts.net/',
    description: 'Browser IDE',
  },
  {
    label: 'Notes',
    href: 'https://code.tail48fe8.ts.net/?folder=/home/vishal/jot',
    description: 'Notes repo in VS Code',
  },
];

export default function ToolsNavbarItem() {
  const { isAuthenticated } = useAuth();
  const [open, setOpen] = useState(false);
  const ref = useRef(null);

  useEffect(() => {
    function handleClickOutside(e) {
      if (ref.current && !ref.current.contains(e.target)) {
        setOpen(false);
      }
    }
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  if (!isAuthenticated) return null;

  return (
    <div ref={ref} className={styles.wrapper}>
      <button
        className={styles.trigger}
        onClick={() => setOpen((o) => !o)}
        aria-expanded={open}
        aria-haspopup="true"
      >
        Tools <span className={styles.caret}>▾</span>
      </button>
      {open && (
        <div className={styles.dropdown}>
          {TOOLS.map((tool) => (
            <a
              key={tool.label}
              href={tool.href}
              target="_blank"
              rel="noopener noreferrer"
              className={styles.item}
              onClick={() => setOpen(false)}
            >
              <span className={styles.itemLabel}>{tool.label}</span>
              <span className={styles.itemDesc}>{tool.description}</span>
            </a>
          ))}
        </div>
      )}
    </div>
  );
}
