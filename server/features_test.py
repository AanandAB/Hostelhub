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
             {"username": "feat1", "password": "secret", "name": "F", "role": "owner"})
owner = reg["user"]["id"]

# property type -> mess default
_, h = req("POST", "/properties", {"owner_id": owner, "name": "Hostel A", "type": "hostel"})
hid = h["property"]["id"]
print("hostel mess default (expect True):", h["property"]["features"].get("mess"))

_, ho = req("POST", "/properties", {"owner_id": owner, "name": "House A", "type": "house"})
hoid = ho["property"]["id"]
print("house mess default (expect False):", ho["property"]["features"].get("mess"))

# toggle mess ON for the house
s, patched = req("PATCH", f"/properties/{hoid}", {"features": {"mess": True}})
print("patch toggle mess ON:", s, patched.get("property", {}).get("features"))

s, g = req("GET", f"/properties/{hoid}")
print("get property type:", s, g.get("property", {}).get("type"))

# bed uniqueness within a room (capacity 2)
_, room = req("POST", "/rooms", {"property_id": hid, "room_no": "1", "capacity": 2})
rid = room["room"]["id"]
s1, _ = req("POST", "/inmates",
            {"property_id": hid, "name": "A", "room_id": rid, "bed_no": 1,
             "rent_amount": 5000, "due_day": 5})
print("inmate bed 1:", s1)
s2, a2 = req("POST", "/inmates",
             {"property_id": hid, "name": "B", "room_id": rid, "bed_no": 1,
              "rent_amount": 5000, "due_day": 5})
print("dup bed 1 (expect 409):", s2, a2.get("error"))
s3, _ = req("POST", "/inmates",
            {"property_id": hid, "name": "C", "room_id": rid, "bed_no": 2,
             "rent_amount": 5000, "due_day": 5})
print("inmate bed 2:", s3)
s4, a4 = req("POST", "/inmates",
             {"property_id": hid, "name": "D", "room_id": rid, "bed_no": 3,
              "rent_amount": 5000, "due_day": 5})
print("bed 3 out of range (expect 409):", s4, a4.get("error"))
