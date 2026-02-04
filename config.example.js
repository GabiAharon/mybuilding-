// EXAMPLE CONFIGURATION - Copy this file to config.js and fill in your values
// config.js should NOT be committed to git (it's in .gitignore)
window.APP_CONFIG = {
  // Main admin email (has full access to everything)
  ADMIN_EMAIL: "your-email@example.com",

  // List of additional admin emails
  ADMIN_EMAILS: [],

  // Building configuration
  BUILDING_NAME: "שם הבניין",
  BUILDING_NAME_EN: "Building Name",
  BUILDING_ADDRESS: "כתובת הבניין",
  BUILDING_ADDRESS_EN: "Building Address",

  // Invitation secret (used to generate secure invitation links)
  // Generate a random string for security
  INVITATION_SECRET: "change-this-to-random-string",

  // Supabase Configuration
  // Get these from your Supabase project: Settings > API
  SUPABASE_URL: "https://your-project.supabase.co",
  SUPABASE_ANON_KEY: "your-anon-key-here"
};
