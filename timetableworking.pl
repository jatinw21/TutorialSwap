#!/usr/bin/env perl -w
use DBI;
use LWP::Simple qw(get);

# declaration of TABLE
my $dbfile = "tutorials.db";
if (-e "tutorials.db") {
    `rm $dbfile`;
}
my $dsn ="dbi:SQLite:dbname=$dbfile";
my $user = "";
my $password = "";
my $dbh = DBI->connect($dsn,$user,$password, {
    PrintError => 0,
    RaiseError => 1,
    AutoCommit => 1,
    FetchHashKeyName => 'NAME_lc',
});

# my $sqlCommand = <<'END_SQL';
# CREATE TABLE tutorials (
#     id          INTEGER PRIMARY KEY,
#     courseName  VARCHAR(9),
#     courseDesc  VARCHAR(100),
#     tutCode     VARCHAR(5),
#     classType   VARCHAR(4),
#     status      VARCHAR(7),
#     emptySpaces INTEGER
# );
# END_SQL
#
# $dbh->do($sqlCommand);

# perl stuff
our $wkDay = qr/Mon|Tue|Wed|Thu|Fri|Sat|Sun/;


my $url = 'http://classutil.unsw.edu.au/COMP_S1.html';
my $html = get $url;

my @lines = split(/\n/, $html);
my $i = 1;
# for each line
for (my $lineNo = 0; $lineNo < scalar(@lines); $lineNo++) {
    # whenever course name line found
    if ($lines[$lineNo] =~ /([A-Z]{4}[0-9]{4})(?=&nbsp;&nbsp;)/) {

        my $courseCode = $1;
        print "Course $courseCode\n";
        # Move to next line THEN grab course description.
        (my $courseDesc = $lines[$lineNo+1]) =~ s/^.*?valign=center>([^<]+)<\/td>.*?$/$1/g;
        $courseDesc =~ s/&amp;/&/g;

        # Until we hit another course header or the end of the file keep looking for tut/lab/tlb's for this course.
        # NB: moves to next line at start of each iteration (pre ++).
        while ($lineNo + $i < @lines && $lines[$lineNo] !~ /.*cucourse.*/) {
            if ($lines[$lineNo] =~ /<td(?: class="cucomp")?>(LAB|TUT|TLB)<\/td><td(?: class="cucomp")?>([^<]+)<\/td><td>\s*(\d+)<\/td><td>([^<]+)<\/td><td(?: class="cuwarn")?>([^<]+)<\/td><td>(\d+)\/(\d+)/g) {

                my ($classType,$tutCode,$tutClass,$tutType,$tutStatus,$stuEnr,$stuCap) = ($1,$2,$3,$4,$5,$6,$7);
                my $emptySpaces = $stuCap - $stuEnr;
                printf("line: %-7s Course: %-12sDesc: %-35sClass: %-10sTutCode: %-10sClass: %-10sType: %-10sStatus: %-10sEmpty Spaces: %-10s\n",
                   $lineNo, $courseCode, $courseDesc, $classType, $tutCode, $tutClass, $tutType, $tutStatus, $emptySpaces);

                # $dbh->do('INSERT INTO tutorials (id,courseName,courseDesc,tutCode,classType,status,emptySpaces) VALUES (?, ?, ?, ?, ?, ?, ?)',
                # undef,
                # $tutClass,
                # $courseCode,
                # $courseDesc,
                # $tutCode,
                # $classType,
                # $tutStatus,
                # $emptySpaces);

                # First basically separate text on semicolons, grab wkday and time.
                #  - There were some strange classes with e.g. 'w2-PP7,8-13,'
                #  - not sure if the same might occur with times somewhere,
                #  - used \w instead of \d to make sure we catch any
                # while ($lines[$lineNo+1] =~ /($wkDay) *(\w+(?:-\w+)?)([^;]+)/g) {
                #     print "\tClass on $1 at $2\n";
                #     print "\tRemaining: $3\n";
                #
                #     # Example remaining string to parse here:
                #     #  - (w4,6,8,10,12, Quad 1049)
                #     #  - (w2-7,8-13, Ainswth101)
                #     #  - (w2-PP7,8-13, CybSK17G11) - ???? what
                #     #  - (Drum K17B8)              - NO SPECIFIC WEEKS
                #     if ($3 =~ /w(((\w+(?:-\w+)?),)+)/) {
                #         my @times = split(/,/,$1);
                #         foreach my $tm (@times) {
                #             print "\t\tclass at $tm\n";
                #         }
                #     }
                # }
            }
            #print "\n";
        }
        $i +=1;
    }
}
