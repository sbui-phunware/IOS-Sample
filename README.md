# Experiment: HapticBeats

Can we create a cool experience by combining haptic feedback with the beats of a song?

## Requirements

- Xcode 8.3
- iOS 10.1+
- Any iPhone with a vibration motor (although 7 is preferred, and 6s is better than older)

## How it works

Currently it's actually pretty simple in how it works. It just checks the peak sound output for all the channels and compares it to the last check. If there was a huge spike, it plays a haptic feedback (which can be hard or soft, depending on intensity of spike). This would be fine for music that is just all beats, but music with other sounds (vocals, high-pitched instruments) tend to get in the way of this.

Only support songs that are not from Apple Music, have no DRM, and are downloaded on the device. Next development is to meter the output of other Music app.



