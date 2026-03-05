# Microsoft Graph v1.0 API — Full Endpoint Coverage

> Coverage map of the entire Microsoft Graph v1.0 REST API against our Elixir library.
> Module = our resource module that implements the endpoint(s).

---

## Users

Manage Azure AD user accounts — create, update, delete, and query user profiles, org hierarchy (manager, direct reports), group/role memberships, licenses, app role assignments, authentication methods, and profile photos.

Module: `MicrosoftGraph.Users`

| Endpoint | Method | Status | Function |
|----------|--------|--------|----------|
| `/users` | GET | ✅ | `list/1` |
| `/users/{id}` | GET | ✅ | `get/2` |
| `/users` | POST | ✅ | `create/2` |
| `/users/{id}` | PATCH | ✅ | `update/3` |
| `/users/{id}` | DELETE | ✅ | `delete/2` |
| `/users/delta` | GET | ✅ | `delta/1` |
| `/users/{id}/changePassword` | POST | ✅ | `change_password/3` |
| `/users/{id}/revokeSignInSessions` | POST | ✅ | `revoke_sign_in_sessions/2` |
| `/users/{id}/exportPersonalData` | POST | ✅ | `export_personal_data/3` |
| `/users/{id}/manager` | GET | ✅ | `get_manager/2` |
| `/users/{id}/manager/$ref` | PUT | ✅ | `assign_manager/3` |
| `/users/{id}/manager/$ref` | DELETE | ✅ | `remove_manager/2` |
| `/users/{id}/directReports` | GET | ✅ | `list_direct_reports/2` |
| `/users/{id}/memberOf` | GET | ✅ | `list_member_of/2` |
| `/users/{id}/transitiveMemberOf` | GET | ✅ | `list_transitive_member_of/2` |
| `/users/{id}/getMemberObjects` | POST | ✅ | `get_member_objects/3` |
| `/users/{id}/getMemberGroups` | POST | ✅ | `get_member_groups/3` |
| `/users/{id}/checkMemberObjects` | POST | ✅ | `check_member_objects/3` |
| `/users/{id}/checkMemberGroups` | POST | ✅ | `check_member_groups/3` |
| `/users/{id}/scopedRoleMemberOf` | GET | ✅ | `list_scoped_role_member_of/2` |
| `/users/{id}/appRoleAssignments` | GET | ✅ | `list_app_role_assignments/2` |
| `/users/{id}/appRoleAssignments` | POST | ✅ | `add_app_role_assignment/3` |
| `/users/{id}/appRoleAssignments/{id}` | DELETE | ✅ | `remove_app_role_assignment/3` |
| `/users/{id}/oauth2PermissionGrants` | GET | ✅ | `list_oauth2_permission_grants/2` |
| `/users/{id}/authentication/methods` | GET | ✅ | `list_authentication_methods/2` |
| `/users/{id}/assignLicense` | POST | ✅ | `assign_license/3` |
| `/users/{id}/licenseDetails` | GET | ✅ | `list_license_details/2` |
| `/users/{id}/photo` | GET | ✅ | `get_photo/2` |
| `/users/{id}/photo/$value` | GET | ✅ | `get_photo_content/2` |
| `/users/{id}/photo/$value` | PUT | ✅ | `update_photo_content/3` |
| `/users/{id}/photo` | DELETE | ❌ | |
| `/users/{id}/createdObjects` | GET | ❌ | |
| `/users/{id}/ownedDevices` | GET | ❌ | |
| `/users/{id}/ownedObjects` | GET | ❌ | |
| `/users/{id}/registeredDevices` | GET | ❌ | |
| `/users/{id}/sponsors` | GET | ❌ | |
| `/users/{id}/sponsors/$ref` | POST | ❌ | |
| `/users/{id}/permissionGrants` | GET | ❌ | |

### Invitations

| Endpoint | Method | Status | Function |
|----------|--------|--------|----------|
| `/invitations` | POST | ❌ | |

---

## Groups

Manage Microsoft 365 and security groups — create, update, delete groups, manage members and owners, check transitive memberships, assign app roles and licenses, and track changes via delta queries.

Module: `MicrosoftGraph.Groups`

