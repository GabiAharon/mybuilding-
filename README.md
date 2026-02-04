# MyBuilding - Smart Building Management App

A comprehensive PWA for residential building management with bilingual support (Hebrew/English).

## Features

### For Residents
- **Dashboard** - Payment status, quick actions, recent notices
- **Maintenance Center** - Report issues with photo upload, track status
- **Notice Board** - Building announcements, events with RSVP
- **Community Hub** - Voting, trusted professionals, marketplace

### For Admins
- **Financial Dashboard** - Income/expenses overview with charts
- **Debtors Tracker** - Send payment reminders
- **Expense Manager** - Log expenses with receipt uploads
- **User Management** - Approve/reject new residents

## Tech Stack
- React 18
- Pure CSS (no frameworks)
- PWA-ready with manifest.json
- RTL/LTR support
- Mobile-first responsive design

## Pages

| File | Description |
|------|-------------|
| `index.html` | Resident Dashboard |
| `auth.html` | Login/Registration flow |
| `faults.html` | Maintenance ticket system |
| `notices.html` | Notice board with events |
| `community.html` | Voting, pros, marketplace |
| `profile.html` | User profile & settings |
| `admin.html` | Admin dashboard |

## Design System

### Colors
- Primary: `#D4785C` (Terracotta)
- Secondary: `#2D5A4A` (Forest Green)
- Background: `#FFF9F5` (Cream)

### Typography
- Display: Fraunces
- Body: Rubik (excellent Hebrew support)

## Getting Started

1. Clone the repository
2. Open any `.html` file in a browser
3. Use mobile view (375px) for best experience

## For Lovable

This project is designed to be imported into Lovable. The HTML files are self-contained with embedded React via CDN, making them easy to convert to Lovable's component structure.

## License

MIT
