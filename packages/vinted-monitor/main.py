#!/usr/bin/env python3
"""Poll a single Vinted search and send new listings to ntfy."""

import json
import logging
import os
import sys
from pathlib import Path
from typing import Optional
from urllib.parse import parse_qsl, urlsplit

import requests

USER_AGENT = "Mozilla/5.0 (X11; Linux x86_64; rv:140.0) Gecko/20100101 Firefox/140.0"
MAX_SEEN = 5000
FAILURE_ALERT_THRESHOLD = 12

# Browser search URLs use the legacy filter names; svc-catalogue silently
# ignores those and expects attribute_ids[<name>] with comma-joined values.
ATTRIBUTE_PARAMS = {
    "catalog[]": "catalog",
    "catalog_ids[]": "catalog",
    "brand_ids[]": "brand",
    "size_ids[]": "size",
    "status_ids[]": "status",
    "color_ids[]": "color",
    "material_ids[]": "material",
}
PASSTHROUGH_PARAMS = {"search_text", "price_from", "price_to", "currency"}


def search_params(search_url: str) -> dict[str, str]:
    """Translate a browser catalog URL into svc-catalogue query parameters.

    `time` and `page` are dropped: `time` pins the search to a snapshot.
    """
    attributes: dict[str, list[str]] = {}
    params: dict[str, str] = {}
    for key, value in parse_qsl(urlsplit(search_url).query):
        if not value:
            continue
        if key in ATTRIBUTE_PARAMS:
            attributes.setdefault(ATTRIBUTE_PARAMS[key], []).append(value)
        elif key in PASSTHROUGH_PARAMS:
            params[key] = value
    for name, values in attributes.items():
        params[f"attribute_ids[{name}]"] = ",".join(values)
    params["order"] = "newest_first"
    params["per_page"] = "96"
    params["page"] = "1"
    return params


class NtfyClient:
    def __init__(self, topic: str, server_url: str = "https://ntfy.sh"):
        self.topic = topic
        self.server_url = server_url.rstrip("/")
        self.logger = logging.getLogger("ntfy")

    def send(self, title: str, message: str, headers: Optional[dict[str, str]] = None) -> None:
        try:
            resp = requests.post(
                f"{self.server_url}/{self.topic}",
                data=message.encode("utf-8"),
                headers={"Title": title, **(headers or {})},
                timeout=30,
            )
            resp.raise_for_status()
            self.logger.debug(f"Sent ntfy notification: {title}")
        except Exception as e:
            self.logger.warning(f"Failed to send ntfy notification: {e}")


class VintedClient:
    def __init__(self, base_url: str, cookies: dict[str, str]):
        host = urlsplit(base_url).netloc
        self.base_url = f"https://{host}"
        self.api_url = f"https://api.{host.removeprefix('www.')}/svc-catalogue/items"
        self.session = requests.Session()
        self.session.headers.update(
            {
                "User-Agent": USER_AGENT,
                "Accept": "application/json",
                "Accept-Language": "fi-FI,fi;q=0.9,en;q=0.8",
            }
        )
        self.session.cookies.update(cookies)
        self.logger = logging.getLogger("vinted")

    def cookies(self) -> dict[str, str]:
        return self.session.cookies.get_dict()

    def refresh_cookies(self) -> None:
        self.logger.info("Fetching fresh anonymous session cookies")
        self.session.cookies.clear()
        resp = self.session.head(f"{self.base_url}/", timeout=30)
        resp.raise_for_status()

    def search(self, params: dict[str, str]) -> list[dict]:
        if "access_token_web" not in self.cookies():
            self.refresh_cookies()
        resp = self._get(params)
        if resp.status_code in (401, 403):
            self.refresh_cookies()
            resp = self._get(params)
        resp.raise_for_status()
        data = resp.json()
        if not isinstance(data.get("items"), list):
            raise ValueError(f"Unexpected response without items: {str(data)[:200]}")
        return data["items"]

    def _get(self, params: dict[str, str]) -> requests.Response:
        cookies = self.cookies()
        headers = {
            "Authorization": f"Bearer {cookies.get('access_token_web', '')}",
            "x-anon-id": cookies.get("anon_id", ""),
        }
        return self.session.get(self.api_url, params=params, headers=headers, timeout=30)


def load_state(path: Path) -> Optional[dict]:
    if not path.exists():
        return None
    try:
        return json.loads(path.read_text())
    except (OSError, json.JSONDecodeError) as e:
        logging.warning(f"Ignoring unreadable state file: {e}")
        return None


def save_state(path: Path, state: dict) -> None:
    tmp = path.with_suffix(".tmp")
    tmp.write_text(json.dumps(state))
    tmp.replace(path)


def format_price(price: dict) -> str:
    return f"{price['amount']} {price['currency_code']}"


def notify_item(ntfy: NtfyClient, base_url: str, item: dict) -> None:
    title = f"{item['title']} - {format_price(item['price'])}"
    box = item.get("item_box", {})
    details = " · ".join(filter(None, [box.get("first_line"), box.get("second_line")]))
    total = item.get("total_item_price")
    if total:
        details += f"\n{format_price(total)} incl. buyer protection"
    headers = {"Click": f"{base_url}{item['url']}", "Tags": "shopping_bags"}
    photo = (item.get("photo") or {}).get("url")
    if photo:
        headers["Attach"] = photo
    ntfy.send(title, details, headers)


def main() -> int:
    logging.basicConfig(level=logging.INFO, format="%(levelname)s %(name)s: %(message)s")

    search_url = os.environ["VINTED_SEARCH_URL"]
    state_file = Path(os.environ.get("STATE_FILE", "state.json"))
    topic = Path(os.environ["NTFY_TOPIC_FILE"]).read_text().strip()
    ntfy = NtfyClient(topic)

    state = load_state(state_file) or {"seen": [], "cookies": {}, "failures": 0}
    first_run = not state.get("initialized")
    params = search_params(search_url)
    vinted = VintedClient(search_url, state.get("cookies", {}))

    try:
        items = vinted.search(params)
    except Exception as e:
        state["failures"] = state.get("failures", 0) + 1
        logging.error(f"Search failed ({state['failures']} in a row): {e}")
        # Expired tokens don't always fail with 401/403, so start the next run fresh.
        state["cookies"] = {}
        if state["failures"] == FAILURE_ALERT_THRESHOLD:
            ntfy.send(
                "Vinted monitor is failing",
                f"{state['failures']} searches in a row failed. Last error: {e}",
                {"Priority": "high", "Tags": "warning"},
            )
        save_state(state_file, state)
        return 1

    if state.get("failures", 0) >= FAILURE_ALERT_THRESHOLD:
        ntfy.send("Vinted monitor recovered", "Searches are working again.", {"Tags": "white_check_mark"})
    state["failures"] = 0
    state["cookies"] = vinted.cookies()

    seen = set(state["seen"])
    new_items = [item for item in items if item["id"] not in seen]
    if first_run:
        logging.info(f"First run: recording {len(items)} existing items without notifying")
    else:
        logging.info(f"{len(items)} items, {len(new_items)} new")
        for item in reversed(new_items):
            notify_item(ntfy, vinted.base_url, item)

    state["initialized"] = True
    state["seen"] = (state["seen"] + [item["id"] for item in new_items])[-MAX_SEEN:]
    save_state(state_file, state)
    return 0


if __name__ == "__main__":
    sys.exit(main())
