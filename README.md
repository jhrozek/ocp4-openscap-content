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
`repo` and `branch` arguments respectively during container build, e.g.
by passing `--build-arg`.

## Where is the content stored?
Directly in `/`

## Does the image need anything else than the content?
The compliance operator uses `cp` to copy all XML files from the root, but
that's it.
