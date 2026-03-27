# FL Studio Discord Rich Presence

Automatically shows your FL Studio activity in Discord - project name, FL version, and how long you've been in the session.

## Requirements

- Windows 10 / 11
- Python 3.8+
- Discord desktop app
- FL Studio (any version)

---

## Installation

### 1. Install Python dependencies

```
pip install pypresence psutil pywin32
```

### 2. Create a Discord Application

1. Go to [discord.com/developers/applications] (https://discord.com/developers/applications)
2. Click **New Application** and name it **FL Studio**
3. Copy the **Application ID** from the General Information page
4. Go to **Rich Presence → Art Assets** and upload:
   - An FL Studio logo image => name it **`fl_logo`**
   - *(Optional)* A music note icon => name it **`note`**

### 3. Add your Client ID to the script

Open `fl_rpc.py` and replace:

```python
CLIENT_ID = "YOUR_CLIENT_ID_HERE"
```

with your Application ID, e.g.:

```python
CLIENT_ID = "123456789012345678"
```

### 4. Run setup (once, as Administrator)

Right-click `RUN_SETUP.bat` => **Run with PowerShell (as Administrator)**

Restart your computer afterwards.

From now on, the presence launches automatically the moment FL Studio opens.

---

## File overview

```
fl_rpc.py           - Main script
RUN_SETUP.bat       - One-time setup
RUN_UNINSTALL.bat   - Instant uninstall
```

---

## Uninstalling

Right-click `RUN_UNINSTALL.bat` => **Run with PowerShell (as Administrator)**

---
