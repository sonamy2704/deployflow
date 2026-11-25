import app as app_module
from app import app


def client():
    return app.test_client()


def test_health():
    r = client().get("/health")
    assert r.status_code == 200
    assert r.get_json() == {"status": "ok"}


def test_version_default():
    r = client().get("/version")
    assert r.status_code == 200
    assert "version" in r.get_json()


def test_status_reads_log(tmp_path, monkeypatch):
    log = tmp_path / "history.log"
    log.write_text(
        "2026-11-25T10:00:00+00:00 SUCCESS ghcr.io/u/deployflow:aaa\n"
        "2026-11-25T11:00:00+00:00 FAILED ghcr.io/u/deployflow:bbb rolled back\n"
    )
    monkeypatch.setattr(app_module, "DEPLOY_LOG", str(log))
    data = client().get("/status").get_json()
    assert data["deployments"][0]["status"] == "FAILED"
    assert data["deployments"][1]["status"] == "SUCCESS"


def test_status_no_log(tmp_path, monkeypatch):
    monkeypatch.setattr(app_module, "DEPLOY_LOG", str(tmp_path / "missing.log"))
    assert client().get("/status").get_json()["deployments"] == []


def test_index_renders():
    assert client().get("/").status_code == 200
