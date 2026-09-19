import json
import urllib.request
import urllib.error

BASE = "https://YOUR-WORKER.workers.dev"  # set to your deployed Worker URL
results = []


def req(m, p, b=None):
    d = json.dumps(b).encode() if b is not None else None
    r = urllib.request.Request(BASE + p, data=d, method=m,
                               headers={"Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(r) as x:
            return x.status, json.loads(x.read())
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read())


def check(name, ok, extra=""):
    results.append((name, ok))
    print(("PASS " if ok else "FAIL ") + name + ("  " + str(extra) if extra else ""))


s, r = req("GET", "/health")
check("health", s == 200 and r.get("status") == "ok")

s, reg = req("POST", "/auth/register", {"username": "owner1", "password": "secret123", "name": "Owner One", "role": "owner"})
owner = reg["user"]["id"]
check("register owner", s == 201 and "password" not in reg["user"])

s, r = req("POST", "/auth/login", {"username": "owner1", "password": "secret123"})
check("login hashed", s == 200 and r["user"]["id"] == owner)
s, _ = req("POST", "/auth/login", {"username": "owner1", "password": "wrong"})
check("reject wrong pw", s == 401)

s, pr = req("POST", "/properties", {"owner_id": owner, "name": "Cloud Hostel", "type": "hostel"})
pid = pr["property"]["id"]
check("create property", s == 201 and pr["property"].get("features", {}).get("mess") is True)

s, rm = req("POST", "/rooms", {"property_id": pid, "room_no": "101", "capacity": 2})
rid = rm["room"]["id"]
check("create room", s == 201)

s, ni = req("POST", "/inmates", {"property_id": pid, "name": "Sashi", "phone": "9999999999", "email": "sashi@example.com", "room_id": rid, "bed_no": 1, "rent_amount": 15000, "due_day": 5})
iid = ni["inmate"]["id"]
check("add inmate w/ email", s == 201 and ni["inmate"]["email"] == "sashi@example.com")

s, inv = req("GET", f"/inmates/{iid}/invoice")
check("invoice", s == 200 and inv["invoice"]["total"] == 15000)

s, _ = req("POST", "/auth/forgot-password", {"email": "sashi@example.com"})
check("forgot password", s == 200)

s, rooms = req("GET", f"/rooms?property_id={pid}")
check("list rooms", s == 200 and len(rooms["rooms"]) == 1)

print("\n%d/%d passed" % (sum(1 for _, ok in results if ok), len(results)))
