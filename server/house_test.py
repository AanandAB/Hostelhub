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
             {"username": "house1", "password": "secret", "name": "H", "role": "owner"})
owner = reg["user"]["id"]

# house property, rent per property, no rooms
_, prop = req("POST", "/properties",
              {"owner_id": owner, "name": "Sunset House", "type": "house", "rent_amount": 15000})
pid = prop["property"]["id"]
print("house property rent_amount:", prop["property"].get("rent_amount"))

# add a tenant with NO room_id / bed (the house/office path)
s, r = req("POST", "/inmates",
           {"property_id": pid, "name": "Sashi", "room_id": "", "bed_no": 0,
            "rent_amount": 15000, "due_day": 1})
print("add tenant (expect 201):", s)
if s == 201:
    print("  room_no:", repr(r["inmate"].get("room_no")),
          "bed_no:", r["inmate"].get("bed_no"))
else:
    print("  error:", r.get("error"))
