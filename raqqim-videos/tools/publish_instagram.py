"""Publish a day's video as an Instagram Reel through the Graph API.

usage: python3 publish_instagram.py YYYY-MM-DD

Env: IG_ACCESS_TOKEN, IG_USER_ID (set in the cloud environment, never in the repo).
Exits 0 and skips quietly when the secrets are missing, so the daily routine never breaks.
Exits 1 on a real publish failure (the video stays on the page either way).
"""
import json, os, sys, time, pathlib, urllib.request, urllib.parse, urllib.error

API = "https://graph.facebook.com/v21.0"
BASE = "https://hussiensameer.github.io/app/raqqim-videos"
root = pathlib.Path(__file__).resolve().parent.parent
day = sys.argv[1]
token, uid = os.environ.get("IG_ACCESS_TOKEN"), os.environ.get("IG_USER_ID")
if not token or not uid:
    print("SKIP: IG_ACCESS_TOKEN / IG_USER_ID not set"); sys.exit(0)

log_path = root / "instagram-posted.json"
log = json.loads(log_path.read_text(encoding="utf-8")) if log_path.exists() else {}
if day in log:
    print("SKIP: already posted", log[day]); sys.exit(0)

video_url = f"{BASE}/videos/raqqim-video-{day}.mp4"
caption = (root / "captions" / f"raqqim-caption-{day}.txt").read_text(encoding="utf-8").strip()

def call(method, path, **params):
    params["access_token"] = token
    data = urllib.parse.urlencode(params).encode()
    url = f"{API}/{path}"
    req = urllib.request.Request(url, data=data) if method == "POST" else urllib.request.Request(f"{url}?{data.decode()}")
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            return json.load(r)
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", "replace")
        body = body.replace(token, "***")
        print("Graph API error:", e.code, body); sys.exit(1)

# 1) wait until Pages serves the file (Instagram fetches it from this URL)
for _ in range(60):
    try:
        req = urllib.request.Request(video_url, method="HEAD")
        with urllib.request.urlopen(req, timeout=30) as r:
            if r.status == 200: break
    except Exception:
        pass
    time.sleep(15)
else:
    print("Video URL not reachable yet:", video_url); sys.exit(1)

# 2) create the Reel container, 3) wait for processing, 4) publish
c = call("POST", f"{uid}/media", media_type="REELS", video_url=video_url, caption=caption, share_to_feed="true")["id"]
for _ in range(60):
    st = call("GET", c, fields="status_code")["status_code"]
    if st == "FINISHED": break
    if st in ("ERROR", "EXPIRED"):
        print("Container status:", st); sys.exit(1)
    time.sleep(10)
else:
    print("Container not ready in time"); sys.exit(1)
media_id = call("POST", f"{uid}/media_publish", creation_id=c)["id"]
link = call("GET", media_id, fields="permalink").get("permalink", "")
log[day] = link or media_id
log_path.write_text(json.dumps(log, ensure_ascii=False, indent=2), encoding="utf-8")
print("POSTED", link or media_id)
