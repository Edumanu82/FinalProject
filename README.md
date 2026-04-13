# 🌌 Astronomy App

## Table of Contents
1. Overview
2. Product Spec
3. Wireframes
4. Schema

---

## Overview

### Description
The Astronomy App is a mobile application that allows users to explore and understand the night sky in real time. By using location data and device sensors, the app identifies stars, planets, and constellations visible from the user’s location.

Users can also capture and share photos, browse NASA-powered content, and interact with a community of astronomy enthusiasts. The app combines education, exploration, and social interaction to make space engaging and accessible.

---

### App Evaluation

- **Category:** Education / Social / Lifestyle  
- **Mobile:** Yes — designed primarily for mobile (iOS/Android)  
- **Story:** Helps users discover and understand space while sharing experiences with others  
- **Market:** Students, hobbyists, and space enthusiasts worldwide  
- **Habit:** Occasional to moderate use (especially during stargazing or celestial events)  
- **Scope:** Medium to broad (real-time sky tracking + social features + API integration)  

---

## Product Spec

### 1. User Stories

#### Required Must-have Stories
- User can register and log into an account  
- User can view a real-time sky map based on location  
- User can identify stars, planets, and constellations  
- User can create a post (photo + caption)  
- User can view a feed of posts  
- User can like and comment on posts  
- User can view NASA astronomy content  
- User can view upcoming celestial events  

#### Optional Nice-to-have Stories
- User can follow other users  
- User can receive notifications for events  
- User can save favorite constellations  
- User can enable AR sky mode  
- User can message other users  

---

### 2. Screen Archetypes

- **Login Screen**  
  - User can log in or sign up  

- **Home Feed**  
  - User can view posts  
  - User can like/comment on posts  

- **Sky View Screen**  
  - User can view real-time sky map  
  - User can identify celestial objects  

- **Post Creation Screen**  
  - User can take or upload a photo  
  - User can add caption and post  

- **Profile Screen**  
  - User can view their posts and profile  

- **Discover Screen (NASA)**  
  - User can view NASA API content  

- **Events Screen**  
  - User can view upcoming celestial events  

---

### 3. Navigation

#### Tab Navigation (Tab to Screen)
- Home → Home Feed  
- Sky View → Sky Map  
- Post (+) → Post Creation  
- Discover → NASA Content  
- Profile → User Profile  

---

#### Flow Navigation (Screen to Screen)

- **Login Screen**  
  → Leads to Home Feed  

- **Home Feed**  
  → Leads to Post Detail  
  → Leads to Comments  
  → Leads to Profile  

- **Sky View Screen**  
  → Displays celestial objects (no major navigation)  

- **Post Creation Screen**  
  → Leads back to Home Feed after posting  

- **Profile Screen**  
  → Leads to Post Detail  

- **Events Screen**  
  → Displays event details  

---

## Wireframes

![Wireframe](./Markup.pdf)

---

## [BONUS] Digital Wireframes & Mockups

![UI Mockup](./astronomy-ui-mockup.png)

---

## Schema

### Models

#### User
| Property | Type | Description |
|----------|------|------------|
| id | String | unique user id |
| username | String | user's display name |
| email | String | user email |
| password | String | user password |
| profileImage | String | profile image URL |

---

#### Post
| Property | Type | Description |
|----------|------|------------|
| id | String | unique post id |
| userId | String | creator of post |
| image | String | image URL |
| caption | String | post caption |
| createdAt | Date | timestamp |

---

#### Comment
| Property | Type | Description |
|----------|------|------------|
| id | String | unique comment id |
| postId | String | associated post |
| userId | String | comment author |
| text | String | comment content |
| createdAt | Date | timestamp |

---

#### Event
| Property | Type | Description |
|----------|------|------------|
| id | String | event id |
| title | String | event name |
| date | Date | event date |
| description | String | event details |

---

### Networking

#### Home Feed
- `[GET] /posts` → retrieve all posts  
- `[POST] /posts` → create a new post  

#### Comments
- `[GET] /posts/:id/comments` → get comments  
- `[POST] /comments` → add comment  

#### User
- `[POST] /register` → create account  
- `[POST] /login` → login user  
- `[GET] /users/:id` → get user profile  

#### Events
- `[GET] /events` → retrieve upcoming celestial events  

#### NASA API
- `[GET] https://api.nasa.gov/planetary/apod` → Astronomy Picture of the Day  

---
