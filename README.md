# Self signed certificates for your Home Lab environment

Today use of Browser SSL certificates becomes a must even for nas, routers and other home lab environment purposes.
With these two scripts you can generate your own self signed root certificate and child certificates for your devices.

## How to use them?
  
From terminal browse to its directory and run first:

```bash
./create_self_signed_root_cert.sh
```

script will ask you to provide:

* CommonName (example Maks-IT)'
* Organization (example Maks-IT)'
* OrganizationalUnit (example Maks-IT Root CA)

at this point your root certificate will be placed in `rootCert` folder and there you find following files:

* ca.crt
* ca.key
* ca.pem

> Keep always them in place to generate child certificates with the next script.

## Install root certificate in Windows

1. Click on `ca.crt` file

2. On general tab click Install Certificate...

![general_tab](/resources/2023-09-10_114033.png)

3. Select Store Location -> Local Machine

![select_store](/resources/2023-09-10_114102.png)

4. Select Place all certificates in the following store radio and click on Browse button

![place_all](/resources/2023-09-10_114114.png)

5. Select Trusted Root Certification Authorities, then OK and Next

![trusted_root_certification_autorities](/resources/2023-09-10_114123.png)

6. Check the summary and Finish

![summary](/resources/2023-09-10_114137.png)

## Install root certificate in Linux (Fedora)

```bash
sudo trust anchor --store ca.pem
sudo trust anchor --remove
sudo update-ca-trust
```

## Generate cert for your device FQDN

From the same terminal window execute:

```bash
./create_self_signed_cert.sh
```

script will ask you to provide:

* Organization (example Maks-IT)
* OrganizationalUnit (example Maks-IT)
* CommonName (example hcrsrv0001.corp.maks-it.com)'

> Note! This time `CommonName` should contain device's complete FQDN
> In this example script will generate cert for 2 DNS records:
> * hcrsrv0001.corp.maks-it.com
> * hcrsrv0001

## Cert files extensions explained

Keys come in two halves, a public key and a private key.
The public key can be distributed publicly and widely, and you can use it to verify,
but not replicate, information generated using the private key. 
The private key must be kept secret.

* .key - are generally the private key, used by the server to encrypt and package data for verification by clients.
* .pem - are generally the public key, used by the client to verify and decrypt data sent by servers. PEM files could also be encoded private keys, so check the content if you're not sure.
* .p12 - have both halves of the key embedded, so that administrators can easily manage halves of keys.
* .cert or .crt - are the signed certificates -- basically the "magic" that allows certain sites to be marked as trustworthy by a third party.
* .csr - is a certificate signing request, a challenge used by a trusted third party to verify the ownership of a keypair without having direct access to the private key (this is what allows end users, who have no direct knowledge of your website, confident that the certificate is valid). In the self-signed scenario you will use the certificate signing request with your own private key to verify your private key (thus self-signed). Depending on your specific application, this might not be needed. (needed for web servers or RPC servers, but not much else).