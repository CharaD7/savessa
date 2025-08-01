#!/bin/bash

# Script to fix Flutter debug connection issues
# This script tries several approaches to resolve the issue with the Dart compiler exiting unexpectedly

echo "Starting Flutter debug connection fix script..."

# Step 1: Clean the project
echo "Step 1: Cleaning the project..."
flutter clean
if [ $? -ne 0 ]; then
    echo "Error: Flutter clean failed. Please check the error message above."
    exit 1
fi
echo "Flutter clean completed successfully."

# Step 2: Get dependencies
echo "Step 2: Getting dependencies..."
flutter pub get
if [ $? -ne 0 ]; then
    echo "Error: Flutter pub get failed. Please check the error message above."
    exit 1
fi
echo "Dependencies retrieved successfully."

# Step 3: Try running with Impeller disabled
echo "Step 3: Running the app with Impeller disabled..."
echo "If the app starts successfully, you can use this command for future runs:"
echo "flutter run --no-enable-impeller"
flutter run --no-enable-impeller

# If the above command fails, try with a specific VM service port
if [ $? -ne 0 ]; then
    echo "Running with Impeller disabled failed. Trying with a specific VM service port..."
    echo "If the app starts successfully, you can use this command for future runs:"
    echo "flutter run --no-enable-impeller --device-vmservice-port=12345"
    flutter run --no-enable-impeller --device-vmservice-port=12345
fi

# If the above command fails, try with additional debug flags
if [ $? -ne 0 ]; then
    echo "Running with a specific VM service port failed. Trying with additional debug flags..."
    echo "If the app starts successfully, you can use this command for future runs:"
    echo "flutter run --no-enable-impeller --verbose --no-track-widget-creation"
    flutter run --no-enable-impeller --verbose --no-track-widget-creation
fi

# If all the above commands fail, provide additional troubleshooting steps
if [ $? -ne 0 ]; then
    echo "All automatic fixes failed. Please try the following manual steps:"
    echo "1. Restart your computer to clear any lingering processes"
    echo "2. Check if any firewall or antivirus software is blocking Flutter's debug connection"
    echo "3. Try running 'flutter doctor -v' to check for any issues with your Flutter installation"
    echo "4. Try running the app on a different device or emulator"
    echo "5. Try running 'flutter config --no-analytics' to disable analytics, which might help with connection issues"
    echo "6. If you're using an emulator, try restarting it"
    echo "7. If you're using a physical device, try disconnecting and reconnecting it"
    echo "8. Try creating a .env file with environment variables to configure Flutter:"
    echo "   export FLUTTER_IMPELLER_ENABLE=0"
    echo "   # Then source this file before running Flutter: source .env && flutter run"
fi

echo "Script completed."