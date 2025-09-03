import json, threading, os
_LOCK = threading.Lock()
_PATH = os.getenv("MODEL_APPROVALS_PATH", "approvals.json")

def _load():
    if not os.path.exists(_PATH): return {"approved": {}}
    with open(_PATH,"r") as f: return json.load(f)

def _save(data):
    with open(_PATH,"w") as f: json.dump(data, f, indent=2)

def get_approvals():
    with _LOCK:
        return _load()

def set_approved(version: str, approved: bool):
    with _LOCK:
        data = _load()
        data.setdefault("approved", {})[version] = approved
        _save(data)
        return data
