#!/bin/bash

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    #   echo "Homebrew is not installed. Skipping Homebrew installation."
    use_brew=false
else
    use_brew=true
fi

# Check if apt-get is installed
if ! command -v apt-get &> /dev/null; then
    #   echo "apt-get is not installed. Skipping apt-get installation."
    use_apt=false
else
    use_apt=true
fi

FILENAME="./package_index.txt"

if [ ! -e "$FILENAME" ]; then
    touch "$FILENAME"
fi

function brew_install(){
    if [ "$use_brew" = true ]; then
        brew install "$1"
        if [ $? -eq 0 ]; then
            add_package "$package" "brew"
            return 0
        fi
    else
        return 1
    fi
}
function apt_install(){
    if [ "$use_apt" = true ]; then
        sudo apt install -y "$1"
        if [ $? -eq 0 ]; then
            add_package "$package" "apt"
            return 0
        else
            echo "Failed to install $1 with apt. Searching for package..."
            sudo apt search "$1"
        fi
        return 1;
    else
        return 1
    fi
}
function brew_remove(){
    if [ "$use_brew" = true ]; then
        brew uninstall "$1"
        if [ $? -eq 0 ]; then
            remove_package "$package"
            return 0
        fi
    else
        return 1
    fi
}

function apt_remove(){
    if [ "$use_apt" = true ]; then
        sudo apt remove "$1"
        if [ $? -eq 0 ]; then
            remove_package "$package"
            return 0
        fi
    else
        return 1
    fi
}
function update(){
    if [ "$use_apt" = true ]; then
        sudo apt update
    fi
    if [ "$use_brew" = true ]; then
        brew update
    fi
}

add_package() {
    local package_name=$1
    local package_manager=$2
    echo "$package_name : $package_manager" >> "$FILENAME"
    echo "Added $package_name with $package_manager."
}
remove_package() {
    local package_name=$1
    if grep -q "^$package_name :" "$FILENAME"; then
        # Delete the line with the matching package name
        sed -i "/^$package_name :/d" "$FILENAME"
        echo "Package $package_name removed."
    else
        echo "Package $package_name not found."
    fi
}
search_package() {
    local package_name=$1
    local result
    result=$(grep "^$package_name :" "$FILENAME")
    if [ -n "$result" ]; then
        # Extract the package manager using 'cut' by splitting at the colon
        local package_manager
        package_manager=$(echo "$result" | cut -d ':' -f 2 | xargs)  # Trim leading/trailing whitespace
        echo "$package_manager"  # Use echo to return the value
    else
        echo ""  # Return an empty string if not found
    fi
}

command=$1
shift
packages=("$@")
if [ "$command" = "install" ]; then
    echo "Packages to install: ${packages[@]}"
    for package in "${packages[@]}"; do
        package_manager=$(search_package "$package_name")
        if [ "$package_manager" = "brew" ]; then
            echo "Package already installed with Homebrew."
            continue
            
            elif [ "$package_manager" = "apt" ]; then
            echo "Package already installed with apt."
            continue
        fi
        echo "Installing $package with Homebrew..."
        brew_install "$package"
        if [ $? -eq 0 ]; then
            echo "$package installed successfully with Homebrew."
        else
            echo "Failed to install $package with Homebrew. Trying apt..."
            apt_install "$package"
            if [ $? -eq 0 ]; then
                echo "$package installed successfully with apt."
            else
                echo "Failed to install $package with both Homebrew and apt."
            fi
        fi
    done
    elif [ "$command" = "remove" ]; then
    for package in "${packages[@]}"; do
        package_manager=$(search_package "$package")
        echo "Package manager: $package_manager"
        if [ "$package_manager" = "brew" ]; then
            echo "Removing $package with Homebrew..."
            brew_remove "$package"
            
            elif [ "$package_manager" = "apt" ]; then
            echo "Removing $package with apt..."
            apt_remove "$package"
            
        else
            echo "Package $package not found."
        fi
    done
    elif [ "$command" = "update" ]; then
    update
    elif [ "$command" = "reindex" ]; then
    rm "$FILENAME"
    touch "$FILENAME"
    brew_packages=($(brew list))
    apt_packages=($(apt list --installed | awk -F/ '{print $1}'))
    
    for package in "${brew_packages[@]}"; do
        add_package "$package" "brew"
    done
    for package in "${apt_packages[@]}"; do
        add_package "$package" "apt"
    done
else
    echo "Unknown command: $command"
    exit 1
fi