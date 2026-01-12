#!/usr/bin/env python3
"""
Script to register Todoist tools with Letta.

Usage (NixOS):
    cd /tmp && nix-shell -p python3 python3Packages.pip python3Packages.requests python3Packages.virtualenv --run "
    python -m venv .letta-venv
    source .letta-venv/bin/activate
    pip install --quiet letta-client
    python /home/juggeli/src/dotfiles/modules/nixos/containers/letta-register-todoist-tools.py
    "

After registration, attach the tools to your agent and set TODOIST_API_KEY in agent secrets.

---
EMBEDDING CONFIG NOTE:
Agents use nomic-embed-text-v1.5 via synthetic API (4096 dims).
New agents won't have this by default - set it via SDK.
IMPORTANT: Set embedding=None to clear the handle, otherwise it reverts!
WARNING: Archives and agent archival memory are linked - deleting an archive nukes agent passages!

    from letta_client import Letta
    client = Letta(base_url="https://letta.jugi.cc", api_key=open("/run/agenix/letta-password").read().strip())

    client.agents.update(
        agent_id="agent-xxx",
        embedding=None,  # Clear handle to prevent revert
        embedding_config={
            "embedding_model": "hf:nomic-ai/nomic-embed-text-v1.5",
            "embedding_endpoint": "https://api.synthetic.new/openai/v1",
            "embedding_endpoint_type": "openai",
            "embedding_dim": 4096,
            "embedding_chunk_size": 300,
        }
    )
"""

import os

from letta_client import Letta

LETTA_BASE_URL = os.environ.get("LETTA_BASE_URL", "https://letta.jugi.cc")
LETTA_PASSWORD_FILE = "/run/agenix/letta-password"


def list_todoist_projects() -> str:
    """
    List all projects in Todoist.

    Returns:
        str: JSON string containing list of projects with their IDs and names.
    """
    import json
    import os

    import requests

    api_key = os.environ.get("TODOIST_API_KEY")
    if not api_key:
        return "Error: TODOIST_API_KEY not set"

    response = requests.get(
        "https://api.todoist.com/rest/v2/projects",
        headers={"Authorization": f"Bearer {api_key}"},
    )

    if not response.ok:
        return f"Error: {response.text}"

    projects = [{"id": p["id"], "name": p["name"]} for p in response.json()]
    return json.dumps(projects, indent=2)


def list_todoist_tasks(project_id: str = None, filter_query: str = None) -> str:
    """
    List tasks from Todoist with optional filtering.

    Args:
        project_id (str): Optional project ID to filter tasks by project.
        filter_query (str): Optional Todoist filter query (e.g., "today", "overdue", "p1", "tomorrow").

    Returns:
        str: JSON string containing list of tasks with their details.
    """
    import json
    import os

    import requests

    api_key = os.environ.get("TODOIST_API_KEY")
    if not api_key:
        return "Error: TODOIST_API_KEY not set"

    params = {}
    if project_id:
        params["project_id"] = project_id
    if filter_query:
        params["filter"] = filter_query

    response = requests.get(
        "https://api.todoist.com/rest/v2/tasks",
        headers={"Authorization": f"Bearer {api_key}"},
        params=params,
    )

    if not response.ok:
        return f"Error: {response.text}"

    tasks = [
        {
            "id": t["id"],
            "content": t["content"],
            "description": t.get("description", ""),
            "priority": 5 - t["priority"],
            "due": t.get("due", {}).get("string") if t.get("due") else None,
            "is_recurring": t.get("due", {}).get("is_recurring", False) if t.get("due") else False,
            "project_id": t["project_id"],
            "labels": t.get("labels", []),
        }
        for t in response.json()
    ]
    return json.dumps(tasks, indent=2)


def add_todoist_task(
    content: str,
    description: str = None,
    project_id: str = None,
    due_string: str = None,
    priority: int = None,
    labels: str = None,
) -> str:
    """
    Create a new task in Todoist.

    Args:
        content (str): The task title/content. Required.
        description (str): Optional longer description for the task.
        project_id (str): Optional project ID to add task to. Defaults to Inbox if not specified.
        due_string (str): Optional natural language due date. Supports recurring (e.g., "tomorrow", "every monday", "every 2 weeks at 9am").
        priority (int): Optional priority P1-P4 where P1=urgent, P4=normal. Pass 1, 2, 3, or 4.
        labels (str): Optional comma-separated list of label names to apply.

    Returns:
        str: Confirmation message with task ID and details.
    """
    import json
    import os

    import requests

    api_key = os.environ.get("TODOIST_API_KEY")
    if not api_key:
        return "Error: TODOIST_API_KEY not set"

    payload = {"content": content}
    if description:
        payload["description"] = description
    if project_id:
        payload["project_id"] = project_id
    if due_string:
        payload["due_string"] = due_string
    if priority:
        payload["priority"] = 5 - priority
    if labels:
        payload["labels"] = [l.strip() for l in labels.split(",")]

    response = requests.post(
        "https://api.todoist.com/rest/v2/tasks",
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        },
        json=payload,
    )

    if not response.ok:
        return f"Error creating task: {response.text}"

    result = response.json()
    due = result.get("due")
    return json.dumps(
        {
            "success": True,
            "task_id": result["id"],
            "content": result["content"],
            "due": due.get("string") if due else None,
            "is_recurring": due.get("is_recurring", False) if due else False,
            "url": result.get("url"),
        },
        indent=2,
    )


