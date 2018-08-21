Available console commands
===========================

List simple commands run in project root.

 - `composer server init` create project docker folder, prepare docker env
 - `composer server up` run server [see more](https://docs.docker.com/compose/reference/up/)
 - `composer server down` stop server [see more](https://docs.docker.com/compose/reference/down/)
 - `composer server restart` sequential execution of commands `down` and `up`
 - `composer server "logs server"` shown logs service `server`
 - `composer server-run server "ls -l"` create service `server`, run command `ls -l` inside container and remove service
 - `composer server-exec server "ls -l"` run command inside exist running service `server`
 
[See AWS commands](ENVIRONMENTS.md#auto-update-hosts-envs)