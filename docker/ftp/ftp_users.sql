create table ftp_users
(
  User        varchar(16) default ''      not null,
  status      enum ('0', '1') default '0' not null,
  Password    varchar(64) default ''      not null,
  Uid         varchar(11) default '-1'    not null,
  Gid         varchar(11) default '-1'    not null,
  Dir         varchar(128) default ''     not null,
  ULBandwidth smallint default '0'        not null,
  DLBandwidth smallint default '0'        not null,
  comment     tinytext                    not null,
  ipaccess    varchar(15) default '*'     not null,
  QuotaSize   smallint default '0'        not null,
  QuotaFiles  int default '0'             not null,
  constraint User
  unique (User)
)
  charset = utf8;

alter table ftp_users
  add primary key (User);