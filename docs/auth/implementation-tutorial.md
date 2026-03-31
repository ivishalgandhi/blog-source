# Implementation Tutorial: Python Authentication with Dex

This tutorial walks through setting up a Python web application that uses Dex as an identity provider to implement OIDC authentication.

## Prerequisites

- Docker and Docker Compose (for running Dex)
- Python 3.8+ installed
- Basic understanding of web concepts
- macOS environment (can be adapted for other platforms)

## Step 1: Set Up Dex Identity Provider

Dex is an identity service that uses OpenID Connect to provide authentication. We'll run it in Docker for simplicity.

### Create Docker Compose Configuration

First, create a `docker-compose.yml` file in the dex directory:

```yaml
version: '3'
services:
  dex:
    image: ghcr.io/dexidp/dex:v2.35.3
    container_name: dex
    ports:
      - "5556:5556"
    volumes:
      - ./config.yaml:/etc/dex/config.yaml
    restart: unless-stopped
```

### Configure Dex

Create a `config.yaml` file in the dex directory:

```yaml
issuer: http://localhost:5556/dex

storage:
  type: sqlite3
  config:
    file: /var/dex/dex.db

web:
  http: 0.0.0.0:5556

staticClients:
- id: python-app
  redirectURIs:
  - 'http://localhost:8000/callback'
  name: 'Python App'
  secret: python-app-secret

oauth2:
  skipApprovalScreen: true

enablePasswordDB: true
staticPasswords:
- email: "admin@example.com"
  hash: "$2a$10$2b2cU8CPhOTaGrs1HRQuAueS7JTT5ZHsHSzYiFPm1leZck7Mc8T4W" # password: password
  username: "admin"
  userID: "08a8684b-db88-4b73-90a9-3cd1661f5466"
```

This configuration:
- Sets up Dex to run on localhost:5556
- Creates a static client for our Python application
- Enables a simple password database with one user (admin@example.com)
- Configures SQLite storage for persistence

## Step 2: Create the Python Web Application

We'll create a Flask application that authenticates users via Dex using OIDC.

### Install Required Packages

Create a `requirements.txt` file in the app directory:

```
flask==2.0.1
authlib==1.0.1
requests==2.26.0
python-dotenv==0.19.1
```

### Create Application Structure

Set up the following files in the app directory:

1. `.env` - Environment variables
```
CLIENT_ID=python-app
CLIENT_SECRET=python-app-secret
ISSUER_URL=http://localhost:5556/dex
APP_SECRET_KEY=your-secret-key
```

2. `app.py` - Main application file
```python
import os
from flask import Flask, redirect, url_for, session, request, jsonify, render_template
from authlib.integrations.flask_client import OAuth
from urllib.parse import urlencode
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Flask app setup
app = Flask(__name__)
app.secret_key = os.getenv("APP_SECRET_KEY")

# OAuth setup
oauth = OAuth(app)
oauth.register(
    name='dex',
    client_id=os.getenv("CLIENT_ID"),
    client_secret=os.getenv("CLIENT_SECRET"),
    server_metadata_url=f'{os.getenv("ISSUER_URL")}/.well-known/openid-configuration',
    client_kwargs={
        'scope': 'openid email profile'
    }
)

@app.route('/')
def home():
    user = session.get('user')
    return render_template('home.html', user=user)

@app.route('/login')
def login():
    redirect_uri = url_for('callback', _external=True)
    return oauth.dex.authorize_redirect(redirect_uri)

@app.route('/callback')
def callback():
    token = oauth.dex.authorize_access_token()
    user = oauth.dex.parse_id_token(token)
    session['user'] = user
    return redirect('/')

@app.route('/logout')
def logout():
    session.pop('user', None)
    return redirect('/')

@app.route('/protected')
def protected():
    if 'user' not in session:
        return redirect('/login')
    return render_template('protected.html', user=session['user'])

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000, debug=True)
```

3. Create a `templates` directory with template files:

