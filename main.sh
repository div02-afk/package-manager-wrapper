#!/bin/bash
# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    use_brew=false
else
    use_brew=true
fi

# Check if apt is installed
if ! command -v apt &> /dev/null; then
    use_apt=false
else
    use_apt=true
fi
# Exit if neither Homebrew nor apt is available
if [ "$use_brew" = false ] && [ "$use_apt" = false ]; then
    echo "Neither Homebrew nor apt is available. Exiting."
    exit 1
fi
# Create package index file if it doesn't exist
FILENAME="/usr/package_index.txt"
if [ ! -e "$FILENAME" ]; then
    touch "$FILENAME"
fi

function brew_install(){
    if [ "$use_brew" = true ]; then
        if brew install "$1"; then
            add_package "$1" "brew"
        else
            echo "Failed to install $1 with Homebrew."
        fi
    else
        return 1
    fi
}

function apt_install(){
    if [ "$use_apt" = true ]; then
        if sudo apt install -y "$1"; then
            add_package "$package" "apt"
            return 0
        else
            echo "Failed to install $1 with apt. Searching for package..."
            sudo apt search "$1" | head -n 20
        fi
        return 1
    else
        return 1
    fi
}

function brew_remove(){
    if [ "$use_brew" = true ]; then
        if brew uninstall "$1"; then
            remove_package "$package"
            return 0
        fi
    else
        return 1
    fi
}

function apt_remove(){
    if [ "$use_apt" = true ]; then
        if  sudo apt remove "$1"; then
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

function add_package() {
    local package_name=$1
    local package_manager=$2
    echo "$package_name : $package_manager" >> "$FILENAME"
    echo "Added $package_name with $package_manager."
}

function remove_package() {
    local package_name=$1
    if grep -q "^$package_name :" "$FILENAME"; then
        # handle macos and linux sed differently
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "/^$package_name :/d" "$FILENAME"
        else
            sed -i "/^$package_name :/d" "$FILENAME"
        fi
        echo "Package $package_name removed."
    else
        echo "Package $package_name not found."
    fi
}

function search_package() {
    local package_name=$1
    local result
    result=$(grep "^$package_name :" "$FILENAME")
    if [ -n "$result" ]; then
        local package_manager
        package_manager=$(echo "$result" | cut -d ':' -f 2 | xargs)
        echo "$package_manager"
    else
        echo ""
    fi
}

command=$1
shift
packages=("$@")

case "$command" in
    install)
        echo "Packages to install: ${packages[@]}"
        for package in "${packages[@]}"; do
            package_manager=$(search_package "$package")
            # echo "Package manager: $package_manager"
            case "$package_manager" in
                brew)
                    echo "Package already installed with Homebrew."
                    continue
                ;;
                apt)
                    echo "Package already installed with apt."
                    continue
                ;;
            esac
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
    ;;
    remove)
        for package in "${packages[@]}"; do
            package_manager=$(search_package "$package")
            # echo "Package manager: $package_manager"
            case "$package_manager" in
                brew)
                    echo "Removing $package with Homebrew..."
                    brew_remove "$package"
                ;;
                apt)
                    echo "Removing $package with apt..."
                    apt_remove "$package"
                ;;
                *)
                    echo "Package $package not found."
                ;;
            esac
        done
    ;;
    update)
        update
    ;;
    reindex)
        rm "$FILENAME"
        touch "$FILENAME"
        brew_packages=($(brew list))
        apt_packages=($(apt list --installed | awk -F/ '{print $1}'))
        apt_packages=("${apt_packages[@]:1}")
        total_packages_len=$(( ${#brew_packages[@]} + ${#apt_packages[@]} ))
        # reindex packages in parallel for faster execution
        (
            for package in "${brew_packages[@]}"; do
                add_package "$package" "brew"
            done
        ) &
        (
            for package in "${apt_packages[@]}"; do
                add_package "$package" "apt"
            done
        ) &
        wait
        echo "Reindexed $total_packages_len packages."
    ;;
    search)
        search_package "${packages[0]}"
    ;;
    list)
        cat "$FILENAME"
    ;;
    *)
        echo "Unknown command: $command"
        exit 1
    ;;
esac