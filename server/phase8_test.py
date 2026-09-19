import json
import os
import re
import time
import urllib.request
import urllib.error

BASE = "http://127.0.0.1:8082"
OUTBOX = os.path.join(os.path.dirname(__file__), "outbox")
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


# 1. Register owner + login (password now hashed)
_, reg = req("POST", "/auth/register",
             {"username": "own8", "password": "secret123", "name": "Owner", "role": "owner"})
owner = reg["user"]["id"]
s, r = req("POST", "/auth/login", {"username": "own8", "password": "secret123"})
check("owner login (hashed)", s == 200 and r["user"]["id"] == owner)
s, _ = req("POST", "/auth/login", {"username": "own8", "password": "wrong"})
check("owner login rejects wrong pw", s == 401)

# 2. Create hostel + room
_, pr = req("POST", "/properties",
            {"owner_id": owner, "name": "Sunrise Hostel", "type": "hostel"})
pid = pr["property"]["id"]
_, rm = req("POST", "/rooms", {"property_id": pid, "room_no": "101", "capacity": 2})
rid = rm["room"]["id"]

# 3. Add inmate with email
s, ni = req("POST", "/inmates", {
    "property_id": pid, "name": "Sashi", "phone": "9999999999",
    "email": "sashi@example.com", "room_id": rid, "bed_no": 1,
    "rent_amount": 15000, "due_day": 5})
iid = ni["inmate"]["id"]
check("add inmate with email", s == 201 and ni["inmate"]["email"] == "sashi@example.com")

# 4. Login as inmate (generated password, hashed)
s, r = req("POST", "/auth/login",
           {"username": ni["inmate"]["username"], "password": ni["password"]})
check("inmate login (hashed)", s == 200 and r["user"]["id"] == iid)

# 5. Invoice data
s, inv = req("GET", f"/inmates/{iid}/invoice")
check("get invoice", s == 200 and inv["invoice"]["total"] == 15000
      and inv["invoice"]["inmate"]["email"] == "sashi@example.com")

# 6. Email invoice (log transport)
before = set(os.listdir(OUTBOX)) if os.path.isdir(OUTBOX) else set()
s, ei = req("POST", f"/inmates/{iid}/invoice/email", {"month": None})
after = set(os.listdir(OUTBOX)) if os.path.isdir(OUTBOX) else set()
check("email invoice (logged)", s == 200 and ei.get("sent") is True
      and len(after - before) >= 1, f"new files={after - before}")

# 7. Forgot password -> token emailed -> reset -> login with new password
s, _ = req("POST", "/auth/forgot-password", {"email": "sashi@example.com"})
check("forgot password ok", s == 200)
time.sleep(0.3)
token = None
for fn in os.listdir(OUTBOX):
    with open(os.path.join(OUTBOX, fn), encoding="utf-8") as f:
        txt = f.read()
    m = re.search(r"reset\?token=([0-9a-f]{64})", txt)
    if m:
        token = m.group(1)
        break
check("reset link emailed with token", token is not None)
if token:
    s, rr = req("POST", "/auth/reset-password",
                {"token": token, "password": "newpass99"})
    check("reset password", s == 200 and rr.get("ok") is True)
    s, _ = req("POST", "/auth/login", {"username": ni["inmate"]["username"], "password": "newpass99"})
    check("login with new password", s == 200)
    s, _ = req("POST", "/auth/reset-password", {"token": token, "password": "again99"})
    check("token single-use", s == 400)

# 8. Room change (add room 102, move inmate)
_, rm2 = req("POST", "/rooms", {"property_id": pid, "room_no": "102", "capacity": 2})
rid2 = rm2["room"]["id"]
s, rr = req("PATCH", f"/inmates/{iid}/room", {"room_id": rid2, "bed_no": 1})
check("change room", s == 200 and rr["inmate"]["room_no"] == "102")
# capacity/bed re-validation: move a 2nd inmate into the same bed should conflict
_, ni2 = req("POST", "/inmates", {"property_id": pid, "name": "B", "room_id": rid, "bed_no": 1, "rent_amount": 1000, "due_day": 1})
s, _ = req("PATCH", f"/inmates/{ni2['inmate']['id']}/room", {"room_id": rid2, "bed_no": 1})
check("change room rejects taken bed", s == 409)

print("\n%d/%d passed" % (sum(1 for _, ok in results if ok), len(results)))