def update_todoist_task(
    task_id: str,
    content: str = None,
    description: str = None,
    due_string: str = None,
    priority: int = None,
    labels: str = None,
) -> str:
    """
    Update an existing task in Todoist.

    Args:
        task_id (str): The ID of the task to update. Required.
        content (str): Optional new task title/content.
        description (str): Optional new description.
        due_string (str): Optional new natural language due date. Supports recurring (e.g., "tomorrow", "every day at 10am").
        priority (int): Optional new priority P1-P4 where P1=urgent, P4=normal. Pass 1, 2, 3, or 4.
        labels (str): Optional comma-separated list of label names to replace existing labels.

    Returns:
        str: Confirmation message with updated task details.
    """
    import json
    import os

    import requests

    api_key = os.environ.get("TODOIST_API_KEY")
    if not api_key:
        return "Error: TODOIST_API_KEY not set"

    payload = {}
    if content:
        payload["content"] = content
    if description is not None:
        payload["description"] = description
    if due_string:
        payload["due_string"] = due_string
    if priority:
        payload["priority"] = 5 - priority
    if labels is not None:
        payload["labels"] = [l.strip() for l in labels.split(",")] if labels else []

    if not payload:
        return "Error: No fields provided to update"

    response = requests.post(
        f"https://api.todoist.com/rest/v2/tasks/{task_id}",
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        },
        json=payload,
    )

    if not response.ok:
        return f"Error updating task: {response.text}"

    result = response.json()
    due = result.get("due")
    return json.dumps(
        {
            "success": True,
            "task_id": task_id,
            "content": result["content"],
            "due": due.get("string") if due else None,
            "is_recurring": due.get("is_recurring", False) if due else False,
        },
        indent=2,
    )


def complete_todoist_task(task_id: str) -> str:
    """
    Mark a task as complete in Todoist.

    Args:
        task_id (str): The ID of the task to complete. Required.

    Returns:
        str: Confirmation message indicating success or failure.
    """
    import json
    import os

    import requests

    api_key = os.environ.get("TODOIST_API_KEY")
    if not api_key:
        return "Error: TODOIST_API_KEY not set"

    response = requests.post(
        f"https://api.todoist.com/rest/v2/tasks/{task_id}/close",
        headers={"Authorization": f"Bearer {api_key}"},
    )

    if response.status_code != 204:
        return f"Error completing task: {response.text}"

    return json.dumps({"success": True, "task_id": task_id, "status": "completed"})


def delete_todoist_task(task_id: str) -> str:
    """
    Permanently delete a task from Todoist.

    Args:
        task_id (str): The ID of the task to delete. Required.

    Returns:
        str: Confirmation message indicating success or failure.
    """
    import json
    import os

    import requests

    api_key = os.environ.get("TODOIST_API_KEY")
    if not api_key:
        return "Error: TODOIST_API_KEY not set"

    response = requests.delete(
        f"https://api.todoist.com/rest/v2/tasks/{task_id}",
        headers={"Authorization": f"Bearer {api_key}"},
    )

    if response.status_code != 204:
        return f"Error deleting task: {response.text}"

    return json.dumps({"success": True, "task_id": task_id, "status": "deleted"})


def main():
    try:
        with open(LETTA_PASSWORD_FILE) as f:
            password = f.read().strip()
    except FileNotFoundError:
        print(f"Error: Password file not found at {LETTA_PASSWORD_FILE}")
        return

    client = Letta(base_url=LETTA_BASE_URL, api_key=password)

    tools = [
        list_todoist_projects,
        list_todoist_tasks,
        add_todoist_task,
        update_todoist_task,
        complete_todoist_task,
        delete_todoist_task,
    ]

    print(f"Connecting to Letta at {LETTA_BASE_URL}...")

    for func in tools:
        tool = client.tools.upsert_from_function(func=func)
        print(f"Registered tool: {tool.name} (id: {tool.id})")

    print("\nAll tools registered successfully!")
    print("\nNext steps:")
    print("1. Go to Letta ADE and edit your agent")
    print("2. Add these tools to your agent")
    print("3. Set TODOIST_API_KEY in agent secrets")
    print("   (Get your API token from: https://app.todoist.com/app/settings/integrations/developer)")


if __name__ == "__main__":
    main()
