use strict;
use warnings;
use English;
use Test::More;
use Test::Exception;
use File::Spec::Functions qw( catdir splitpath rel2abs );

#use OpenXPKI::Debug; $OpenXPKI::Debug::LEVEL{'OpenXPKI::Server::Database.*'} = 100;

#
# setup
#
my $basedir = catdir((splitpath(rel2abs(__FILE__)))[0,1]);
require "$basedir/DatabaseTest.pm";

my $db = DatabaseTest->new(
    columns => [ # yes an ArrayRef to have a defined order!
        id => "INTEGER PRIMARY KEY",
        text => "VARCHAR(100)",
        entropy => "INTEGER",
    ],
    data => [
        [ 1, "Litfasssaeule", 1 ],
        [ 2, "Buergersteig",  1 ],
        [ 3, "Rathaus",       42 ],
        [ 4, "Kindergarten",  3 ],
    ],
);

#
# tests
#
$db->run("SQL SELECT", 11, sub {
    my $t = shift;
    my $dbi = $t->dbi;
    my $sth;

    # simple select
    lives_ok {
        $sth = $dbi->select(
            from => "test",
            columns => [ "text" ],
            where => { id => 3 },
        );
        is_deeply $sth->fetchall_arrayref, [
            [ "Rathaus" ],
        ];
    } "simple select";

    # select with AND
    lives_ok {
        $sth = $dbi->select(
            from => "test",
            columns => [ "text" ],
            where => { text => "Litfasssaeule", entropy => 1 },
        );
        is_deeply $sth->fetchall_arrayref, [
            [ "Litfasssaeule" ],
        ];
    } "select with AND";

    # select with OR
    lives_ok {
        $sth = $dbi->select(
            from => "test",
            columns => [ "text" ],
            where => { entropy => [ 1, 42] },
        );
        is_deeply $sth->fetchall_arrayref, [
            [ "Litfasssaeule" ],
            [ "Buergersteig" ],
            [ "Rathaus" ],
        ];
    } "select with OR";

    # select with "bigger than"
    lives_ok {
        $sth = $dbi->select(
            from => "test",
            columns => [ "text" ],
            where => { id => { ">=", 3 } },
        );
        is_deeply $sth->fetchall_arrayref, [
            [ "Rathaus" ],
            [ "Kindergarten" ],
        ];
    } "select with 'bigger than'";

    # select without result
    lives_ok {
        $sth = $dbi->select(
            from => "test",
            columns => [ "text" ],
            where => { text => "Rathaus", entropy => 33 },
        );
        is_deeply $sth->fetchall_arrayref, [];
    } "select without result";

    # select from non existing table
    dies_ok {
        $sth = $dbi->select(
            from => "huh",
            columns => [ "text" ],
            where => { entropy => 33 },
        );
    } "select from non existing table";
});

done_testing($db->test_no);
