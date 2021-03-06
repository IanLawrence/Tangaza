package Nokia::Tangaza::Schema::AuthUser;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("auth_user");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "username",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 30,
  },
  "first_name",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 30,
  },
  "last_name",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 30,
  },
  "email",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 75,
  },
  "password",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 128,
  },
  "is_staff",
  { data_type => "TINYINT", default_value => undef, is_nullable => 0, size => 1 },
  "is_active",
  { data_type => "TINYINT", default_value => undef, is_nullable => 0, size => 1 },
  "is_superuser",
  { data_type => "TINYINT", default_value => undef, is_nullable => 0, size => 1 },
  "last_login",
  {
    data_type => "DATETIME",
    default_value => undef,
    is_nullable => 0,
    size => 19,
  },
  "date_joined",
  {
    data_type => "DATETIME",
    default_value => undef,
    is_nullable => 0,
    size => 19,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("username", ["username"]);
__PACKAGE__->has_many(
  "organizations",
  "Nokia::Tangaza::Schema::Organization",
  { "foreign.org_admin_id" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-12-20 11:06:11
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:lbAK4KhnW9jkmQMl54aFtQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