- `templates/home.html`:
```html
<!DOCTYPE html>
<html>
<head>
    <title>OIDC Demo</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .container { max-width: 800px; margin: 0 auto; }
        .card { border: 1px solid #ddd; padding: 20px; border-radius: 5px; }
        .btn { display: inline-block; padding: 10px 15px; background: #4285f4; color: white; 
               text-decoration: none; border-radius: 4px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>OIDC Authentication Demo</h1>
        {% if user %}
            <div class="card">
                <h2>Logged in as {{ user.email }}</h2>
                <p>User ID: {{ user.sub }}</p>
                <p><a href="/protected" class="btn">View Protected Page</a></p>
                <p><a href="/logout" class="btn">Logout</a></p>
            </div>
        {% else %}
            <p>You are not logged in.</p>
            <p><a href="/login" class="btn">Login with Dex</a></p>
        {% endif %}
    </div>
</body>
</html>
```

- `templates/protected.html`:
```html
<!DOCTYPE html>
<html>
<head>
    <title>Protected Page</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .container { max-width: 800px; margin: 0 auto; }
        .card { border: 1px solid #ddd; padding: 20px; border-radius: 5px; }
        .btn { display: inline-block; padding: 10px 15px; background: #4285f4; color: white; 
               text-decoration: none; border-radius: 4px; }
        pre { background: #f5f5f5; padding: 15px; border-radius: 5px; overflow-x: auto; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Protected Resource</h1>
        <div class="card">
            <h2>This page is only accessible to authenticated users</h2>
            <h3>Your User Profile:</h3>
            <pre>{{ user|tojson(indent=4) }}</pre>
            <p><a href="/" class="btn">Back to Home</a></p>
        </div>
    </div>
</body>
</html>
```

## Step 3: Running the Application

### Start Dex

1. Navigate to the dex directory:
```bash
cd ~/learn/auth-demo/dex
```

2. Start the Dex container:
```bash
docker-compose up -d
```

3. Verify Dex is running:
```bash
curl http://localhost:5556/dex/.well-known/openid-configuration
```

### Start the Python Application

1. Navigate to the app directory:
```bash
cd ~/learn/auth-demo/app
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

3. Start the application:
```bash
python app.py
```

4. Open http://localhost:8000 in your browser

## Step 4: Testing the Authentication Flow

1. Open the application at http://localhost:8000
2. Click "Login with Dex"
3. You'll be redirected to the Dex login page
4. Log in with:
   - Email: admin@example.com
   - Password: password
5. After successful authentication, you'll be redirected back to the application
6. You can now access the protected page, which shows your user information

## Authentication Flow Explained

The authentication flow follows the OIDC Authorization Code Flow:

1. **User initiates login**: By clicking the login button, the user is redirected to Dex's authorization endpoint
2. **Authorization request**: The app requests authorization from Dex with client ID, redirect URI, and requested scopes
3. **User authentication**: User authenticates with Dex using credentials
4. **Authorization grant**: Dex redirects back to the app's callback URL with an authorization code
5. **Token exchange**: The app exchanges the code for ID and access tokens by making a request to Dex's token endpoint
6. **Identity verification**: The app verifies the ID token and extracts user information
7. **Session creation**: The app creates a session for the authenticated user
8. **Protected resource access**: The user can now access protected resources

## Next Steps and Enhancements

1. **Add more authentication providers**: Configure Dex to connect to external providers like Google, GitHub, etc.
2. **Implement token refresh**: Add logic to refresh tokens when they expire
3. **Add role-based access control**: Extend the application to use roles or groups from the ID token
4. **Improve security**: Add CSRF protection and secure session handling
5. **Implement logout with OIDC**: Use OIDC's end_session_endpoint for proper logout

## Troubleshooting

- **Connection issues**: Ensure Dex is running and accessible at http://localhost:5556
- **Callback errors**: Verify that the redirect URI in Dex config exactly matches the application callback URL
- **Token validation errors**: Check that the client ID and secret match between Dex and the application
- **Invalid state errors**: This usually indicates session problems in the application

## Conclusion

You've successfully set up a Python web application that uses OpenID Connect for authentication through Dex. This demonstrates the core concepts of modern authentication while providing a foundation you can build upon for more complex scenarios.
