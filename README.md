# Manual updater for Signal APK direct download

```
./update.sh
```

This repository is a miserable pile of scripts. Using a de-googled android phone with no app store makes updates difficult, so I slapped this together as a bandaid over the most common papercuts and [RSI](https://en.wikipedia.org/wiki/Repetitive_strain_injury).

The scripts will [TOFU](https://en.wikipedia.org/wiki/Trust_on_first_use) and pin on whatever certs are active in the wild, and report (stop) whenever they encounter a change (such as a SSL certificate rotation or different APK signing key).

Yes, I'm aware that Signal is using Google as their trusted HTTPS CA, and that Googles android tools are needed to use the signer. There's not much I can do about that. @ me on Matrix. 

More in-depth blog coming ~soon~ maybe.
