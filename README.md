# easy_reader

A App to unzip manga archive and show images sorted to user.

# Feature implemented
  - Login with firebase authentication(done)
  - Login with google(done)
  - Edit profile (cloud database)(done)
  - Read zip files and show images sorted(done)
  - Read from URL and unzip and show images sorted(done)
  - Create a asset icon to send to google play(pending)
 
# Futures features
  - Read .rar files(actually native library of dart dont support .rar decode)
  - Read CBZ files(actually native library of dart dont support .CBZ decode)
  - Add chat
  
# Extra information
This URL can be insert inside app to download direct the zip file: 
```
https://drive.google.com/uc?authuser=0&id=1t4xdD9ZXRrqiMzXQK_9uwdBB60Q4eQmy&export=download
```
or you can download this file and select the file from your storage.
  
# What can be better?
  - Brake in more pages
  - Some way accept more types
  - Home screen more clean
  - Create a lib with common components like loading
  - Unit tests
  - Navigator.popUntil(context, ModalRoute.withName(Navigator.defaultRouteName)); - Gives pop until found a "root page"
I did use this in logout button, this way I have sure that when a did a logout a have only root page and nothing can go
upside of my login page, I don't know if this way is the better way.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://flutter.dev/docs/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://flutter.dev/docs/cookbook)

For help getting started with Flutter, view our
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
