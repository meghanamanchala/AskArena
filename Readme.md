# AskArena – Real-Time Event Q&A Platform

AskArena is a real-time audience engagement platform built using SvelteKit and Supabase. It enables attendees to submit and upvote questions during live events, with instant ranking updates and secure role-based access control.

---

## Features

### Attendee

* Join an event using a unique event code
* Submit questions in real time
* Upvote questions (one vote per question)
* View dynamically ranked questions
* See answered questions

### Host

* Create and manage live events
* Moderate questions (delete or mark as answered)
* Lock events to stop new votes
* Monitor engagement in real time

---

## Tech Stack

Frontend:

* SvelteKit
* TypeScript (optional)
* Tailwind CSS (optional)

Backend:

* Supabase

  * PostgreSQL
  * Row Level Security (RLS)
  * Realtime subscriptions
  * Edge Functions (optional for moderation and rate limiting)

---

## System Architecture

User Action → SvelteKit Client → Supabase Database → Realtime Broadcast → All Clients Update

* Questions and votes are stored in PostgreSQL.
* Supabase Realtime broadcasts INSERT and UPDATE events.
* The UI updates automatically without polling.
* Row Level Security ensures proper access control.

---

## Database Schema

### events

| Column     | Type      | Description       |
| ---------- | --------- | ----------------- |
| id         | UUID      | Primary Key       |
| title      | Text      | Event name        |
| code       | Text      | Unique join code  |
| created_by | UUID      | Host ID           |
| is_live    | Boolean   | Event status      |
| is_locked  | Boolean   | Prevent new votes |
| created_at | Timestamp | Creation time     |

---

### questions

| Column      | Type      | Description              |
| ----------- | --------- | ------------------------ |
| id          | UUID      | Primary Key              |
| event_id    | UUID      | Foreign Key → events     |
| content     | Text      | Question text            |
| created_by  | UUID      | Creator ID or session ID |
| votes_count | Integer   | Cached vote count        |
| is_answered | Boolean   | Answer status            |
| is_deleted  | Boolean   | Soft delete flag         |
| created_at  | Timestamp | Creation time            |

---

### votes

| Column      | Type      | Description                     |
| ----------- | --------- | ------------------------------- |
| id          | UUID      | Primary Key                     |
| question_id | UUID      | Foreign Key → questions         |
| user_id     | UUID      | Used to prevent duplicate votes |
| created_at  | Timestamp | Creation time                   |

A unique constraint on (question_id, user_id) prevents duplicate voting.

---

## Security Model (Row Level Security)

Attendees can:

* Insert questions only into active events
* Vote once per question
* View questions within joined events

Hosts can:

* Delete or update questions in their own events
* Lock events to prevent new votes
* Mark questions as answered

Users cannot:

* Modify vote counts directly
* Access other events’ data
* Vote multiple times on the same question

---

## Real-Time Updates

Supabase Realtime is used to:

* Broadcast new questions instantly
* Update vote counts across connected clients
* Reflect moderation changes immediately

All updates occur without page refresh.

---

## Core Logic Highlights

* Vote deduplication enforced at the database level
* Cached vote counts enable efficient sorting
* Optimistic UI updates improve responsiveness
* Event lifecycle states: Created → Live → Locked → Closed

---

## Scalability Considerations

* Indexed foreign keys for faster queries
* Cached vote counts instead of runtime aggregation
* Pagination for large events
* Optional rate limiting via Edge Functions

---

## Future Enhancements

* AI-based content moderation
* Public presentation mode for large screens
* Polls and quizzes integration
* Engagement analytics dashboard
* Multi-tenant organization support

