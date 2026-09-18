import json
import urllib.request
import urllib.error

BASE = "http://127.0.0.1:8084"


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


def show(label, r):
    print(f"{label}: {r[0]} {json.dumps(r[1], sort_keys=True)}")


# owner + property + room + 2 inmates
_, reg = req("POST", "/auth/register",
             {"username": "owner5", "password": "secret", "name": "Aanand", "role": "owner"})
owner_id = reg["user"]["id"]
_, prop = req("POST", "/properties", {"owner_id": owner_id, "name": "Green Hostel"})
prop_id = prop["property"]["id"]
_, room = req("POST", "/rooms", {"property_id": prop_id, "room_no": "101", "capacity": 4})
room_id = room["room"]["id"]

ids = []
for n in ["Ravi", "Asha"]:
    _, a = req("POST", "/inmates",
               {"property_id": prop_id, "name": n, "room_id": room_id,
                "rent_amount": 7000, "due_day": 5})
    ids.append(a["inmate"]["id"])

# create poll
_, p = req("POST", "/polls",
           {"property_id": prop_id, "meal_type": "dinner", "for_date": "2026-09-20",
            "recurring": False, "options": ["Yes", "No"]})
poll_id = p["poll"]["id"]
show("create poll", (201, {"id": poll_id}))

# respond
show("respond Yes", req("POST", f"/polls/{poll_id}/respond",
                        {"inmate_id": ids[0], "response": "Yes"}))
show("respond No", req("POST", f"/polls/{poll_id}/respond",
                       {"inmate_id": ids[1], "response": "No"}))

# list responses
show("list responses", req("GET", f"/polls/{poll_id}/responses"))

# list polls
show("list polls", req("GET", f"/polls?property_id={prop_id}"))
