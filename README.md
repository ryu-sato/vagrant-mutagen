# Vagrant::Mutagen::Utilizer

This plugin forked from [vagrant-mutagen](https://github.com/dasginganinja/vagrant-mutagen) and made the following modifications.

* Is is not to be elevated to administrative privileges
  * In many cases, the plugin executor has permission of SSH user configuration file
* Organized orchestration related to VM status (Basic ideas is below)
  * Have an entry in the SSH configuration file exist only while the VM is running
  * Running an project of mutagen only while the VM is running


This plugin adds an entry to your `~/.ssh/config` file on the host system.

On **up**, **resume** and **reload** commands, it tries to add the information, if it does not already exist in your config file.
On **halt**, **destroy**, and **suspend**, those entries will be removed again.


## Installation

    $ vagrant plugin install vagrant-mutagen-utilizer

Uninstall it with:

    $ vagrant plugin uninstall vagrant-mutagen-utilizer

Update the plugin with:

    $ vagrant plugin update vagrant-mutagen-utilizer

## Usage

You need to set `orchestrate` and `config.vm.hostname`.

    config.mutagen_utilizer.orchestrate = true

This hostname will be used for the entry in the `~/.ssh/config` file.

Orchestration also requires a `mutagen.yml` file configured for your project.

### Example Project Orchestration Config (`mutagen.yml`)

As an example starting point you can use the following for a Drupal project:
```
sync:
  defaults:
    mode: "two-way-resolved"
    ignore:
      vcs: false
      paths:
        - /.idea/
        - /vendor/**/.git/
        - contrib/**/.git/
        - node_modules/
        - /web/sites/**/files/
    symlink:
      mode: "portable"
    watch:
      mode: "portable"
    permissions:
      defaultFileMode: 0644
      defaultDirectoryMode: 0755
  app:
    alpha: "your-vm.hostname:/srv/www/app/"
    beta: "./app/"
```

## Installing development version

If you would like to install vagrant-mutagen-utilize on the development version perform the following:

```
git clone https://github.com/ryu-sato/vagrant-mutagen-utilize
cd vagrant-mutagen-utilize
git checkout develop
gem build vagrant-mutagen-utilize.gemspec
vagrant plugin install vagrant-mutagen-utilize-*.gem
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request


## Versions
