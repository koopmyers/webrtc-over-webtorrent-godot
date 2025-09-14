# WebRTC over Webtorrent in Godot

This Godot project is a proof of concept for creating and connecting players over the internet with the only requirement to pass a short password between players. It uses WebRTC peer to peer connection without the need to deploy a signaling server, using public WebTorrent Trackers.

It is limited and is not ready for full real use. It is missing basic functionalities for a production project like troubleshooting, proper closing connections and session, timeout…

It is recommended to use multiple trackers as they can be unreliable.

To test it, just run the project in Godot, and create a session with one peer and connect other peers using the session id generated.

# Credits
Theme: https://github.com/passivestar/godot-minimal-theme?tab=readme-ov-file
Icons: https://www.kenney.nl/assets/game-icons