| Endpoint | Method | Status | Function |
|----------|--------|--------|----------|
| `/groups` | GET | ✅ | `list/1` |
| `/groups/{id}` | GET | ✅ | `get/2` |
| `/groups` | POST | ✅ | `create/2` |
| `/groups/{id}` | PATCH | ✅ | `update/3` |
| `/groups/{id}` | DELETE | ✅ | `delete/2` |
| `/groups/delta` | GET | ✅ | `delta/1` |
| `/groups/{id}/members` | GET | ✅ | `list_members/2` |
| `/groups/{id}/members/$ref` | POST | ✅ | `add_member/3` |
| `/groups/{id}/members/{id}/$ref` | DELETE | ✅ | `remove_member/3` |
| `/groups/{id}/members/delta` | GET | ✅ | `members_delta/2` |
| `/groups/{id}/owners` | GET | ✅ | `list_owners/2` |
| `/groups/{id}/owners/$ref` | POST | ✅ | `add_owner/3` |
| `/groups/{id}/owners/{id}/$ref` | DELETE | ✅ | `remove_owner/3` |
| `/groups/{id}/transitiveMembers` | GET | ✅ | `list_transitive_members/2` |
| `/groups/{id}/memberOf` | GET | ✅ | `list_member_of/2` |
| `/groups/{id}/assignLicense` | POST | ✅ | `assign_license/3` |
| `/groups/{id}/renew` | POST | ✅ | `renew/2` |
| `/groups/{id}/transitiveMemberOf` | GET | ✅ | `list_transitive_member_of/2` |
| `/groups/{id}/getMemberObjects` | POST | ✅ | `get_member_objects/3` |
| `/groups/{id}/getMemberGroups` | POST | ✅ | `get_member_groups/3` |
| `/groups/{id}/checkMemberObjects` | POST | ✅ | `check_member_objects/3` |
| `/groups/{id}/checkMemberGroups` | POST | ✅ | `check_member_groups/3` |
| `/groups/{id}/appRoleAssignments` | GET | ✅ | `list_app_role_assignments/2` |
| `/groups/{id}/appRoleAssignments` | POST | ✅ | `add_app_role_assignment/3` |
| `/groups/{id}/appRoleAssignments/{id}` | DELETE | ✅ | `remove_app_role_assignment/3` |
| `/groups/{id}/permissionGrants` | GET | ✅ | `list_permission_grants/2` |
| `/groups/{id}/settings` | GET/POST | ❌ | |
| `/groups/{id}/threads` | GET/POST | ❌ | *(legacy — Outlook Groups)* |
| `/groups/{id}/conversations` | GET/POST | ❌ | *(legacy — Outlook Groups)* |
| `/groups/{id}/events` | GET/POST | ❌ | |
| `/groups/{id}/calendar` | GET | ❌ | |
| `/groups/{id}/drive` | GET | ❌ | |
| `/groups/{id}/sites` | GET | ❌ | |
| `/groups/{id}/photo` | GET/PUT | ❌ | |

---

## Applications

Register and manage Azure AD app registrations and service principals — credentials, owners, app role assignments, and OAuth2 permission grants.

No module implemented.

| Endpoint | Method | Status |
|----------|--------|--------|
| `/applications` | GET/POST | ❌ |
| `/applications/{id}` | GET/PATCH/DELETE | ❌ |
| `/applications/{id}/owners` | GET/POST | ❌ |
| `/applications/{id}/addPassword` | POST | ❌ |
| `/applications/{id}/removePassword` | POST | ❌ |
| `/servicePrincipals` | GET/POST | ❌ |
| `/servicePrincipals/{id}` | GET/PATCH/DELETE | ❌ |
| `/servicePrincipals/{id}/appRoleAssignments` | GET/POST | ❌ |
| `/servicePrincipals/{id}/appRoleAssignedTo` | GET/POST | ❌ |
| `/servicePrincipals/{id}/oauth2PermissionGrants` | GET | ❌ |

---

## Calendars

Access and manage Outlook calendar events — CRUD operations on events, query calendar views by date range, list a user's calendars, and track event changes via delta queries.

Module: `MicrosoftGraph.Calendar`

