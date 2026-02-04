// This script generates public/config.js from environment variables
// Run before build: node scripts/generate-config.js

const fs = require('fs');
const path = require('path');

const config = {
  ADMIN_EMAIL: process.env.VITE_ADMIN_EMAIL || '',
  ADMIN_EMAILS: process.env.VITE_ADMIN_EMAILS ? process.env.VITE_ADMIN_EMAILS.split(',') : [],
  BUILDING_NAME: process.env.VITE_BUILDING_NAME || 'MyBuilding',
  BUILDING_NAME_EN: process.env.VITE_BUILDING_NAME_EN || 'MyBuilding',
  BUILDING_ADDRESS: process.env.VITE_BUILDING_ADDRESS || '',
  BUILDING_ADDRESS_EN: process.env.VITE_BUILDING_ADDRESS_EN || '',
  INVITATION_SECRET: process.env.VITE_INVITATION_SECRET || 'default-secret-change-me',
  SUPABASE_URL: process.env.VITE_SUPABASE_URL || '',
  SUPABASE_ANON_KEY: process.env.VITE_SUPABASE_ANON_KEY || ''
};

const configContent = `// Auto-generated config - DO NOT EDIT
// Generated at build time from environment variables
window.APP_CONFIG = ${JSON.stringify(config, null, 2)};
`;

const publicDir = path.join(__dirname, '..', 'public');
const configPath = path.join(publicDir, 'config.js');

// Ensure public directory exists
if (!fs.existsSync(publicDir)) {
  fs.mkdirSync(publicDir, { recursive: true });
}

fs.writeFileSync(configPath, configContent);
console.log('Generated public/config.js from environment variables');
