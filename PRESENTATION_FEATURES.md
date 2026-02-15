# AI Ready App - Presentation Feature List

This document lists the features currently implemented in the project.

## 1) Core AI Chat Experience
- Real-time AI chat with streaming responses (typewriter-style output).
- Multiple model choices directly in chat (model dropdown).
- Markdown message rendering with code highlighting.
- Suggested-reply chips for faster follow-up prompts.
- Regenerate assistant response for the latest reply.
- Edit your sent messages after posting.
- Copy any message content with one tap.
- Text-to-speech playback for assistant replies.
- Voice-to-text input using microphone speech recognition.

## 2) Conversation Management
- Create new conversations quickly from drawer or header actions.
- Conversation list with pagination/loading more.
- Conversation search/filter by keyword.
- Rename and delete conversations.
- Auto-title support from backend responses.
- Folder-based organization for conversations.
- Create, rename, and delete folders.
- Move conversations between folders.

## 3) Multimodal and Image Features
- Attach images from recent photos or full photo library picker.
- Image analysis (vision chat) by sending image + prompt.
- Dedicated image generation mode.
- Image editing mode available from chat modes.
- Save generated images to device gallery.
- Paste image from clipboard directly into chat.

## 4) Bookmarks and Saved Content
- Bookmark important messages directly in chat.
- Local bookmark storage for offline persistence.
- Bookmark page with search and role filters (AI vs You).
- Bookmarks grouped by time (Today, This Week, This Month, Earlier).
- Swipe to remove bookmark with Undo action.
- Jump from bookmark back to exact message context in chat.

## 5) Prompt and Discovery Features
- Prompt Library page for reusable prompts.
- Create custom prompts.
- AI-powered "Enhance Prompt" feature while creating prompts.
- Discover page with AI tips and capability cards.
- Prompt idea chips on Discover to quickly copy and use.

## 6) Profile, Personalization, and Appearance
- Profile page with avatar upload/change.
- Edit first and last name.
- Personal stats cards (conversations, messages, badges).
- Personalization fields: preferred name, preferred tone, preferred language, and custom system instructions.
- Personalization controls: stream responses, haptic feedback, theme mode, and default model preference.
- Appearance settings: font size scaling and font family selection.
- Quick theme toggle from chat app bar.
- iOS alternate app icon picker.

## 7) Authentication and Session Security
- Email/password registration and login.
- Google Sign-In flow.
- Persistent auth with secure token storage.
- Auto token refresh handling in network layer.
- Device-aware login/session metadata.
- Active Sessions page with device/IP/last active display.
- Terminate individual sessions.
- Terminate all other sessions.
- Logout current device.
- Logout all devices.

## 8) Gamification and Engagement
- Achievements/badges integration from backend status.
- Achievement card in profile.
- New achievement snackbar notifications.
- Local cache of unlocked achievement IDs.

## 9) Platform and Architecture Strengths
- Cross-platform Flutter architecture (mobile + desktop + web targets in project).
- Adaptive/responsive layout behavior via `flutter_adaptive_kit`.
- BLoC/Cubit state management across features.
- Modular feature-based project structure.
- Environment-based config (`dev` and `production` env files).
- Dependency injection with `get_it`.
- Structured API layer with repositories and typed models.

## 10) Advanced/Code-Ready Capabilities (Present in code, not primary UI flow)
- Conversation export service (share as markdown/text).
- Conversation share/unshare API support.
- Message feedback API support.
- Conversation summary API support.
- Web search API support.
- Usage statistics page route (`/usage`).
- Analytics repository support.
- Health-check repository support.
- Local pinned-conversation storage utilities.

## Optional 3-Minute Demo Flow
- Login with email or Google.
- Start a new chat, send a prompt, show streaming response.
- Switch mode to Image Generation and generate an image.
- Save image to gallery.
- Bookmark a message and open Bookmarks page.
- Create a folder and move a conversation into it.
- Open Prompt Library and create/enhance a prompt.
- Open Profile to show stats, achievements, personalization, and active sessions.
