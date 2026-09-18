import json
import urllib.request
import urllib.error

BASE = "http://127.0.0.1:8081"


def req(m, p, b=None):
    d = json.dumps(b).encode() if b is not None else None
    r = urllib.request.Request(BASE + p, data=d, method=m,
                               headers={"Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(r) as x:
            return x.status, json.loads(x.read())
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read())


_, reg = req("POST", "/auth/register",
             {"username": "sub1", "password": "secret", "name": "S", "role": "owner"})
owner = reg["user"]["id"]

# default subscription
s, sub = req("GET", f"/subscriptions/{owner}")
print("default sub:", s, sub.get("subscription", {}).get("status"),
      "limit", sub.get("subscription", {}).get("property_limit"))

# 1st property ok
s1, _ = req("POST", "/properties", {"owner_id": owner, "name": "P1", "type": "hostel"})
print("create property 1:", s1)
# 2nd property blocked (limit 1)
s2, a2 = req("POST", "/properties", {"owner_id": owner, "name": "P2", "type": "hostel"})
print("create property 2 (expect 403):", s2, a2.get("error"))

# upgrade -> 2nd property allowed
req("POST", f"/subscriptions/{owner}/upgrade")
s3, _ = req("POST", "/properties", {"owner_id": owner, "name": "P2", "type": "hostel"})
print("after upgrade, create property 2:", s3)

# expire -> login blocked
req("POST", f"/subscriptions/{owner}/expire")
sl, al = req("POST", "/auth/login", {"username": "sub1", "password": "secret"})
print("login while expired (expect 403):", sl, al.get("error"))
req("POST", f"/subscriptions/{owner}/renew")
sl2, _ = req("POST", "/auth/login", {"username": "sub1", "password": "secret"})
print("login after renew:", sl2)

# checkout + deposit settlement + stay history
pid = req("GET", f"/properties?owner_id={owner}")[1]["properties"][0]["id"]
_, room = req("POST", "/rooms", {"property_id": pid, "room_no": "1", "capacity": 2})
rid = room["room"]["id"]
_, add = req("POST", "/inmates",
             {"property_id": pid, "name": "Ravi", "room_id": rid,
              "rent_amount": 6000, "due_day": 5})
iid = add["inmate"]["id"]
req("POST", "/deposits",
    {"property_id": pid, "inmate_id": iid, "amount_collected": 10000})
_, co = req("POST", "/checkouts",
            {"property_id": pid, "inmate_id": iid, "vacate_date": "2026-09-30"})
cid = co["checkout"]["id"]
s, done = req("POST", f"/checkouts/{cid}/complete", {"refund": 8000, "forfeit": 2000})
print("complete checkout:", s, done.get("checkout", {}).get("status"))
_, dep = req("GET", f"/deposits?inmate_id={iid}")
d = dep["deposits"][0]
total_ded = sum(x["amount"] for x in d.get("deductions", []))
print("deposit deducted total (expect 2000):", total_ded)
_, inmates = req("GET", f"/inmates?property_id={pid}")
print("inmate checkout_date:", inmates["inmates"][0].get("checkout_date"))
