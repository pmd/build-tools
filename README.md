[![Build Snapshot](https://github.com/pmd/build-tools/actions/workflows/build-snapshot.yml/badge.svg)](https://github.com/pmd/build-tools/actions/workflows/build-snapshot.yml)

# PMD build tools

Artifact containing configuration data and various infos to build pmd/pmd from source.

**Note:** This project does not use semantic versioning.

-----
*   [Configuration](#configuration)
    *   [IDE Configs](#ide-configs)
    *   [Checkstyle Configs](#checkstyle-configs)
    *   [PMD Configs](#pmd-configs)
*   [Miscellaneous](#miscellaneous)
    *   [Nexus Staging Maven Plugin](#nexus-staging-maven-plugin)
    *   [Remote debugging](#remote-debugging)
    *   [Intermittent connection resets or timeouts while downloading dependencies from maven central](#intermittent-connection-resets-or-timeouts-while-downloading-dependencies-from-maven-central)

-----

## Configuration

### IDE Configs
* [intellij-idea](https://github.com/pmd/build-tools/tree/main/intellij-idea):
  * code formatter
* [eclipse](https://github.com/pmd/build-tools/tree/main/eclipse)
  * code formatter
  * code cleanup
  * code templates
* [netbeans](https://github.com/pmd/build-tools/tree/main/netbeans)
  * code formatter

### Checkstyle Configs
* [pmd-checkstyle-config.xml](https://github.com/pmd/build-tools/blob/main/src/main/resources/net/sourceforge/pmd/pmd-checkstyle-config.xml)

### PMD Configs
* [pmd-dogfood-config.xml](https://github.com/pmd/build-tools/blob/main/src/main/resources/net/sourceforge/pmd/pmd-dogfood-config.xml)

## Miscellaneous

### Release Signing Keys

#### Creating a new key
In general, a key created once should be reused. However, if the key is (potentially) compromised, a new
key needs to be generated. A gpg key consists of a master key and one or more subkeys. The master key
defines the identity (fingerpringt, key ID) and subkeys can be used for actual signing. The master key is
then only used to create new subkeys or renew subkeys. For a more safe operation, the master key should
be kept offline and only the subkeys should be used for signing. A Release Signing Key also doesn't need
a subkey for encryption. In case a signing key gets compromised, the subkey can be revoked and a new key
can be generated. But the master key still is safe.

Creating such a key is not straightforward, hence this how to (there are a couple of guides
in the internet about best practices):

```
$ gpg --expert --full-generate-key
...
Please select what kind of key you want:
> 8 (RSA (set your own capabilities)
> S (Toggle Sign)
> E (Toggle Encrypt)
> Q
Current allowed actions: Certify
What keysize do you want?
> 4096
Please specify how long the key should be valid.
> 2y
Real name:
> PMD Release Signing Key
Email address:
> releases@pmd-code.org
...
pub   rsa4096 2025-01-04 [C] [expires: 2027-01-04]
      2EFA55D0785C31F956F2F87EA0B5CA1A4E086838
uid                      PMD Release Signing Key <releases@pmd-code.org>
```

Then we create a subkey for signing:
```
$ gpg --edit-key 2EFA55D0785C31F956F2F87EA0B5CA1A4E086838
gpg> addkey
> 4 (RSA (sign only))
keysize:
> 4096
Expiration
> 2y
...
> save
```

Now let's publish the public key:
```
$ gpg --armor --export 2EFA55D0785C31F956F2F87EA0B5CA1A4E086838 | curl -T - https://keys.openpgp.org
Key successfully uploaded. Proceed with verification here:
https://keys.openpgp.org/upload/....
```

Export the key to upload it to <https://keyserver.ubuntu.com/#submitKey>:
`gpg --armor --export 2EFA55D0785C31F956F2F87EA0B5CA1A4E086838 | wl-copy`
Also upload it to <http://pgp.mit.edu/>.

Also export the (public) key into a file and add it to build-tools repo:
```
$ gpg --armor --export 2EFA55D0785C31F956F2F87EA0B5CA1A4E086838 > scripts/files/release-signing-key-2EFA55D0785C31F956F2F87EA0B5CA1A4E086838-public.asc
```

Verify the uploaded key (and expiration date):

```
gpg --show-keys release-signing-key-2EFA55D0785C31F956F2F87EA0B5CA1A4E086838-public.asc
curl 'https://keys.openpgp.org/vks/v1/by-fingerprint/2EFA55D0785C31F956F2F87EA0B5CA1A4E086838' | gpg --show-keys
curl 'https://keyserver.ubuntu.com/pks/lookup?search=0x2EFA55D0785C31F956F2F87EA0B5CA1A4E086838&fingerprint=on&exact=on&options=mr&op=get' | gpg --show-keys
curl 'http://pgp.mit.edu/pks/lookup?op=get&search=0x2EFA55D0785C31F956F2F87EA0B5CA1A4E086838' | gpg --show-keys
```

#### Current Key

* Used since January 2025
* Fingerprint `2EFA 55D0 785C 31F9 56F2  F87E A0B5 CA1A 4E08 6838`
* Used for signing artifacts in Maven Central

```
$ gpg --list-keys --fingerprint 2EFA55D0785C31F956F2F87EA0B5CA1A4E086838
pub   rsa4096 2025-01-04 [C] [expires: 2027-01-04]
      2EFA 55D0 785C 31F9 56F2  F87E A0B5 CA1A 4E08 6838
uid           [ultimate] PMD Release Signing Key <releases@pmd-code.org>
sub   rsa4096 2025-01-04 [S] [expires: 2027-01-04]
```

The public key is available here:
* <https://keys.openpgp.org/search?q=0x2EFA55D0785C31F956F2F87EA0B5CA1A4E086838>
* <https://keyserver.ubuntu.com/pks/lookup?search=0x2EFA55D0785C31F956F2F87EA0B5CA1A4E086838&fingerprint=on&op=index>
* <http://pgp.mit.edu/pks/lookup?search=0x2EFA55D0785C31F956F2F87EA0B5CA1A4E086838&fingerprint=on&op=index>
* <https://github.com/pmd/build-tools/blob/main/release-signing-key-2EFA55D0785C31F956F2F87EA0B5CA1A4E086838-public.asc>


#### Old keys

* Fingerprint `EBB2 41A5 45CB 17C8 7FAC B2EB D0BF 1D73 7C9A 1C22`
  * Used until December 2024
  * Replaced as the passphrase has been compromised and therefore the key is potentially
    compromised. Note - as until now (January 2025) we don't have any indication that the key
    actually has been misused.
  * Revoked 2025-01-04.
  * see file `release-signing-key-D0BF1D737C9A1C22-public.asc`.

* Fingerprint `94A5 2756 9CAF 7A47 AFCA  BDE4 86D3 7ECA 8C2E 4C5B`
  * Old key used to sign PMD Designer
  * Revoked 2025-01-04.

#### Private key

In order for GitHub Action to automatically sign the artifacts for snapshot builds and release builds,
we need to make the private key along with the passphrase available. This is done using
multiple [`secrets`](https://help.github.com/en/actions/configuring-and-managing-workflows/creating-and-storing-encrypted-secrets).
The secrets are configured on the organization level of PMD, so that the Release Signing key is available
for all repositories.

To not expose the master key, we only export the subkeys we use for signing and store this in the secret
`PMD_CI_GPG_PRIVATE_KEY`.

For setting up, export the secret key and copy-paste it into a new secret:

```
gpg --armor --export-secret-subkeys 2EFA55D0785C31F956F2F87EA0B5CA1A4E086838 | wl-copy
```

(instead of wl-copy, use xclip or pbcopy, depending on your os).

This private key will be imported by the script `setup-secrets.bash`.

**Note 1:** We use option `--export-secret-subkeys` to only export the subkey and not the master key.
That way, we don't need to transfer the master key.

**Note 2:** In order to use the key later on, the passphrase is needed. This is also setup as a secret:
`PMD_CI_GPG_PASSPHRASE`. This secret is then exported as "MAVEN_GPG_PASSPHRASE" where needed
(`MAVEN_GPG_PASSPHRASE: ${{ secrets.PMD_CI_GPG_PASSPHRASE }}`) in github actions workflows.
See also <https://maven.apache.org/plugins/maven-gpg-plugin/usage.html#sign-artifacts-with-gnupg>.

**Note 3:** The private key is now only secured by the passphrase. It is stored as a GitHub Actions
secret and available in an environment variable. It is not anymore committed in
this build-tools repository and is therefore not encrypted with another key (e.g. PMD_CI_SECRET_PASSPHRASE). 

#### Updating the key

From time to time the key needs to be renewed, passphrase needs to be changed or a whole (sub)key needs to
be replaced.

For renewing or changing the passphrase, import the private master key and public key into your local gpg keystore
(if you don't have it already in your keyring) and renew it.
Make sure to renew all subkeys. Then export the public key again.

For replacing, generate a new (sub) key, just export it.

You can verify the expiration date with `gpg --fingerprint --list-key 2EFA55D0785C31F956F2F87EA0B5CA1A4E086838`:

```
pub   rsa4096 2025-01-04 [C] [expires: 2027-01-04]
      2EFA 55D0 785C 31F9 56F2  F87E A0B5 CA1A 4E08 6838
uid           [ultimate] PMD Release Signing Key <releases@pmd-code.org>
sub   rsa4096 2025-01-04 [S] [expires: 2027-01-04]

```

Upload the exported *public* key to

* <https://keys.openpgp.org/upload>
* <https://keyserver.ubuntu.com/#submitKey>
* <http://pgp.mit.edu/>

Verify the uploaded key expiration date:

```
gpg --show-keys release-signing-key-2EFA55D0785C31F956F2F87EA0B5CA1A4E086838-public.asc
curl 'https://keys.openpgp.org/vks/v1/by-fingerprint/2EFA55D0785C31F956F2F87EA0B5CA1A4E086838' | gpg --show-keys
curl 'https://keyserver.ubuntu.com/pks/lookup?search=0x2EFA55D0785C31F956F2F87EA0B5CA1A4E086838&fingerprint=on&exact=on&options=mr&op=get' | gpg --show-keys
curl 'http://pgp.mit.edu/pks/lookup?op=get&search=0x2EFA55D0785C31F956F2F87EA0B5CA1A4E086838' | gpg --show-keys
```

Don't forget to update the secret `PMD_CI_GPG_PRIVATE_KEY` with the renewed private signing subkey.

### Remote debugging

Debugging remotely is possible with <https://github.com/mxschmitt/action-tmate>.

Just add the following step into the job:

```
      - name: Setup tmate session
        uses: mxschmitt/action-tmate@v3
```

**Note**: This is dangerous for push/pull builds on repositories of pmd itself, because these have access
to the secrets and the SSH session
is not protected. Builds triggered by pull requests from forked repositories don't have access to the secrets.

See also <https://docs.github.com/en/actions/reference/encrypted-secrets>.

### Intermittent connection resets or timeouts while downloading dependencies from maven central

Root issue seems to be SNAT Configs in Azure, which closes long running [idle TCP connections
after 4 minutes](https://docs.microsoft.com/en-us/azure/load-balancer/troubleshoot-outbound-connection#idletimeout).

The workaround is described in [actions/virtual-environments#1499](https://github.com/actions/virtual-environments/issues/1499)
and [WAGON-545](https://issues.apache.org/jira/browse/WAGON-545)
and [WAGON-486](https://issues.apache.org/jira/browse/WAGON-486):

The setting `-Dmaven.wagon.httpconnectionManager.ttlSeconds=180 -Dmaven.wagon.http.retryHandler.count=3`
makes sure, that Maven doesn't try to use pooled connections that have been unused for more than 180 seconds.
These settings are placed as environment variable `MAVEN_OPTS` in the workflow, so that they are active for
all Maven executions (including builds done by regression tester).

Alternatively, pooling could be disabled completely via `-Dhttp.keepAlive=false -Dmaven.wagon.http.pool=false`.
This has the consequence, that for each dependency, that is being downloaded, a new https connection is
established.

More information about configuring this can be found at [wagon-http](https://maven.apache.org/wagon/wagon-providers/wagon-http/).

**Update: Since [Maven 3.9.0](https://maven.apache.org/docs/3.9.0/release-notes.html)**, the native transport instead of wagon is used:

> The Maven Resolver transport has changed from Wagon to “native HTTP”, see [Resolver Transport guide](https://maven.apache.org/guides/mini/guide-resolver-transport.html).

Therefore, the property to configure the timeouts changed to `-Daether.connector.http.connectionMaxTtl=180`.
Retry count is by default 3 and can be omitted.
See <https://maven.apache.org/resolver/configuration.html> for all available properties.

Note: This system property only works with Maven 3.9.2 or later!