| Endpoint | Method | Status | Function |
|----------|--------|--------|----------|
| `/users/{id}/events` | GET | ✅ | `list_events/2` |
| `/users/{id}/events/{id}` | GET | ✅ | `get_event/3` |
| `/users/{id}/events` | POST | ✅ | `create_event/3` |
| `/users/{id}/events/{id}` | PATCH | ✅ | `update_event/4` |
| `/users/{id}/events/{id}` | DELETE | ✅ | `delete_event/3` |
| `/users/{id}/calendarView` | GET | ✅ | `calendar_view/2` |
| `/users/{id}/calendars` | GET | ✅ | `list_calendars/2` |
| `/users/{id}/events/delta` | GET | ✅ | `events_delta/2` |
| `/users/{id}/calendars` | POST (Create) | ❌ | |
| `/users/{id}/calendarGroups` | GET/POST | ❌ | |
| `/users/{id}/calendar/getSchedule` | POST | ❌ | |
| `/users/{id}/events/{id}/accept` | POST | ❌ | |
| `/users/{id}/events/{id}/decline` | POST | ❌ | |
| `/users/{id}/events/{id}/tentativelyAccept` | POST | ❌ | |
| `/users/{id}/events/{id}/cancel` | POST | ❌ | |
| `/users/{id}/events/{id}/forward` | POST | ❌ | |
| `/users/{id}/events/{id}/instances` | GET | ❌ | |
| `/users/{id}/events/{id}/attachments` | GET/POST | ❌ | |

---

## Mail

Send and manage Outlook email — list, read, and delete messages, create drafts, send mail, browse mail folders, and track message changes via delta queries.

Module: `MicrosoftGraph.Mail`

| Endpoint | Method | Status | Function |
|----------|--------|--------|----------|
| `/users/{id}/messages` | GET | ✅ | `list_messages/2` |
| `/users/{id}/messages/{id}` | GET | ✅ | `get_message/3` |
| `/users/{id}/sendMail` | POST | ✅ | `send_mail/3` |
| `/users/{id}/messages` | POST (Draft) | ✅ | `create_draft/3` |
| `/users/{id}/messages/{id}` | DELETE | ✅ | `delete_message/3` |
| `/users/{id}/mailFolders` | GET | ✅ | `list_mail_folders/2` |
| `/users/{id}/mailFolders/{id}/messages` | GET | ✅ | `list_folder_messages/3` |
| `/users/{id}/messages/delta` | GET | ✅ | `messages_delta/2` |
| `/users/{id}/mailFolders/{id}/messages/delta` | GET | ✅ | `folder_messages_delta/3` |
| `/users/{id}/messages/{id}` | PATCH (Update) | ❌ | |
| `/users/{id}/messages/{id}/send` | POST | ❌ | |
| `/users/{id}/messages/{id}/reply` | POST | ❌ | |
| `/users/{id}/messages/{id}/replyAll` | POST | ❌ | |
| `/users/{id}/messages/{id}/forward` | POST | ❌ | |
| `/users/{id}/messages/{id}/move` | POST | ❌ | |
| `/users/{id}/messages/{id}/copy` | POST | ❌ | |
| `/users/{id}/messages/{id}/attachments` | GET/POST | ❌ | |
| `/users/{id}/mailFolders` | POST (Create) | ❌ | |
| `/users/{id}/mailFolders/{id}` | GET/PATCH/DELETE | ❌ | |
| `/users/{id}/mailFolders/{id}/move` | POST | ❌ | |
| `/users/{id}/mailFolders/{id}/copy` | POST | ❌ | |
| `/users/{id}/mailFolders/{id}/messageRules` | GET/POST | ❌ | |
| `/users/{id}/getMailTips` | POST | ❌ | |
| `/users/{id}/mailboxSettings` | GET/PATCH | ❌ | |
| `/users/{id}/inferenceClassification/overrides` | GET/POST | ❌ | |

---

## Files (OneDrive)

Work with OneDrive and SharePoint document libraries — browse drives and folders, upload/download files, manage item metadata, copy items, control sharing permissions, and access file versions and thumbnails.

Module: `MicrosoftGraph.Files`

