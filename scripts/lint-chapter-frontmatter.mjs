#!/usr/bin/env node

/**
 * Validates frontmatter in every .mdx file under docs/devops/postgres-ha-patroni-book/
 * against the chapter-frontmatter JSON Schema.
 *
 * Usage: node scripts/lint-chapter-frontmatter.mjs
 * Exit code: 0 = all valid, 1 = validation errors found
 */

import { readFileSync, readdirSync } from 'fs';
import { join, resolve } from 'path';

const BOOK_DIR = resolve('docs/devops/postgres-ha-patroni-book');
const SCHEMA_PATH = resolve('specs/001-postgres-ha-patroni-book/contracts/chapter-frontmatter.schema.json');

// Simple YAML frontmatter parser (extracts key: value pairs from --- blocks)
function parseFrontmatter(content) {
  const match = content.match(/^---\n([\s\S]*?)\n---/);
  if (!match) return null;

  // We only need to validate required top-level keys exist and have correct types.
  // For a lightweight linter without external deps, we parse YAML manually for the
  // fields we care about.
  const yaml = match[1];
  const fm = {};

  for (const line of yaml.split('\n')) {
    const kv = line.match(/^(\w[\w_]*)\s*:\s*(.+)$/);
    if (kv) {
      const [, key, rawVal] = kv;
      const val = rawVal.trim();
      // Detect arrays
      if (val.startsWith('[')) {
        try { fm[key] = JSON.parse(val.replace(/'/g, '"')); } catch { fm[key] = val; }
      } else if (/^\d+$/.test(val)) {
        fm[key] = parseInt(val, 10);
      } else {
        fm[key] = val.replace(/^["']|["']$/g, '');
      }
    }
  }

  // Parse nested version_support block
  if (yaml.includes('version_support:')) {
    fm.version_support = {};
    const vsBlock = yaml.split('version_support:')[1];
    if (vsBlock) {
      const lines = vsBlock.split('\n');
      for (const l of lines) {
        const nested = l.match(/^\s{2}(\w[\w_]*)\s*:\s*(.+)$/);
        if (nested) {
          const [, k, v] = nested;
          const val = v.trim();
          if (val.startsWith('[')) {
            try { fm.version_support[k] = JSON.parse(val.replace(/'/g, '"')); } catch { fm.version_support[k] = val; }
          } else if (/^\d+$/.test(val)) {
            fm.version_support[k] = parseInt(val, 10);
          } else {
            fm.version_support[k] = val.replace(/^["']|["']$/g, '');
          }
        }
        // Stop at next top-level key
        if (l.match(/^\w/) && !l.startsWith(' ')) break;
      }
    }
  }

  return fm;
}

function validate(fm, filePath) {
  const errors = [];
  const required = ['title', 'sidebar_position', 'description', 'version_support', 'anchors_user_stories', 'frs_covered'];

  for (const field of required) {
    if (fm[field] === undefined || fm[field] === null) {
      errors.push(`Missing required field: ${field}`);
    }
  }

  if (typeof fm.title === 'string' && fm.title.length < 5) {
    errors.push(`title must be at least 5 characters (got ${fm.title.length})`);
  }

  if (typeof fm.sidebar_position === 'number' && (fm.sidebar_position < 0 || fm.sidebar_position > 99)) {
    errors.push(`sidebar_position must be 0..99 (got ${fm.sidebar_position})`);
  }

  if (typeof fm.description === 'string' && fm.description.length < 20) {
    errors.push(`description must be at least 20 characters (got ${fm.description.length})`);
  }

  if (fm.version_support && typeof fm.version_support === 'object') {
    if (!fm.version_support.postgres) errors.push('version_support.postgres is required');
    if (!fm.version_support.patroni) errors.push('version_support.patroni is required');
    if (fm.version_support.window_months === undefined) errors.push('version_support.window_months is required');
  }

  if (fm.anchors_user_stories && Array.isArray(fm.anchors_user_stories)) {
    for (const us of fm.anchors_user_stories) {
      if (!/^US[1-5]$/.test(us)) errors.push(`Invalid user story: ${us} (must match US1..US5)`);
    }
  }

  if (fm.frs_covered && Array.isArray(fm.frs_covered)) {
    for (const fr of fm.frs_covered) {
      if (!/^FR-\d{3}$/.test(fr)) errors.push(`Invalid FR: ${fr} (must match FR-NNN)`);
    }
  }

  return errors;
}

// Main
let hasErrors = false;
const files = readdirSync(BOOK_DIR).filter(f => f.endsWith('.mdx'));

if (files.length === 0) {
  console.log('No .mdx files found in', BOOK_DIR);
  process.exit(0);
}

for (const file of files) {
  const filePath = join(BOOK_DIR, file);
  const content = readFileSync(filePath, 'utf-8');
  const fm = parseFrontmatter(content);

  if (!fm) {
    console.error(`FAIL ${file}: No frontmatter found`);
    hasErrors = true;
    continue;
  }

  const errors = validate(fm, filePath);
  if (errors.length > 0) {
    console.error(`FAIL ${file}:`);
    for (const e of errors) console.error(`  - ${e}`);
    hasErrors = true;
  } else {
    console.log(`PASS ${file}`);
  }
}

process.exit(hasErrors ? 1 : 0);
