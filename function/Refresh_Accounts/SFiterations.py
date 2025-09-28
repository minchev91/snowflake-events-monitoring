import os, re, json, logging, datetime
import azure.functions as func
import requests
from azure.identity import DefaultAzureCredential
# reuse your existing storage/KeyVault helper if you have one

# Where to persist the discovered accounts (choose one)
TARGET = os.getenv("SNOWFLAKE_ACCOUNTS_DEST", "file")  # "file" | "kv"
STORAGE_CONNECTION_STRING = os.getenv("AZURE_STORAGE_CONNECTION_STRING")
STATE_SHARE = os.getenv("STATE_SHARE_NAME", "funcstatemarkershare")
STATE_FILE = os.getenv("SNOWFLAKE_ACCOUNTS_FILE", "snowflake_accounts.json")
KEYVAULT_NAME = os.getenv("KEY_VAULT", None)
KEYVAULT_SECRET_NAME = os.getenv("SNOWFLAKE_ACCOUNTS_SECRET", "snowflake-accounts")

GRAPH_SCOPE = "https://graph.microsoft.com/.default"
GRAPH_BASE = "https://graph.microsoft.com/v1.0"

SNOWFLAKE_HOST_RE = re.compile(r"https://([a-z0-9\-\._]+\.snowflakecomputing\.com|[a-z0-9\-\._]+\.privatelink\.snowflakecomputing\.com)", re.I)

def get_graph_token():
    cred = DefaultAzureCredential()
    token = cred.get_token(GRAPH_SCOPE)
    return token.token

def list_snowflake_service_principals(access_token: str):
    # Broad filter, then narrow client-side:
    # - displayName contains 'Snowflake'
    # - replyUrls contain snowflakecomputing.com and end with /fed/login
    url = f"{GRAPH_BASE}/servicePrincipals?$select=id,displayName,replyUrls,applicationTemplateId"
    headers = {"Authorization": f"Bearer {access_token}"}
    items = []
    while url:
        r = requests.get(url, headers=headers, timeout=30)
        r.raise_for_status()
        data = r.json()
        items.extend(data.get("value", []))
        url = data.get("@odata.nextLink")
    snowflake_sps = []
    for sp in items:
        reply_urls = sp.get("replyUrls", []) or []
        snowflake_reply_urls = [u for u in reply_urls if "snowflakecomputing.com" in u.lower() and u.lower().endswith("/fed/login")]
        if snowflake_reply_urls:
            snowflake_sps.append({ "id": sp["id"], "displayName": sp.get("displayName"), "replyUrls": snowflake_reply_urls })
    return snowflake_sps

def derive_account_urls(sp_list):
    accounts = set()
    for sp in sp_list:
        for u in sp["replyUrls"]:
            # strip /fed/login and validate host
            base = u.split("/fed/login")[0]
            m = SNOWFLAKE_HOST_RE.match(base)
            if m:
                accounts.add(base)
    return sorted(accounts)

def save_accounts_json(account_urls, content_bytes):
    # Example using Azure File Share (since your repo already uses it)
    from azure.storage.fileshare import ShareClient, ShareFileClient
    share = ShareClient.from_connection_string(STORAGE_CONNECTION_STRING, share_name=STATE_SHARE)
    try:
        share.create_share()
    except Exception:
        pass
    file_cli = ShareFileClient.from_connection_string(STORAGE_CONNECTION_STRING, share_name=STATE_SHARE, file_path=STATE_FILE)
    try:
        file_cli.delete_file()
    except Exception:
        pass
    file_cli.upload_file(content_bytes)

def persist_accounts(account_urls):
    payload = {
        "accounts": account_urls,
        "refreshedUtc": datetime.datetime.utcnow().isoformat() + "Z"
    }
    content = json.dumps(payload, indent=2).encode("utf-8")

    if TARGET == "kv" and KEYVAULT_NAME:
        # store as a secret (JSON string)
        from azure.identity import DefaultAzureCredential
        from azure.keyvault.secrets import SecretClient
        kv = SecretClient(vault_url=f"https://{KEYVAULT_NAME}.vault.azure.net", credential=DefaultAzureCredential())
        kv.set_secret(KEYVAULT_SECRET_NAME, content.decode("utf-8"))
    else:
        save_accounts_json(account_urls, content)

# Runs daily at 02:00 UTC
# function.json -> "schedule": "0 0 2 * * *"
def main(mytimer: func.TimerRequest) -> None:
    logging.info("Refreshing Snowflake account URLs from Entra...")
    token = get_graph_token()
    sps = list_snowflake_service_principals(token)
    accounts = derive_account_urls(sps)
    if not accounts:
        logging.warning("No Snowflake accounts discovered. Check Graph permissions and SAML configs.")
    persist_accounts(accounts)
    logging.info("Discovered %d Snowflake accounts.", len(accounts))
