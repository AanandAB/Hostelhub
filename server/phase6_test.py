import json
import urllib.request
import urllib.error

BASE = "http://127.0.0.1:8086"


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
             {"username": "owner7", "password": "secret", "name": "Aanand", "role": "owner"})
owner_id = reg["user"]["id"]
_, prop = req("POST", "/properties", {"owner_id": owner_id, "name": "Green Hostel"})
prop_id = prop["property"]["id"]
_, room = req("POST", "/rooms", {"property_id": prop_id, "room_no": "101", "capacity": 4})
room_id = room["room"]["id"]
_, add = req("POST", "/inmates",
             {"property_id": prop_id, "name": "Ravi", "room_id": room_id,
              "rent_amount": 7000, "due_day": 5})
inmate_id = add["inmate"]["id"]

# chat
show("owner msg", req("POST", "/chat",
                      {"inmate_id": inmate_id, "sender_id": owner_id,
                       "sender_role": "owner", "text": "Hi Ravi"}))
show("inmate msg", req("POST", "/chat",
                       {"inmate_id": inmate_id, "sender_id": inmate_id,
                        "sender_role": "inmate", "text": "Hello sir"}))
show("list chat", req("GET", f"/chat?inmate_id={inmate_id}"))

# rent (income for P&L)
show("pay rent", req("POST", "/payments",
                     {"inmate_id": inmate_id, "amount": 7000, "due_date": "2026-09-05"}))

# expenses
show("add expense", req("POST", "/expenses",
                        {"property_id": prop_id, "category": "groceries",
                         "amount": 1500, "notes": "Weekly"}))
show("add expense 2", req("POST", "/expenses",
                          {"property_id": prop_id, "category": "salary", "amount": 8000}))
show("pnl", req("GET", f"/pnl?property_id={prop_id}"))

# ratings
show("add rating", req("POST", "/ratings",
                       {"property_id": prop_id, "inmate_id": inmate_id,
                        "stars": 4, "comment": "Good food"}))
show("list ratings", req("GET", f"/ratings?property_id={prop_id}"))

# sos
s, a = req("POST", "/sos", {"property_id": prop_id, "inmate_id": inmate_id})
show("create sos", (s, a))
show("acknowledge sos", req("POST", f"/sos/{a['alert']['id']}/acknowledge"))
show("list sos", req("GET", f"/sos?property_id={prop_id}"))
