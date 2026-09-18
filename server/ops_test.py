import json
import urllib.request
import urllib.error

BASE = "http://127.0.0.1:8085"


def req(method, path, body=None):
    data = json.dumps(body).encode() if body is not None else None
    r = urllib.request.Request(url=BASE + path, data=data, method=method,
                               headers={"Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(r) as resp:
            return resp.status, json.loads(resp.read().decode())
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read().decode())


def show(label, r):
    print(f"{label}: {r[0]} {json.dumps(r[1], sort_keys=True)}")


# setup
_, reg = req("POST", "/auth/register",
             {"username": "owner6", "password": "secret", "name": "Aanand", "role": "owner"})
owner_id = reg["user"]["id"]
_, prop = req("POST", "/properties", {"owner_id": owner_id, "name": "Green Hostel"})
prop_id = prop["property"]["id"]
_, room = req("POST", "/rooms", {"property_id": prop_id, "room_no": "101", "capacity": 4})
room_id = room["room"]["id"]
_, add = req("POST", "/inmates",
             {"property_id": prop_id, "name": "Ravi Kumar", "room_id": room_id,
              "rent_amount": 7000, "due_day": 5})
inmate_id = add["inmate"]["id"]

# complaints
s, c = req("POST", "/complaints",
           {"property_id": prop_id, "inmate_id": inmate_id,
            "category": "plumbing", "description": "Leaking tap"})
show("create complaint", (s, c))
show("list complaints", req("GET", f"/complaints?property_id={prop_id}"))
show("complaint status", req("POST", f"/complaints/{c['complaint']['id']}/status",
                             {"status": "in_progress"}))

# notices
show("create notice", req("POST", "/notices",
                          {"property_id": prop_id, "title": "Water off 2-4pm",
                           "body": "Maintenance", "category": "maintenance", "pinned": True}))
show("list notices", req("GET", f"/notices?property_id={prop_id}"))

# visitors
s, v = req("POST", "/visitors",
           {"property_id": prop_id, "name": "Rajesh", "phone": "999",
            "purpose": "meeting", "visiting_inmate_name": "Ravi Kumar"})
show("create visitor", (s, v))
show("checkout visitor", req("POST", f"/visitors/{v['visitor']['id']}/checkout"))
show("list visitors", req("GET", f"/visitors?property_id={prop_id}"))

# leave
show("create leave", req("POST", "/leave",
                         {"property_id": prop_id, "inmate_id": inmate_id,
                          "start_date": "2026-09-20", "end_date": "2026-09-22", "reason": "Home"}))
show("list leave", req("GET", f"/leave?property_id={prop_id}"))

# deposits
s, d = req("POST", "/deposits",
           {"property_id": prop_id, "inmate_id": inmate_id, "amount_collected": 10000})
show("create deposit", (s, d))
show("deduct", req("POST", f"/deposits/{d['deposit']['id']}/deduct",
                   {"reason": "Damage", "amount": 500}))
show("list deposits", req("GET", f"/deposits?property_id={prop_id}"))
show("inmate deposit", req("GET", f"/deposits?inmate_id={inmate_id}"))

# checkout
show("create checkout", req("POST", "/checkouts",
                            {"property_id": prop_id, "inmate_id": inmate_id, "vacate_date": "2026-09-30"}))
show("list checkouts", req("GET", f"/checkouts?property_id={prop_id}"))
