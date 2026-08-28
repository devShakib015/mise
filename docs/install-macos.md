# Installing Mise on a Mac

## 1. Install it

Open the `.dmg` you downloaded and drag **Mise** onto the Applications folder
next to it. Eject the disk image.

## 2. Open it the first time

macOS will say it *cannot verify the developer*. That is expected — Mise is free
and is not signed with a paid Apple certificate.

**Right-click Mise in Applications → Open → Open.**

You only do this once. After that it opens normally.

> Why: Apple charges $99/year for the certificate that removes this warning.
> Mise is free and self-hosted, so it does not pay it. The warning means
> "unsigned", not "unsafe" — the source is public and you can build it yourself.

## 3. Decide which computer runs the restaurant

One machine holds the menu, the orders and the takings. Everything else joins it.
Pick the one that stays switched on during service — usually the back-office
computer.

On that machine, choose **Run the restaurant on this computer**. Mise starts its
own server and shows you an address like `http://192.168.0.209:8090`.

**Write that address down.** Tablets and the kitchen screen need it.

macOS may ask whether Mise can accept incoming network connections. Say yes —
that is how the tablets reach it.

## 4. Set up the restaurant

The first run walks through three steps: what the place is called, what it
charges, and who owns it. Then you are signed in.

## 5. Add the other devices

On each tablet or kitchen screen, open Mise and type the address from step 3 —
not "run on this computer". They join the machine that is hosting.

Everything must be on the same wi-fi.

## Where your data lives

`~/Library/Application Support/com.devshakib.mise/server/pb_data`

On the host machine only. Nothing is sent anywhere. Updating Mise never touches
it. Back it up by copying that folder while Mise is closed.

## If something is wrong

**The tablets cannot find it.** Check they are on the same wi-fi, and that macOS
is allowing incoming connections for Mise (System Settings → Network → Firewall).

**"The server did not come up in time."** Something else may be using port 8090.
Quit it and reopen Mise.

**You want to start over.** Quit Mise and delete the folder above. The next
launch behaves like a fresh install.
