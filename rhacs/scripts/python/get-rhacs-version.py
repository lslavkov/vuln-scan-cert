"""Retrieve the RHACS Central version via the /v1/metadata API endpoint."""

import os
import sys

import requests

ROX_ENDPOINT = os.getenv("ROX_ENDPOINT")
ROX_API_TOKEN = os.getenv("ROX_API_TOKEN")
STEP_RESULT_PATH = os.getenv("STEP_RESULT_PATH")

headers = {"Authorization": f"Bearer {ROX_API_TOKEN}"}

response = requests.get(f"{ROX_ENDPOINT}/v1/metadata", headers=headers)

if response.status_code != 200:
    print(f"Failed to retrieve RHACS metadata: {response.status_code}")
    print(response.text)
    sys.exit(1)

metadata = response.json()
version = metadata.get("version", "")

if not version:
    print("ERROR: version field missing from /v1/metadata response")
    sys.exit(1)

print(f"RHACS Central version: {version}")

if STEP_RESULT_PATH:
    with open(STEP_RESULT_PATH, "w") as f:
        f.write(version)
