package Nokia::Tangaza::Schema::Groups;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("groups");
__PACKAGE__->add_columns(
  "group_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "group_name",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 60,
  },
  "group_name_file",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 32,
  },
  "group_type",
  { data_type => "ENUM", default_value => "public", is_nullable => 0, size => 7 },
  "is_active",
  { data_type => "ENUM", default_value => undef, is_nullable => 1, size => 3 },
  "org_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
);
__PACKAGE__->set_primary_key("group_id");
__PACKAGE__->add_unique_constraint("group_name", ["group_name", "is_active"]);
__PACKAGE__->has_many(
  "admin_group_histories",
  "Nokia::Tangaza::Schema::AdminGroupHistory",
  { "foreign.group_id" => "self.group_id" },
);
__PACKAGE__->has_many(
  "group_admins",
  "Nokia::Tangaza::Schema::GroupAdmin",
  { "foreign.group_id" => "self.group_id" },
);
__PACKAGE__->belongs_to(
  "org_id",
  "Nokia::Tangaza::Schema::Organization",
  { org_id => "org_id" },
);
__PACKAGE__->has_many(
  "invitations",
  "Nokia::Tangaza::Schema::Invitations",
  { "foreign.group_id" => "self.group_id" },
);
__PACKAGE__->has_many(
  "pub_messages",
  "Nokia::Tangaza::Schema::PubMessages",
  { "foreign.channel" => "self.group_id" },
);
__PACKAGE__->has_many(
  "sub_messages",
  "Nokia::Tangaza::Schema::SubMessages",
  { "foreign.channel" => "self.group_id" },
);
__PACKAGE__->has_many(
  "user_group_histories",
  "Nokia::Tangaza::Schema::UserGroupHistory",
  { "foreign.group_id" => "self.group_id" },
);
__PACKAGE__->has_many(
  "user_groups",
  "Nokia::Tangaza::Schema::UserGroups",
  { "foreign.group_id" => "self.group_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-12-20 11:06:11
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Z73zwK4koOjA5i/i7T9iWA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
