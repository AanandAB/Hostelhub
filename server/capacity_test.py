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
             {"username": "cap1", "password": "secret", "name": "Cap", "role": "owner"})
owner = reg["user"]["id"]
_, prop = req("POST", "/properties", {"owner_id": owner, "name": "Cap Hostel"})
pid = prop["property"]["id"]
_, room = req("POST", "/rooms", {"property_id": pid, "room_no": "1", "capacity": 1})
rid = room["room"]["id"]

s1, a1 = req("POST", "/inmates",
             {"property_id": pid, "name": "A", "room_id": rid,
              "rent_amount": 5000, "due_day": 5})
print("inmate 1 (capacity 1):", s1, "->", a1.get("inmate", {}).get("name"))

s2, a2 = req("POST", "/inmates",
             {"property_id": pid, "name": "B", "room_id": rid,
              "rent_amount": 5000, "due_day": 5})
print("inmate 2 (expect 409):", s2, "->", a2.get("error"))
