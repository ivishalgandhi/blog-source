# Setting Up Radicale with Remind and TaskWarrior Integration

This guide provides a step-by-step configuration for hosting a Radicale CalDAV server in a Proxmox LXC container, accessible via Tailscale. It integrates Remind `.rem` files and TaskWarrior tasks using the `radicale-remind` backend for native, two-way synchronization. As an alternative for TaskWarrior only, it covers using `syncall`. The focus is on displaying Remind events in Apple Calendar and TaskWarrior tasks in Apple Reminders (or Calendar if converted to events).

**Key Notes:**
- This assumes you're using a Proxmox LXC container with Radicale already installed (e.g., via community script).
- Remind data appears as VEVENT (events) in Calendar.
- TaskWarrior data appears as VTODO (tasks) in Reminders. For tasks as events in Calendar, you'd need custom scripting (not covered here; refer to prior custom Python approach if needed).
- All commands are run inside the LXC container unless specified.
- Replace placeholders like `youruser`, `yourpass`, `/path/to/your/.reminders`, and Tailscale IP with your actual values.

## Prerequisites
- Proxmox LXC container with Radicale installed and running.
- Tailscale set up in the LXC (with TUN device enabled and authenticated).
- Basic tools: `apt update && apt upgrade -y`.
- Your Remind `.rem` file (e.g., `~/.reminders`) and TaskWarrior data (e.g., `~/.task`).

## Step 1: Install Dependencies
Inside the LXC container:
```bash
apt install remind task -y
pip3 install radicale-remind
```
- If using `syncall` alternative: `pip3 install 'syncall[caldav,tw]'`.

## Step 2: Configure Radicale for radicale-remind Backend
Edit the Radicale configuration file (typically `/etc/radicale/config`):
```ini
[server]
hosts = 0.0.0.0:5232

[auth]
type = htpasswd
htpasswd_filename = /etc/radicale/users
htpasswd_encryption = bcrypt  # Or sha512

[rights]
type = owner_only  # Or custom; see Step 3

[storage]
type = radicale_remind
filesystem_folder = /var/lib/radicale  # Path for user collections
remind_file = /path/to/your/.reminders  # Full path to your .rem file
task_folder = /path/to/your/.task  # Full path to your TaskWarrior folder
```
- Omit `remind_file` or `task_folder` if not using one.
- Ensure the paths are accessible by the Radicale user (e.g., chown if needed).

## Step 3: Configure Rights for Access
Create or edit the rights file (e.g., `/etc/radicale/rights`):
```ini
[root]
user: .+
collection:
permissions: R

[principal]
user: .+
collection: {user}
permissions: RW

[calendars]
user: .+
collection: {user}/.*
permissions: rw
```
- This allows read/write access to collections like `{user}/.reminders/` and `{user}/.task/all_projects/`.
- Restart Radicale: `systemctl restart radicale`.

## Step 4: Set Up Authentication
If not already done:
```bash
apt install apache2-utils -y
htpasswd -B -c /etc/radicale/users youruser  # Enter yourpass
```
- Restart Radicale again.

## Step 5: Test Collections
Verify the integration:
```bash
curl -u youruser:yourpass -X PROPFIND -H "Depth: 1" "http://localhost:5232/youruser/.reminders/"
curl -u youruser:yourpass -X PROPFIND -H "Depth: 1" "http://localhost:5232/youruser/.task/all_projects/"
```
- Collections should list your events/tasks.
- Use your Tailscale IP instead of `localhost` for remote testing.

## Step 6: Connect to Apple Apps
- **For Remind (Calendar App):**
  1. Open Calendar (macOS/iOS).
  2. Add Account > Other > CalDAV.
  3. Server: `your-tailscale-ip:5232/youruser/.reminders/`
  4. Username: `youruser`
  5. Password: `yourpass`
  - Events from `.rem` files will appear.

