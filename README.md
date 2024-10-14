
# Chat and Video Call Application
This repository demonstrates the functionality of a chat and video call application built using Flutter with Node.js and Socket.IO for the backend. The app supports features like real-time messaging, multimedia sharing, video calls, and user management, making it suitable for both one-to-one and group interactions.

![video](/media/chat_app.gif)

# Description

* **Login Screen**: Users can log in using a valid mobile number and OTP. Once verified, registered users are redirected to the friend list screen, while new users are prompted to complete the registration.

* **Registration Screen**: Users can enter personal information like First Name, Last Name, Email, and Profile Image. Upon registration, users are redirected to the friend list screen.

* **Friend List Screen**: This screen displays a list of friends. Users can:

    * Send a friend request to new contacts.
    * View and update their profile.
    * Select friends to start a chat or initiate a one-to-one video call.

* **Chat Screen**: Users can engage in text chats (both one-to-one and group) that include:

    * Sending text, images, videos, and audio messages.
    * Sharing live locations.
    * Initiating a one-to-one video call using WebRTC.

* **Friend Request Functionality**: Users can send and manage friend requests, view pending requests, and accept or decline them.

* **Profile Management**: Users can update their profile information, including profile picture, username, and status.

# Table of Contents

* **Login UI**: Validates phone number, verifies OTP, and redirects to the friend list.
* **Registration UI**: Collects user data and redirects to the friend list.
* **Friend List UI**: Displays the list of friends, initiates video calls, sends friend requests, and logs out.
* **Chat UI**: Displays one-to-one and group conversations, sends multimedia messages, and initiates video calls.

# Technical Details

* **Project Architecture**: MVVM (Model-View-ViewModel)
* **Project Language**: Flutter (Dart)
* **Backend**: Node.js and Socket.IO for real-time messaging
* **Video Call**: WebRTC for one-to-one video calls
* **Database**: Mysql
* **Minimum SDK Version (iOS)**: 12.0
* **Minimum SDK Version (Android)**: 23

# Features

* **Text Chat**: Supports one-to-one and group chats with text, images, videos, audio messages, and live location sharing using Socket.IO.
* **Video Call**: One-to-one video calls powered by WebRTC.
* **Phone Number Authentication**: Login with OTP verification.
* **Friend Requests**: Send and manage friend requests.
* **Profile Management**: Update profile picture, username, and more.

# UI Components

* **Flutter Widgets**:
    * ListView
    * Image
    * Toast
    * TextField
    * Buttons