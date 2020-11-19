Release Howto for pmd-build
============================

Step by step
-------------
1. Checkout master branch:

``` shell
git clone https://github.com/pmd/build-tools.git
cd build-tools
```

2. Prepare the release (creates a new release tag).
   This will be done for you: http://maven.apache.org/plugins/maven-release-plugin/examples/prepare-release.html
   Maven will ask you about the release version, the tag name and the new version. You can simply hit enter,
   to use the default values.

``` shell
./mvnw release:clean
./mvnw release:prepare
```

3.  Wait, until release is ready. The maven plugin will directly push the tag. The tag will be
    built by [Github Actions](https://github.com/pmd/build-tools/actions?query=workflow%3Abuild).
    After it is done, the new release
    should be available under <https://repo.maven.apache.org/maven2/net/sourceforge/pmd/pmd-build-tools-config/>.

