#!/usr/bin/env perl6

use v6;
use DBIish;

#########################
# Variables
# #######################
my $dbh = DBIish.connect("SQLite", :database<bycicle_kilometer.sqlite3>, :RaiseError);

my token day	{ \d+ };
my token month	{ \d+ };
my token year	{ \d+ };

multi sub MAIN("delete-database") {
	my $answer = prompt "Do you realy want to delete the database? ";
	if "y" eq lc $answer {
		say "Delete database";
		my $sth = $dbh.do('DROP TABLE if exists bycicle_kilometer');
	} else {
		say "Do not delete database!";
	}
}

multi sub MAIN("create-database") {
	say "Create new database";
	$dbh.do(q:to/STATEMENT/);
		CREATE TABLE if not exists bycicle_kilometer (
			bk_id			INTEGER PRIMARY KEY AUTOINCREMENT,
			bk_date			int,
			bk_kilometer	int
		)
		STATEMENT
}

multi sub MAIN("add", $date, Int $kilometer) {
	say "add";

	if $date ~~ / <day> \. <month> \. <year> / {
		say "day ", $<day>;
		say "month ", $<month>;
		say "year ", $<year>;
		my $d = DateTime.new(year => +$<year>, month => +$<month>, day => +$<day>);
		say $d.posix;
	} else {
		say "Could not recognize date string '$date'. Expect patter dd.mm.yyyy";
	}


}

multi sub MAIN("change", $date, $kilometer) {
	say "change";
}

multi sub MAIN("average", $type) {
	say "average";
}

sub help() {
	say qq:to "ENDHELP";
$?FILE date kilometer energy

date : the date pattern dd.mm.yy
kilometer : the kilometer amount
energy : The energy consumed

ENDHELP
}