| Endpoint | Method | Status | Function |
|----------|--------|--------|----------|
| `/users/{id}/drive` | GET | ✅ | `get_drive/2` |
| `/users/{id}/drives` | GET | ✅ | `list_drives/2` |
| `/drives/{id}/root/children` | GET | ✅ | `list_root_children/2` |
| `/drives/{id}/items/{id}/children` | GET | ✅ | `list_children/3` |
| `/drives/{id}/items/{id}` | GET | ✅ | `get_item/3` |
| `/drives/{id}/root:/{path}:` | GET | ✅ | `get_item_by_path/3` |
| `/drives/{id}/special/{name}` | GET | ✅ | `get_special_folder/3` |
| `/drives/{id}/root/search(q='...')` | GET | ✅ | `search/3` |
| `/drives/{id}/items/{id}/content` | GET | ✅ | `download_content/3` |
| `/drives/{id}/root:/{path}:/content` | PUT | ✅ | `upload_small/4` |
| `/drives/{id}/root:/{path}:/createUploadSession` | POST | ✅ | `create_upload_session/4` |
| `/drives/{id}/root/delta` | GET | ✅ | `drive_delta/2` |
| `/drives/{id}/items/{parent}/children` | POST | ✅ | `create_folder/4` |
| `/drives/{id}/items/{id}` | PATCH | ✅ | `update_item/4` |
| `/drives/{id}/items/{id}` | DELETE | ✅ | `delete_item/3` |
| `/drives/{id}/items/{id}/copy` | POST | ✅ | `copy_item/4` |
| `/drives/{id}/items/{id}/permissions` | GET | ✅ | `list_permissions/3` |
| `/drives/{id}/items/{id}/createLink` | POST | ✅ | `create_sharing_link/4` |
| `/drives/{id}/items/{id}/invite` | POST | ✅ | `add_permission/4` |
| `/drives/{id}/items/{id}/permissions/{id}` | DELETE | ✅ | `delete_permission/4` |
| `/drives/{id}/items/{id}/versions` | GET | ✅ | `list_versions/3` |
| `/drives/{id}/items/{id}/thumbnails` | GET | ✅ | `list_thumbnails/3` |
| `/shares/{shareId}/driveItem` | GET | ✅ | `get_shared_item/2` |
| `/drives/{id}/items/{id}/move` | PATCH | ❌ | (use `update_item` with `parentReference`) |

---

## Subscriptions (Change Notifications)

Subscribe to webhooks for resource changes — create, renew, and delete subscriptions on users, messages, events, drives, etc. Includes webhook payload parsing and validation.

Module: `MicrosoftGraph.Subscriptions`

| Endpoint | Method | Status | Function |
|----------|--------|--------|----------|
| `/subscriptions` | GET | ✅ | `list/1` |
| `/subscriptions/{id}` | GET | ✅ | `get/2` |
| `/subscriptions` | POST | ✅ | `create/2` |
| `/subscriptions/{id}` | PATCH | ✅ | `renew/3` |
| `/subscriptions/{id}` | DELETE | ✅ | `delete/2` |

Webhook handling: `MicrosoftGraph.Webhook` (classify, parse_notifications, valid_client_state?)

---

## Not Yet Implemented — Full API Categories

| Category | Module | Status |
|----------|--------|--------|
| Backup storage | — | ❌ Not started |
| Compliance | — | ❌ Not started |
| Cross-device experiences | — | ❌ Not started |
| Customer booking (Bookings) | — | ❌ Not started |
| Device and app management (Intune) | — | ❌ Not started |
| Education | — | ❌ Not started |
| Employee experience (Viva) | — | ❌ Not started |
| Extensions | — | ❌ Not started |
| External data connections | — | ❌ Not started |
| Identity and access | — | ❌ Not started |
| Notes (OneNote) | — | ❌ Not started |
| People and workplace intelligence | — | ❌ Not started |
| Personal contacts | — | ❌ Not started |
| Reports | — | ❌ Not started |
| Partner billing reports | — | ❌ Not started |
| Search | — | ❌ Not started |
| Security | — | ❌ Not started |
| Sites and lists (SharePoint) | — | ❌ Not started |
| Tasks and plans (Planner) | — | ❌ Not started |
| Teamwork and communications (Teams) | — | ❌ Not started |
| To-do tasks | — | ❌ Not started |
| Workbooks and charts (Excel) | — | ❌ Not started |

---

## Overall Summary

| Module | Covered | Key endpoints |
|--------|---------|---------------|
| **Users** | 30 | CRUD, manager, photo, memberships, auth methods, licenses, app roles, delta |
| **Groups** | 26 | CRUD, members, owners, transitive members, membership introspection, app role assignments, permission grants, license, delta |
| **Mail** | 9 | Messages, folders, send, draft, delta |
| **Calendar** | 8 | Events CRUD, calendar view, calendars list, delta |
| **Files** | 23 | Drives, items CRUD, copy, upload, download, permissions, sharing links, versions, thumbnails, search, shared items, delta |
| **Subscriptions** | 5 | CRUD + webhook helpers |
| **Total implemented** | **101** | |

> **Cross-cutting features:** OData query builder, batch requests, delta queries, pagination, schema casting, delegated auth (OAuth), client-request-id correlation, error handling middleware, retry middleware.
