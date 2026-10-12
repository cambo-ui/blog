---
title: "Generate SSH Key Pair Access to Google Cloud"
date: 2025-09-29
description: "Step #1: Generate Your SSH Key Pair Use the ssh-keygen command to create a new key pair. Replace [KEY_FILENAME] with a descriptive name and [USERNAME] with t..."

---

## Step #1: Generate Your SSH Key Pair

Use the ssh-keygen command to create a new key pair. Replace `[KEY_FILENAME]` with a descriptive name and `[USERNAME]` with the desired login user (usually your Linux username).

```
ssh-keygen -t rsa -f ~/.ssh/[KEY_FILENAME] -C [USERNAME]
```

Example:

```
ssh-keygen -t rsa -f ~/.ssh/ssh-key-pair -C ologucci888
```

## Step #2: Navigate to the Key Directory

Change directory to your local `.ssh` folder where the new keys were created.

```
cd ~/.ssh
```

## Step #3: Restrict Private Key Permissions

For security, the private key file must have restrictive permissions, allowing only the owner to read it.

```
chmod 400 [KEY_FILENAME]
```

Example:

```
chmod 400 ssh-key-pair
```

## Step #4: Display the Public Key

View the content of the public key (the file ending in `.pub`). You will need to copy this entire output.

```
cat [KEY_FILENAME].pub
```

Example:

```
cat ssh-key-pair.pub
```

## Step #5: Upload Public Key to Google Cloud Metadata

Log into your Google Cloud console and paste the entire output from the previous step into the SSH Keys section of the Compute Engine Metadata.

Metadata Link: <https://console.cloud.google.com/compute/metadata?project=n8n-train-468804&scopeTab=projectMetadata&resourceTab=sshkeys>

## Final Step: Connect to Your VM Instance

Once the key is saved in the metadata, you can connect from your local machine using the private key (`-i` flag), your user ID, and the external IP address.

```
ssh -i YOUR_PRIVATE_KEY YOUR_USER@YOUR_EXTERNAL_IP
```

Example:

```
ssh -i ssh-key-pair ologucci888@34.169.59.15
```
