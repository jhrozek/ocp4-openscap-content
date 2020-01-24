## ocp4-openscap-content

This repository contains a Dockerfile and some associated scripts that
build the OpenSCAP content for OCP4. It is not intended to be used on
its own, but rather by the [compliance operator](https://github.com/jhrozek/compliance-operator).

The point of having this container image building the content rather
than using the RHEL RPM is two-fold:
 * We can build the image with the content on a different schedule
 * By having the container image with the content separate from the
   scanner image, it gets easier to supply custom content for the scanner
   just by providing a custom image.

## Where does the content come from?
By default, the Dockerfile fetches content from the master branch of the
[upstream repository](https://github.com/ComplianceAsCode/content).
If you want to build content from another repo or branch, just adjust the
`CONTENT_REPO` and `CONTENT_BRANCH` environment variables respectively during
container build, e.g.:
```
make build-nocache CONTENT_REPO=https://github.com/jhrozek/content CONTENT_BRANCH=remediation_demo TAG=test-tag
```

## Wait, why build-nocache?
Docker optimizes the build by using layers. At the moment, the Dockerfile we
use clones the content repo, but even if the clone content is different,
docker treats the clone as being the same layer as a previous clone. Maybe
that's a bug in how I use Dockerfile, if yes, please submit a bug report
or better a PR.

## Where is the built content stored?
Directly in `/`

## Does the image need anything else than the content?
The compliance operator uses `cp` to copy all XML files from the root, but
that's it. This means that if you want to provide your own custom content,
all you need to do is have an image with the XML content files at `/`.

The compliance operator then uses an init container in the scanner pod,
this init container copies the files to a volume from which the openscap
container in the scanner pod uses the content.

## Walk me through building my own content, please
Sure, follow the steps below. There are two ways you can build your content
image, both represented by a set of make targets. Either you can let the
build scaffolding do the whole build and push to a public container registry
or alternatively you can build the content locally yourself and then just
put the resulting XML artifact into a container image which you'd push to
the cluster yourself.

The former is probably what you'd use in a build system or a CI, the latter
is handy for quick development. Let's start with the first approach.

### Set up a container hub hosting
You'll want to push your content image somewhere. Set up a container image
space at dockerhub, quay.io or whatever place you prefer.

### Make changes to the content
Start by forking the 
[upstream repository](https://github.com/ComplianceAsCode/content)
and cloning your fork. Make your changes to the content there and
push the changes to your fork. This README shouldn't go to the details
of writing OpenSCAP content, but there is a [developer guide on github](https://github.com/ComplianceAsCode/content/blob/master/docs/manual/developer_guide.adoc)
Once you have the content available, push your changes to the fork.

### Build the content image
Use the `make build-nocache` target to buld the image, passing the
URL and branch name of your fork as make parameters. Considering
I've cloned the content to a repo based at `https://github.com/jhrozek/content`
in a branch called `remediation_demo`, I would call:
```
make build-nocache CONTENT_REPO=https://github.com/jhrozek/content CONTENT_BRANCH=remediation_demo TAG=test-tag
```

If you don't provide `CONTENT_REPO`, the upstream ComplianceAsContent repo
would be used. If you don't provide the `CONTENT_BRANCH` variable, the
branch you are at *in this content container repo* would be used. You can
also optionally provide a tag, the `TAG` variable defaults to `latest`
if not set explicitly.

The build first installs all the needed build dependencies into a build
container, builds the content there, runs tests, then copies the built
content into the content container which is based on `ubi8` in order to
have a small footprint.

You'll end up with a container called `localhost/ocp4-openscap-content`
tagged `latest`.

### Tag the content image
Unless you tagged the image during build with the `TAG` variable,
you'll probably want to tag the image with something distinguishable.
Use the `tag`, `tag-latest` or `tag-branch` Makefile targets. All of
them use the `REPO` variable which should point to the container hub
that hosts your container, in my case that would be `quay.io/jhrozek`.

To use a custom tag, use the `tag` target:
```
$ make tag REPO=quay.io/jhrozek TAG=test-tag
$ podman images | head -n3
REPOSITORY                                                                               TAG                 IMAGE ID       CREATED         SIZE
localhost/ocp4-openscap-content                                                          latest              ff27fad1b5dc   7 minutes ago   113 MB
quay.io/jhrozek/ocp4-openscap-content                                                    test-tag            ff27fad1b5dc   7 minutes ago   113 MB
```

The `tag-latest` branch defaults the TAG variable to `latest` and
the `tag-branch` target defaults the TAG variable to the git branch
you're at.

### Push the content image
In order to use the content image, it needs to be available from
a hub you set up earlier. Push the image to the hub using either
`make push`, `make push-latest` or `make push-branch`. These targets
use the same `REPO` and `TAG` variables as the `tag-*` branchs.

### Use the content image in a ComplianceSuite or ComplianceScan
The `ComplianceSuite` and `ComplianceScan` CR can point to your
scan image using the `contentImage` attribute. A full example
follows:
```
apiVersion: complianceoperator.compliance.openshift.io/v1alpha1
kind: ComplianceSuite
metadata:
  name: example-compliancesuite
spec:
  autoApplyRemediations: true
  scans:
      - name: workers-scan
        profile: xccdf_org.ssgproject.content_profile_coreos-ncp
        content: ssg-ocp4-ds.xml
        contentImage: quay.io/jhrozek/ocp4-openscap-content:remediation_demo
        nodeSelector:
            node-role.kubernetes.io/worker: ""
      - name: masters-scan
        profile: xccdf_org.ssgproject.content_profile_coreos-ncp
        content: ssg-ocp4-ds.xml
        contentImage: quay.io/jhrozek/ocp4-openscap-content:remediation_demo
        nodeSelector:
            node-role.kubernetes.io/master: ""
```

## This all too complex and takes too long.
The Makefile targets are supposed to deliver the content in a manner
close to production. For example, much of the container build time is
spent running tests. If you're a developer and know what you're doing,
you might want to shorten the loop as soon as possible to make sure you
can iterate on the content quickly.

The fastest way to iterate on the content is to build your own content
locally, skipping the tests and then push the resulting image straight to
the cluster. The following sections tell you how.

## Setup the development environment
You'll want to install all the build dependencies required to build
the content. You can refer to the Dockerfile in this repo and just
run the yum/dnf commands yourself.

## Build the content
Make changes to the content and then configure the project:
```
pushd build
cmake ..
popd
```
You only need to configure the project once. After each change, build
the content with:
```
./build_product ocp4
```
The content is then placed in a file called `build/ssg-ocp4-ds.xml`.

## Build the image
Use the `make build-dev` command and point it to your build content:
```
make build-dev CONTENT_PATH=/home/jhrozek/devel/compliance-as-code-content/build/ssg-ocp4-ds.xml TAG=test-tag
```
This will just copy the content to a `ubi8` based container which takes
just a moment.

## Tag the image
Please refer to the paragraph above about the different tag options.

## Push the image to your cluster
Instead of pushing the image to a public container image hub, we'll be pushing
the image to our cluster. So naturally, the prerequisite is to actually have
one, you should also make sure you're logged in with `oc login`.

Once you've done that, just call a make target:
```
make image-to-cluster FROM=quay.io/repository/jhrozek/openscap-ocp:test-tag TO=ocp4-openscap-content:test-tag
```
The semantic of the variables is the same as earlier. Under the hood, the
make target would open up a route to the container registry and push the
local image `$(FROM)` to the container registry as `$(TO)`. You can then
access the image in the CRs at
`image-registry.openshift-image-registry.svc:5000/openshift-compliance/$(TO)`,
for example:
```
contentImage: image-registry.openshift-image-registry.svc:5000/openshift-compliance/ocp4-openscap-content:test-tag
```
