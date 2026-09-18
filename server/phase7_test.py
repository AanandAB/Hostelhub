import json
import urllib.request
import urllib.error

BASE = "http://127.0.0.1:8087"


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


_, reg = req("POST", "/auth/register",
             {"username": "owner8", "password": "secret", "name": "Aanand",
              "role": "owner"})
owner_id = reg["user"]["id"]

# multi-property: two hostels under one owner
_, p1 = req("POST", "/properties",
            {"owner_id": owner_id, "name": "Green Hostel"})
_, p2 = req("POST", "/properties",
            {"owner_id": owner_id, "name": "Blue Hostel"})
show("list properties", req("GET", f"/properties?owner_id={owner_id}"))

# document vault: per-hostel + per-inmate docs are isolated
show("add hostel doc (Green)",
     req("POST", "/documents",
         {"owner_type": "hostel", "owner_id": p1["property"]["id"],
          "name": "Rent Agreement", "type": "agreement"}))
show("add hostel doc (Blue)",
     req("POST", "/documents",
         {"owner_type": "hostel", "owner_id": p2["property"]["id"],
          "name": "House Rules", "type": "rules"}))
show("list docs Green",
     req("GET", f"/documents?owner_type=hostel&owner_id={p1['property']['id']}"))
show("list docs Blue",
     req("GET", f"/documents?owner_type=hostel&owner_id={p2['property']['id']}"))
