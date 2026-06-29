import os

MASTER_PASSWORD_REQUIRED = False
AUTHENTICATION_SOURCES = ["oauth2", "internal"]
OAUTH2_AUTO_CREATE_USER = True

OAUTH2_CONFIG = [
    {
        "OAUTH2_NAME": "oidc",
        "OAUTH2_DISPLAY_NAME": "Single Sign-On",
        "OAUTH2_CLIENT_ID": os.environ["OAUTH2_CLIENT_ID"],
        "OAUTH2_CLIENT_SECRET": os.environ["OAUTH2_CLIENT_SECRET"],
        "OAUTH2_AUTHORIZATION_URL": os.environ["OAUTH2_AUTHORIZATION_URL"],
        "OAUTH2_TOKEN_URL": os.environ["OAUTH2_TOKEN_URL"],
        "OAUTH2_API_BASE_URL": os.environ["OAUTH2_API_BASE_URL"],
        "OAUTH2_SERVER_METADATA_URL": os.environ["OAUTH2_SERVER_METADATA_URL"],
        "OAUTH2_USERINFO_ENDPOINT": os.environ.get("OAUTH2_USERINFO_ENDPOINT", "userinfo"),
        "OAUTH2_SCOPE": os.environ.get("OAUTH2_SCOPE", "openid email profile"),
        "OAUTH2_USERNAME_CLAIM": os.environ.get("OAUTH2_USERNAME_CLAIM", "email"),
        "OAUTH2_BUTTON_COLOR": "#0067c5",
    }
]
