# Package Management Script

This script is designed to help you install, remove, and manage software packages using `brew` and `apt` package managers. It supports basic operations like installing, removing, and updating packages, as well as searching and reindexing the installed packages.

## Features

- **Install Packages**: Installs a package using either Homebrew or APT.
- **Remove Packages**: Removes a package from your system.
- **Update**: Updates the list of available packages using both Homebrew and APT.
- **Reindex**: Rebuilds the package index file (`/usr/package_index.txt`).
- **Search**: Searches for a package in the package index file to determine its package manager.
- **List**: Displays all installed packages in the package index file.

## Requirements

- **Homebrew**: Must have Homebrew installed for Homebrew package management.
- **APT**: Must have APT (Advanced Package Tool) installed for package management on Debian-based systems (e.g., Ubuntu).

## Installation

Ensure that both `brew` and `apt` are installed on your system. If you don't have them installed, the script will attempt to use only the available package manager.

### Homebrew Installation (if not installed)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### APT Installation (for Debian/Ubuntu-based systems)

```bash
sudo apt update
sudo apt install apt
```

## Usage

### Commands

- **install**: Install a package using either Homebrew or APT.
- **remove**: Remove a package using either Homebrew or APT.
- **update**: Update the package lists for both package managers.
- **reindex**: Rebuild the package index file.
- **search**: Search for a package to determine which package manager is used.
- **list**: Display the list of installed packages in the index file.

### Example Commands

#### Install Packages

```bash
./main.sh install wget python3
```

This will attempt to install `wget` and `python3` using Homebrew first, and if that fails, it will try using APT.

#### Remove Packages

```bash
./main.sh remove wget python3
```

This will attempt to remove `wget` and `python3` using Homebrew first, and if that fails, it will try using APT.

#### Update Package Lists

```bash
./main.sh update
```

This will update both the APT and Homebrew package lists.

#### Reindex Packages

```bash
./main.sh reindex
```

This will rebuild the `/usr/package_index.txt` file with the current package list from both Homebrew and APT.

#### Search Package Manager

```bash
./main.sh search wget
```

This will search the index file to see if `wget` is managed by Homebrew or APT.

#### List Installed Packages

```bash
./main.sh list
```

This will display all the installed packages in the `/usr/package_index.txt` file.

## How It Works

1. **Package Indexing**: When you install or remove a package, the script adds or removes entries from the `package_index.txt` file. Each line contains a package name and the corresponding package manager (e.g., `wget : apt`).

2. **Installation Logic**:
   - If a package is already installed (found in the index file), the script skips installation.
   - If the package is not found in the index file, it first attempts installation with Homebrew. If Homebrew installation fails, it then tries APT.

3. **Reindexing**: The script rebuilds the `package_index.txt` file by listing installed packages from both Homebrew and APT.

## Configuration

- **`FILENAME`**: The package index file is stored at `/usr/package_index.txt`. Ensure you have appropriate permissions to read and write to this file.

## Example Output

- **Install Example**:

  ```bash
  sudo ./main.sh install wget python3
  Packages to install: wget python3
  Package manager: apt
  Package already installed with apt.
  Installing python3 with Homebrew...
  Failed to install python3 with Homebrew. Trying apt...
  python3 installed successfully with apt.
  ```

- **Remove Example**:

  ```bash
  sudo ./main.sh remove wget
  Removing wget with Homebrew...
  Package wget removed.
  ```

## Troubleshooting

- If you encounter permission issues with the `/usr/package_index.txt` file, you may need to change the file's permissions or run the script with `sudo`.
- Ensure both `brew` and `apt` are properly installed and configured on your system.

## License

This script is provided under the MIT License.

---
