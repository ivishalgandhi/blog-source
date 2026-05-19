import React from 'react';
import companionLinks from '@site/docs/devops/postgres-ha-patroni-book/_companion-links.json';

/**
 * Resolves a companion-repo artifact ID (e.g. LAB-03-A) to a clickable link.
 * Throws at build time when the ID is missing — this is the FR-010 drift signal.
 */
export default function ArtifactRef({ id }) {
  const entry = companionLinks[id];
  if (!entry) {
    throw new Error(
      `ArtifactRef: unknown artifact ID "${id}". ` +
      `Add it to docs/devops/postgres-ha-patroni-book/_companion-links.json`
    );
  }
  return (
    <a href={entry.url} title={entry.description || id}>
      <code>{id}</code>
    </a>
  );
}
