#!/usr/bin/env python3
import json, os, sys, requests

nb = os.environ.get("NETBOX_URL") or "https://netbox.example.com"
token = os.environ.get("NETBOX_TOKEN") or ""
headers = {"Authorization": f"Token {token}", "Content-Type": "application/json"}

tf_json = json.load(open(sys.argv[sys.argv.index("--tf-json")+1]))
# Expect tf outputs like: outputs: { nodes: { value: [ {name, site, role, mgmt_ip, ...}, ... ] } }
nodes = tf_json["outputs"]["nodes"]["value"]

def upsert(path, payload, lookup):
    # naive upsert: GET by unique fields, POST if missing, PATCH if present
    q = "&".join([f"{k}={requests.utils.quote(str(payload[k]))}" for k in lookup if k in payload])
    r = requests.get(f"{nb}/api/{path}?{q}", headers=headers, timeout=15)
    r.raise_for_status()
    results = r.json().get("results", [])
    if results:
        rid = results[0]["id"]
        requests.patch(f"{nb}/api/{path}{rid}/", headers=headers, json=payload, timeout=15).raise_for_status()
        return rid
    else:
        r = requests.post(f"{nb}/api/{path}", headers=headers, json=payload, timeout=15); r.raise_for_status()
        return r.json()["id"]

for n in nodes:
    site_id = upsert("dcim/sites/", {"name": n["site"], "slug": n["site"]}, ["slug"])
    role_id = upsert("dcim/device-roles/", {"name": n["role"], "slug": n["role"]}, ["slug"])
    device = {"name": n["name"], "device_role": role_id, "site": site_id}
    dev_id = upsert("dcim/devices/", device, ["name"])
    if "mgmt_ip" in n:
        # create interface + assign IP (simplified)
        iface_id = upsert("dcim/interfaces/", {"name": "mgmt0", "device": dev_id}, ["device","name"])
        ip_id = upsert("ipam/ip-addresses/", {"address": n["mgmt_ip"], "status": "active"}, ["address"])
        requests.patch(f"{nb}/api/ipam/ip-addresses/{ip_id}/", headers=headers,
                       json={"assigned_object_type":"dcim.interface","assigned_object_id":iface_id}, timeout=15)
print("Seed complete")
