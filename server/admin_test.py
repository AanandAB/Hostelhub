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


# admin login
s, r = req("POST", "/auth/login", {"username": "admin", "password": "admin123"})
print("admin login:", s, r.get("user", {}).get("role"))

# get pricing (defaults)
s, r = req("GET", "/pricing")
print("pricing global:", s, r["pricing"]["global"])

# update global rates
s, r = req("PATCH", "/pricing", {"monthly": 700, "yearly": 7000})
print("update global:", s, r["pricing"]["global"])

# register an owner + set a per-client override
_, reg = req("POST", "/auth/register",
             {"username": "own1", "password": "secret", "name": "O1", "role": "owner"})
oid = reg["user"]["id"]
s, r = req("PATCH", f"/pricing/overrides/{oid}",
           {"monthly": 900, "yearly": 9000, "extra_property": 250})
print("set override:", s, r["pricing"]["overrides"])

# list owners
s, r = req("GET", "/owners")
print("owners:", s, [o["username"] for o in r["owners"]])

# clear override
s, r = req("PATCH", f"/pricing/overrides/{oid}", {"clear": True})
print("clear override:", s, r["pricing"]["overrides"])
