import json
import urllib.request
import urllib.error

BASE = "http://127.0.0.1:8083"


def req(method, path, body=None):
    data = json.dumps(body).encode() if body is not None else None
    r = urllib.request.Request(
        url=BASE + path, data=data, method=method,
        headers={"Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(r) as resp:
            return resp.status, json.loads(resp.read().decode())
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read().decode())


def show(label, result):
    status, data = result
    print(f"{label}: {status} {json.dumps(data, sort_keys=True)}")


# 1. register owner
_, reg = req("POST", "/auth/register",
             {"username": "owner4", "password": "secret", "name": "Aanand", "role": "owner"})
owner_id = reg["user"]["id"]
show("register owner", (201, reg))

# 2. create property
_, prop = req("POST", "/properties",
              {"owner_id": owner_id, "name": "Green Hostel", "address": "Kochi"})
prop_id = prop["property"]["id"]

# 3. add room
_, room = req("POST", "/rooms",
              {"property_id": prop_id, "room_no": "101", "capacity": 3})
room_id = room["room"]["id"]

# 4. add inmate
s, add = req("POST", "/inmates",
             {"property_id": prop_id, "name": "Ravi Kumar", "phone": "9876543210",
              "room_id": room_id, "bed_no": 1, "rent_amount": 7000,
              "due_day": 5, "join_date": "2026-09-19"})
show("add inmate", (s, add))
inmate = add["inmate"]
username = inmate["username"]
password = add["password"]
inmate_id = inmate["id"]

# 5. login with correct password
show("login correct", req("POST", "/auth/login",
                          {"username": username, "password": password}))

# 6. login with wrong password (expect 401)
show("login wrong", req("POST", "/auth/login",
                        {"username": username, "password": "wrongpw"}))

# 7. rent plan
show("rent plan", req("GET", f"/rent-plans?inmate_id={inmate_id}"))

# 8. pay rent
show("pay rent", req("POST", "/payments",
                     {"inmate_id": inmate_id, "amount": 7000, "due_date": "2026-09-05"}))

# 9. list payments
show("list payments", req("GET", f"/payments?inmate_id={inmate_id}"))