- **For TaskWarrior (Reminders App):**
  1. Open Reminders (macOS/iOS).
  2. Add Account > Other > CalDAV (or in Settings > Accounts).
  3. Server: `your-tailscale-ip:5232/youruser/.task/all_projects/`
  4. Username: `youruser`
  5. Password: `yourpass`
  - Tasks sync with due dates; edits sync back.

- Two-way sync: Changes in Apple apps update your files.

## Alternative: Using syncall for TaskWarrior Only
If you prefer not to use `radicale-remind` and keep default Radicale storage:
1. Install: Already done in Step 1.
2. Create a calendar collection in Radicale (if needed):
   ```bash
   curl -u youruser:yourpass -X MKCOL "http://localhost:5232/youruser/main-calendar/"
   ```
3. Set up cron for sync (e.g., every 15 minutes):
   - Edit crontab: `crontab -e`
   - Add: `*/15 * * * * tw_caldav_sync --caldav-url http://localhost:5232/youruser/main-calendar/ --caldav-user youruser --caldav-passwd yourpass --taskwarrior-tags optional-tag-filter`
4. Connect in Reminders: Use `your-tailscale-ip:5232/youruser/main-calendar/` as the server.
- This is one-way by default; check `syncall` docs for two-way options.

## Limitations and Troubleshooting
- **Limitations:**
  - Separate collections: No automatic merge into one calendar.
  - Tasks in Reminders, not Calendar (unless custom conversion).
  - Not all features sync perfectly (e.g., complex recurrences).
  - If using Abook, it can be added as CardDAV.

- **Troubleshooting:**
  - Check logs: `journalctl -u radicale`.
  - Ensure Tailscale is connected and ports are open.
  - Test locally first before remote.
  - If errors: Verify file paths, permissions, and restart services.
  - For HTTPS: Add an Nginx reverse proxy in the LXC.

- **References:**
  - [radicale-remind GitHub](https://github.com/jspricke/radicale-remind)
  - [syncall TaskWarrior-CalDAV Docs](https://github.com/bergercookie/syncall/blob/master/docs/readme-tw-caldav.md)

This Markdown file can be saved as `radicale-setup-guide.md` for reference. Follow steps sequentially, testing after each. If issues arise, provide details for further help.


python3 rem2dav.py -r http://radicale:5232/vishal/51e7ed21-253c-7596-8416-d6f1efbf2825/ -u vishal -p Ishaan@240978 -i /root/remind/reminders.rem 

```shell
# Export TaskWarrior tasks with due dates and import them into Radicale as VTODOs
task export rc.verbose:nothing | jq -r '
  .[] |
  select(.due != null) |
  "REM " + (.due | strptime("%Y%m%dT%H%M%SZ") | strftime("%b %d %Y")) +
  " MSG " +
  (if .status == "completed" then "DONE: " else "TODO: " end) +
  (if .project then .project + " - " else "" end) +
  .description
' | python3 rem2dav.py -d -i -r 'http://radicale:5232/vishal/51e7ed21-253c-7596-8416-d6f1efbf2825/' -u 'vishal' -p 'Ishaan@240978' -
```
```shell
# 1. Generate the file
task export rc.verbose:nothing | jq -r '...' > sync.rem

# 2. Sync it
python3 rem2dav.py -d -i -r 'http://radicale:5232/vishal/51e7ed21-253c-7596-8416-d6f1efbf2825/' -u 'vishal' -p 'Ishaan@240978' sync.rem
```

```shell

# Directly sync Remind file to Radicale with deletion of missing events
❯ python3 rem2dav.py -d -r https://radicale.tail48fe8.ts.net/vishal/7a1ffa71-e5cc-1a70-a5e9-d51de8decab8/ -u vishal -p 'Ishaan@240978' /Users/vishal/code/remind/reminders.rem
```

Key Changes Explanation
-d: Deletes events on the server that are not in your input. This fixes the duplication issue when you change task details (since the UIDs change).
-i: Ensures "insecure" mode (ignores SSL errors), which was in your original command.
- (in Option 1): Crucial argument at the very end that tells the script "read the reminders from the pipe/command before me".