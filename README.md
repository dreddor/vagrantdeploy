## Deploy a dev environment using Vagrant

Steps to deploy:

```bash
cp userconfig.yaml.example userconfig.yaml
vi userconfig.yaml # edit usersettings
vagrant up
```

`vagrant up` will provision a system user and run the deploy command desegnated
in the usersettings.yaml. By default it will download and execute the system
configuration using this repo:

https://github.com/dreddor/envsetup

