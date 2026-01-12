import os
import sys

import requests


def load_secret(path: str) -> str:
    with open(path) as f:
        return f.read().strip()


def load_last_event_id(state_dir: str) -> int:
    state_file = os.path.join(state_dir, "last_event_id")
    if os.path.exists(state_file):
        with open(state_file) as f:
            return int(f.read().strip())
    return 0


def save_last_event_id(state_dir: str, event_id: int) -> None:
    state_file = os.path.join(state_dir, "last_event_id")
    with open(state_file, "w") as f:
        f.write(str(event_id))


def get_activity(api_key: str, limit: int = 100) -> list:
    response = requests.post(
        "https://api.todoist.com/sync/v9/activity/get",
        headers={"Authorization": f"Bearer {api_key}"},
        json={"event_type": "completed", "limit": limit},
        timeout=30,
    )
    response.raise_for_status()
    return response.json().get("events", [])


def send_to_letta(
    base_url: str, password: str, agent_id: str, message: str
) -> None:
    response = requests.post(
        f"{base_url}/v1/agents/{agent_id}/messages",
        headers={
            "Authorization": f"Bearer {password}",
            "Content-Type": "application/json",
        },
        json={"messages": [{"role": "system", "content": message}]},
        timeout=120,
    )
    response.raise_for_status()


def main() -> None:
    todoist_api_key = load_secret(os.environ["TODOIST_API_KEY_FILE"])
    letta_password = load_secret(os.environ["LETTA_PASSWORD_FILE"])
    letta_base_url = os.environ["LETTA_BASE_URL"]
    agent_ids = load_secret(os.environ["AGENT_IDS_FILE"]).split(",")
    state_dir = os.environ["STATE_DIR"]

    last_event_id = load_last_event_id(state_dir)
    is_initial = last_event_id == 0
    print(f"Last event ID: {last_event_id}")

    events = get_activity(todoist_api_key)
    print(f"Fetched {len(events)} completion events")

    new_events = [e for e in events if e.get("id", 0) > last_event_id]
    print(f"New events since last check: {len(new_events)}")

    if events:
        max_id = max(e.get("id", 0) for e in events)
        save_last_event_id(state_dir, max_id)
        print(f"Saved new last event ID: {max_id}")

    if is_initial:
        print("Initial run, skipping notifications")
        return

    if not new_events:
        print("No new completions")
        return

    for event in new_events:
        extra = event.get("extra_data", {})
        task_name = extra.get("content", "Unknown task")
        message = f"[Todoist Event] Task completed: {task_name}"
        print(f"Notifying agents: {message}")
        for agent_id in agent_ids:
            try:
                send_to_letta(
                    letta_base_url, letta_password, agent_id, message
                )
                print(f"Notification sent to {agent_id}")
            except requests.RequestException as e:
                print(f"Failed to notify {agent_id}: {e}", file=sys.stderr)
                sys.exit(1)


if __name__ == "__main__":
    main()
