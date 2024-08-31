#!/bin/bash

# Description:
# This shell script can be used to list, start, stop, and terminate EC2 instances.
#
# Pre-requisites:
# 1. This will require AWS access key and secret access key
# 2. You must have aws cli installed. Verify by running `aws --version`

# Check if AWS credentials are available
if [ -d ~/.aws ]; then
    # Get a list of available AWS profiles
    profiles=$(aws configure list-profiles --output text)

    if [ -z "$profiles" ]; then
        echo "No AWS profiles found."
        read -r -p "Do you want to configure a new profile? (y/n) " choice
        choice=$(echo "$choice" | tr '[:upper:]' '[:lower:]' | xargs)

        if [ "$choice" == "y" ] || [ "$choice" == "yes" ]; then
            aws configure
        else
            echo "Cannot proceed without AWS credentials."
            exit 1
        fi
    else
        # Sort profiles alphabetically
        sorted_profiles=$(echo "$profiles" | sort)

        # Check if "default" profile is present
        default_present=$(echo "$sorted_profiles" | grep -w "default")

        # Create a new list without "default"
        if [ -n "$default_present" ]; then
            new_list=$(echo "$sorted_profiles" | sed '/default/d')
        else
            new_list="$sorted_profiles"
        fi

        # Create the new final list and
        # add "default" as a first element if default was present
        final_list=()
        if [ -n "$default_present" ]; then
            final_list+=("default")
        fi

        # Add the new_list elements to the final_list
        for profile in $new_list; do
            final_list+=("$profile")
        done

        # Create an array with the sorted profiles
        sorted_profiles_array=("${final_list[@]}")

        echo "Available AWS profiles:"
        counter=1
        for profile in "${sorted_profiles_array[@]}"; do
            echo "$counter. $profile"
            counter=$((counter + 1))
        done

        read -r -p "Enter the number corresponding to the profile you want to use: " profile_number

        # Check if the selected number is valid
        if [ "$profile_number" -ge 1 ] && [ "$profile_number" -le "${#sorted_profiles_array[@]}" ]; then
            # Get the selected profile name from the array
            selected_profile="${sorted_profiles_array[$((profile_number - 1))]}"

            # Set the selected profile
            export AWS_PROFILE="$selected_profile"
        else
            echo "Invalid profile number selected."
        fi
    fi
else
    echo "AWS configuration directory not found."
    read -r -p "Do you want to configure AWS credentials? (y/n) " choice
    choice=$(echo "$choice" | tr '[:upper:]' '[:lower:]' | xargs)

    if [ "$choice" == "y" ] || [ "$choice" == "yes" ]; then
        # Check if AWS CLI is installed
        if ! command -v aws &> /dev/null; then
            echo "AWS CLI is not installed. Please install it first."
            echo "You can download it from: https://aws.amazon.com/cli/"
            exit 1
        fi

        aws configure
    else
        echo "Cannot proceed without AWS credentials."
        exit 1
    fi
fi

# Function to display a dot loader
show_loader() {
    local pid=$!
    local delay=0.5
    local spinner='/-\|'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinner#?}
        printf " [%c]  " "$spinner"
        spinner=$temp${spinner%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Function to list all EC2 instances
list_instances() {
    # shellcheck disable=SC2016
    aws ec2 describe-instances --query 'Reservations[*].Instances[*].[Tags[?Key==`Name`].Value|[0],InstanceId,InstanceType,State.Name,PublicIpAddress]' --output table & show_loader
}

# Function to start an EC2 instance
start_instance() {
    read -r -p "Enter the instance ID: " instance_id
    aws ec2 start-instances --instance-ids "$instance_id"
    echo "Starting instance $instance_id..."
}

# Function to stop an EC2 instance
stop_instance() {
    read -r -p "Enter the instance ID: " instance_id
    aws ec2 stop-instances --instance-ids "$instance_id"
    echo "Stopping instance $instance_id..."
}

# Function to terminate an EC2 instance
terminate_instance() {
    read -r -p "Enter the instance ID: " instance_id
    aws ec2 terminate-instances --instance-ids "$instance_id"
    echo "Terminating instance $instance_id..."
}

# Clear screen
clear

# Loop until a valid choice is made
while true; do
    # Display menu options
    echo "AWS EC2 Management Script"
    echo "1. List instances"
    echo "2. Start instance"
    echo "3. Stop instance"
    echo "4. Terminate instance"
    echo "5. Exit"

    # Read user choice
    read -r -p "Enter your choice (1-5): " choice

    # Clear screen
    clear

    # Execute the selected option
    case "$choice" in
        1) list_instances ;;
        2) start_instance ;;
        3) stop_instance ;;
        4) terminate_instance ;;
        5) exit ;;
        *) echo "Invalid choice. Please try again." ;;
    esac

    echo -e "\n"

    # Ask if the user wants to continue
    read -r -p "Do you want to continue with other choices? (y/n) " continue
    if [ "$continue" != "y" ]; then
        break
    fi
done