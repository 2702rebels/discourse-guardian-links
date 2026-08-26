# Discourse Guardian Links (`discourse-guardian-links`)

[![Discourse Plugin Tests](https://github.com/2702rebels/discourse-guardian-links/actions/workflows/test.yml/badge.svg)](https://github.com/2702rebels/discourse-guardian-links/actions/workflows/test.yml)

A lightweight Discourse plugin designed for youth robotics teams (FRC 2702 Rebels) and organizations to track relational **Parent/Guardian <-> Student** links. 

It keeps Discourse as the authoritative system of record with PostgreSQL foreign key integrity while keeping relationship metadata **strictly backend/admin-only (100% invisible on public user profiles)**.

---

## Table of Contents

1. [Features](#features)
2. [Database Architecture](#database-architecture)
3. [REST API Documentation](#rest-api-documentation)
4. [External Integration (Team Hub / Node.js)](#external-integration-team-hub--nodejs)
5. [Discourse Native Admin UI](#discourse-native-admin-ui)
6. [Local Development & Testing](#local-development--testing)
7. [Production Deployment (`ls1`)](#production-deployment-ls1)
8. [Rollback & Safety](#rollback--safety)

---

## Features

- **Relational Integrity**: Backed by a dedicated PostgreSQL `guardian_links` table with foreign keys referencing `users(id)` and `ON DELETE CASCADE`. If a user is renamed, their relationships remain valid. If a user is deleted, relationships clean up automatically.
- **Zero Profile Exposure**: Does not register or serialize custom user fields onto public profile cards or serializer pipelines. Only accessible to Discourse staff/admins.
- **Bi-Directional Querying**: Query all students for a parent, all parents for a student, or search across both by username or display name.
- **Native Admin Interface**: Built-in Ember.js admin view at `/admin/plugins/guardian-links`.
- **Admin REST API**: Exposes JSON endpoints protected by Discourse API keys for external dashboards (like Team Hub).

---

## Database Architecture

The plugin runs an ActiveRecord migration that creates the `guardian_links` table in Discourse's PostgreSQL database:

```sql
CREATE TABLE guardian_links (
    id SERIAL PRIMARY KEY,
    parent_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    student_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    relationship_type VARCHAR(255) DEFAULT 'parent' NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL
);

CREATE UNIQUE INDEX index_guardian_links_on_parent_id_and_student_id 
    ON guardian_links (parent_id, student_id);

CREATE INDEX index_guardian_links_on_student_id 
    ON guardian_links (student_id);
```

---

## REST API Documentation

All endpoints require Discourse Staff authentication (session cookie) or an Admin API Key (`Api-Key` and `Api-Username` HTTP headers).

### 1. List / Search Links
```http
GET /admin/plugins/guardian-links.json
```

**Query Parameters:**
| Parameter | Type | Description |
| :--- | :--- | :--- |
| `parent_id` | `integer` (optional) | Filter links for a specific parent user ID |
| `student_id` | `integer` (optional) | Filter links for a specific student user ID |
| `search` | `string` (optional) | Substring search across usernames and display names |

**Sample Response (`200 OK`):**
```json
{
  "guardian_links": [
    {
      "id": 12,
      "parent_id": 45,
      "student_id": 102,
      "relationship_type": "mother",
      "created_at": "2026-08-26T18:00:00.000Z",
      "parent": {
        "id": 45,
        "username": "jane_doe",
        "name": "Jane Doe",
        "avatar_template": "/user_avatar/discourse.2702rebels.com/jane_doe/{size}/12_2.png"
      },
      "student": {
        "id": 102,
        "username": "alex_doe",
        "name": "Alex Doe",
        "avatar_template": "/user_avatar/discourse.2702rebels.com/alex_doe/{size}/45_2.png"
      }
    }
  ]
}
```

---

### 2. Create Guardian Link
```http
POST /admin/plugins/guardian-links.json
Content-Type: application/json
```

**Request Body (Accepts either numeric IDs or usernames):**
```json
{
  "parent_username": "jane_doe",
  "student_username": "alex_doe",
  "relationship_type": "parent"
}
```
*Alternatively:*
```json
{
  "parent_id": 45,
  "student_id": 102,
  "relationship_type": "guardian"
}
```

**Sample Response (`200 OK`):**
```json
{
  "guardian_link": {
    "id": 12,
    "parent_id": 45,
    "student_id": 102,
    "relationship_type": "parent",
    "parent": { "id": 45, "username": "jane_doe", "name": "Jane Doe" },
    "student": { "id": 102, "username": "alex_doe", "name": "Alex Doe" }
  }
}
```

**Error Responses:**
- `404 Not Found`: If parent or student user does not exist.
- `422 Unprocessable Entity`: If users are already linked or self-linking is attempted.

---

### 3. Remove / Unlink
```http
DELETE /admin/plugins/guardian-links/:id.json
```

**Sample Response (`200 OK`):**
```json
{
  "success": "OK"
}
```

---

## External Integration (Team Hub / Node.js)

To query or mutate relationships from an external Node.js service (e.g. `team-hub` tRPC router):

```typescript
import { fetchWithRateLimit } from './services/http/fetchWithRateLimit';

const DISCOURSE_URL = process.env.DISCOURSE_URL || 'https://discourse.2702rebels.com';
const DISCOURSE_API_KEY = process.env.DISCOURSE_API_KEY!;
const DISCOURSE_API_USERNAME = process.env.DISCOURSE_API_USERNAME || 'system';

export async function fetchStudentGuardians(studentId: number) {
  const response = await fetchWithRateLimit(
    `${DISCOURSE_URL}/admin/plugins/guardian-links.json?student_id=${studentId}`,
    {
      headers: {
        'Api-Key': DISCOURSE_API_KEY,
        'Api-Username': DISCOURSE_API_USERNAME,
        Accept: 'application/json',
      },
    }
  );

  if (!response.ok) {
    throw new Error(`Failed to fetch guardians: ${response.statusText}`);
  }

  const data = await response.json();
  return data.guardian_links;
}
```

---

## Discourse Native Admin UI

Discourse administrators and staff can manage links directly inside Discourse:

1. Log in to Discourse with a staff/admin account.
2. Navigate to **Admin → Plugins → Guardian Links** (or URL `/admin/plugins/guardian-links`).
3. Enter parent and student usernames and click **Link Guardian & Student**.
4. Use the table to search, inspect profiles, or unlink accounts.

---

## Local Development & Testing

### Using VS Code Dev Containers (Recommended)

1. Open this repository folder in VS Code.
2. When prompted, click **"Reopen in Container"** (or use command palette: `Dev Containers: Reopen in Container`).
3. Inside the container, start the Rails server and Ember CLI:
   ```bash
   bundle exec rails server
   ```

### Running Automated Tests (RSpec)

Run the plugin test suite locally:
```bash
bundle exec rake plugin:spec["discourse-guardian-links"]
```

The test suite covers:
- `spec/models/guardian_link_spec.rb`: Foreign key cascading, self-link prevention, uniqueness checks.
- `spec/requests/guardian_links_controller_spec.rb`: Admin authorization gates, search filters, serialization.

---

## Production Deployment (`ls1`)

To deploy this plugin to your self-hosted Discourse instance on `ls1`:

1. SSH into the server:
   ```bash
   ssh ls1
   ```
2. Edit `/var/discourse/containers/app.yml`:
   ```bash
   sudo nano /var/discourse/containers/app.yml
   ```
3. Add the repository under `hooks.after_code`:
   ```yaml
   hooks:
     after_code:
       - exec:
           cd: "$home/plugins"
           cmd:
             - git clone https://github.com/discourse/docker_manager.git
             - git clone https://github.com/paviliondev/discourse-events.git
             - git clone https://github.com/2702rebels/discourse-guardian-links.git
   ```
4. Rebuild the Discourse container:
   ```bash
   cd /var/discourse
   sudo ./launcher rebuild app
   ```
   *Note: Rebuild takes ~5–8 minutes. Database migrations execute automatically during startup.*

---

## Rollback & Safety

1. **Rebuild Failure Protection**: Discourse builds a secondary container image before swapping. If the plugin fails to build, `./launcher rebuild app` halts and leaves your existing production container untouched.
2. **Uninstalling**:
   - Remove `- git clone https://github.com/2702rebels/discourse-guardian-links.git` from `/var/discourse/containers/app.yml`.
   - Run `sudo ./launcher rebuild app`.
