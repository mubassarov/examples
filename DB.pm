package Tracer::DB;
use strict;
use warnings;
use Exporter;
use vars qw(@ISA @EXPORT @EXPORT_OK);

@ISA = ('Exporter');
@EXPORT = qw(
    connectDB
    disconnectDB
    getAlert
    getDays
    getDevice
    getObject
    getObjects
    getPositions
    getState
    getTracks
    getUser
    quoteDB
    requestDB
    selectDB
    setAlert
    storeDevide
    storeObject
    storePosition
    storeProperty
    storeState
);

use DBI;
use Data::Dumper;

use Tracer::Crypt;
use Tracer::Var;


my ($dbh);

sub connectDB {
    my $exist = -f $DBfile;

    $dbh = DBI->connect("DBI:SQLite:dbname=$DBfile", "", "", { RaiseError => 1 }) or die $DBI::errstr;

    initDB() unless $exist;
}

sub disconnectDB {
    return unless $dbh;

    $dbh->disconnect();
}

sub selectDB {
    my ($query) = @_;

    connectDB unless $dbh;
    print STDERR Dumper $query if $debug > 4;
    my $sth = $dbh->prepare($query);
    $sth->execute();

    my ($result, @row);
    while (@row = $sth->fetchrow_array()) {
	push @{$result}, [ @row ];
    }
    $sth->finish();

    return $result;
}

sub requestDB {
    connectDB unless $dbh;

    print STDERR Dumper @_ if $debug > 4;
    return
	@_?
	    @_ == 1?
		$dbh->do($_[0]):
		map { $dbh->do($_) } grep($_, ('BEGIN', @_, 'COMMIT')):
	    0;
}

sub quoteDB {
    connectDB unless $dbh;

    return
	@_?
	    @_ == 1?
		$dbh->quote($_[0]):
		map { $dbh->quote(defined $_?$_:'') } @_:
	();    
}

sub initDB {
    my $password = getCryptedPassword($defaultAdminLogin, $defaultAdminPassword);

    requestDB(<<EOF,
CREATE TABLE device (
    idDevice	INTEGER		PRIMARY KEY	AUTOINCREMENT,
    title	CHAR(32)			NOT NULL
);
EOF
<<EOF,
CREATE INDEX device_title_index ON device(title);
EOF

<<EOF,
CREATE TABLE object (
    idObject	INTEGER		PRIMARY KEY	AUTOINCREMENT,
    idDevice	INTEGER		NOT NULL,
    identify	CHAR(32)	NOT NULL,
    timezone	FLOAT		NOT NULL,
    FOREIGN KEY (idDevice) REFERENCES device(idDevice)
);
EOF
<<EOF,
CREATE INDEX object_device_index ON object(idDevice);
EOF
<<EOF,
CREATE INDEX object_identify_index ON object(identify);
EOF

<<EOF,
CREATE TABLE position (
    idPosition	INTEGER		PRIMARY KEY	AUTOINCREMENT,
    idObject	INTEGER		NOT NULL,
    date	INTEGER		NOT NULL,
    latitude	FLOAT		NOT NULL,
    longitude	FLOAT		NOT NULL,
    speed	FLOAT		NOT NULL,
    course	FLOAT		NOT NULL,
    state	CHAR(8)		NOT NULL,
    time	INTEGER		NOT NULL,
    FOREIGN KEY (idObject) REFERENCES object(idObject)
);
EOF

<<EOF,
CREATE TABLE state (
    idState	INTEGER		PRIMARY KEY	AUTOINCREMENT,
    idObject	INTEGER		NOT NULL,
    date	INTEGER		NOT NULL,
    key         CHAR(64)	NOT NULL,
    value	CHAR(256)	NOT NULL,
    time	INTEGER		NOT NULL,
    FOREIGN KEY (idObject) REFERENCES object(idObject)
);
EOF

<<EOF,
CREATE TABLE user (
    idUser	INTEGER		PRIMARY KEY	AUTOINCREMENT,
    login	CHAR(32)	NOT NULL,
    password	CHAR(60)	NOT NULL,
    fio		CHAR(32)	NOT NULL,
    phone	CHAR(11)	DEFAULT '',
    alert	INTEGER 	DEFAULT 0
);
EOF
<<EOF,
INSERT INTO user (idUser, login, password, fio) VALUES (0, '', '', 'supervisor');
EOF
<<EOF,
INSERT INTO user (login, password, fio) VALUES ('$defaultAdminLogin', '$password', 'Admin');
EOF

<<EOF,
CREATE TABLE property (
    idProperty	INTEGER		PRIMARY KEY	AUTOINCREMENT,
    idUser	INTEGER		NOT NULL,
    idObject	INTEGER		NOT NULL,
    title	CHAR(32)	DEFAULT '',
    FOREIGN KEY (idUser) REFERENCES user(idUser),
    FOREIGN KEY (idObject) REFERENCES object(idObject)
);
EOF

<<EOF,
CREATE TABLE alerts (
    idAlert	INTEGER		PRIMARY KEY	AUTOINCREMENT,
    idData      INTEGER         NOT NULL,
    idType      INTEGER         DEFAULT 0,
    isPosition  INTEGER         DEFAULT 1
    FOREIGN KEY (idType) REFERENCES type(idType),
);
EOF

<<EOF,
CREATE TABLE type (
    idType	INTEGER		PRIMARY KEY,
    name	CHAR(32)	DEFAULT ''
);
EOF
<<EOF,
INSERT INTO type (idType, name) VALUES (0, 'online');
EOF
<<EOF,
INSERT INTO type (idType, name) VALUES (1, 'drive');
EOF
<<EOF,
INSERT INTO type (idType, name) VALUES (2, 'offline');
EOF
    );
}

sub getDevice {
    my ($ref) = @_;

    my ($id, $title);
    $id = $ref->{'id'} if defined $ref->{'id'};
    $title = $ref->{'title'} if defined $ref->{'title'};
    return unless defined $id || defined $title;

    my $res = selectDB(
        'SELECT idDevice, title '.
        'FROM device '.
        'WHERE '.join(' AND ', defined $id?'idDevice = '.quoteDB($id):(), defined $title?'title = '.quoteDB($title):())
    );
    unless ($res) {
	return unless $id = storeDevide({ 'title' => $title});
    } else {
	($id, $title) = @{@{$res}[0]};
    }

    return {
	'id'	=> $id,
	'title'	=> $title,
    };
}

sub storeDevide {
    my ($ref) = @_;

    return unless defined $ref->{'title'};
    requestDB("INSERT INTO device (title) VALUES (".quoteDB($ref->{'title'}).")");
    $ref = selectDB("SELECT last_insert_rowid()");

    return @{@{$ref}[0]}[0];
}

sub getObject {
    my ($ref) = @_;

    my ($id, $tz, $identify);
    $id = $ref->{'id'} if defined $ref->{'id'};
    $identify = $ref->{'identify'} if defined $ref->{'identify'};

    return unless defined $id || defined $identify;

    my $res = selectDB(
        'SELECT idObject, timezone, identify '.
        'FROM object '.
        'WHERE '.join(' AND ', defined $id?'idObject = '.quoteDB($id):(), defined $identify?'identify = '.quoteDB($identify):())
    );

    unless ($res) {
        $ref->{'date'} = time unless defined $ref->{'date'};
	$tz = sprintf("%i", (time - $ref->{'date'})/1800 + 0.5) * 1800;
	return unless $id = storeObject({
	    'identify'	=> $identify,
	    'timezone'	=> $tz,
	    'type'	=> $ref->{'type'},
	});
    } else {
	($id, $tz, $identify) = @{@{$res}[0]};
    }

    return {
	'id'		=> $id,
	'identify'	=> $identify,
	'timezone'	=> $tz,
    };
}

sub fillPosition {
    my ($object, $position) = @_;

    return {
	'id'	    => @{$object}[0],
	'property'  => @{$object}[1],
	'timezone'  => @{$object}[2],
	'identify'  => @{$object}[3],
	'title'	    => @{$object}[4],
	'date'	    => @{$position}[2] ?
	                @{$position}[2] :
	                @{$position}[0] ?
	                    @{$position}[0] :
	                    0,
	'speed'     => @{$position}[1] ?
	                @{$position}[1] :
	                0,
	'latitude'  => @{$position}[3],
	'longitude' => @{$position}[4],
	'position'  => @{$position}[5],
    }
}

sub fillState {
    my ($object, $state) = @_;

    return {
	'id'	    => @{$object}[0],
	'property'  => @{$object}[1],
	'timezone'  => @{$object}[2],
	'identify'  => @{$object}[3],
	'title'     => @{$object}[4],
	'date'      => @{$state}[2] ? 
	                @{$state}[2] :
	                @{$state}[0] ?
	                    @{$state}[0] :
	                    0,
	'value'     => @{$state}[1],
	'key'       => @{$state}[4],
	'state'     => @{$state}[3],
    }
}

sub getObjects {
    my ($ref) = @_;

    my (@condition, @where);
    if (defined $ref->{'user'}) {
        $ref->{'user'} = quoteDB($ref->{'user'});
        push @condition, "idUser = $ref->{'user'}";
    } 
    if (defined $ref->{'identify'}) {
        $ref->{'identify'} = quoteDB($ref->{'identify'});
        push @condition, "identify = $ref->{'identify'}";
    }

    push @where, defined $ref->{'date'}?"date < $ref->{'date'}":
                defined $ref->{'time'}?"time < $ref->{'time'}":();
        
    return unless @condition || @where;

    my $where = @where ? ('AND '.join(' AND ', @where)) : '';
    my $condition = @condition ? ('WHERE '.join(' AND ', @condition)) : '';
    my ($res);

    if (my $data = selectDB(<<EOF
SELECT idObject, idProperty, timezone, identify, title
FROM property pr INNER JOIN object USING(idObject)
$condition
GROUP BY idObject
EOF
            )) {
        my ($id);
        foreach my $object (@{$data}) {
            $id = @{$object}[0];
            my $position = selectDB(<<EOF
SELECT date, speed, time, latitude, longitude, idposition
FROM (
        SELECT max(idposition) AS idposition
        FROM position
        WHERE idObject = $id $where
    ) INNER JOIN position p USING(idposition)
EOF
            );
            ($position) = @{$position} if defined $position;
            print STDERR Dumper $position if $debug > 2 && defined $position;

            my $state = selectDB(<<EOF
SELECT date, value, time, idState, key
FROM (
        SELECT max(idState) AS idState
        FROM state
        WHERE idObject = $id $where
    ) INNER JOIN state s USING(idState)
EOF
            );
            ($state) = @{$state} if defined $state;
            print STDERR Dumper $state if $debug > 2 && defined $state;

            if (defined $position) {
                if (defined $state) {
                    $res->{$id} = (@{$position}[2] > @{$state}[2]) ?
                        fillPosition($object, $position) :
                        fillState($object, $state)
                } else {
                    $res->{$id} = fillPosition($object, $position)
                }
            } elsif (defined $state) {
                $res->{$id} = fillState($object, $state)
            }
        }
    }

    return $res;
}

sub storeObject {
    my ($ref) = @_;

    return unless defined $ref->{'identify'} && (defined $ref->{'device'} || defined $ref->{'type'});

    unless (defined $ref->{'device'}) {
	my ($res);
	return unless $res = getDevice({ 'title' => $ref->{'type'} });
	$ref->{'device'} = $res->{'id'};
    }

    $ref->{'timezone'} = 0 unless $ref->{'timezone'};

    requestDB("INSERT INTO object (idDevice, identify, timezone) VALUES (".join(', ', quoteDB($ref->{'device'}, $ref->{'identify'}, $ref->{'timezone'})).")");
    $ref = selectDB("SELECT last_insert_rowid()");

    return @{@{$ref}[0]}[0];
}

sub storePosition {
    my ($ref) = @_;

    my ($res);
    return unless $res = getObject($ref);
    if (defined $ref->{'date'}) {
        $ref->{'date'} += $res->{'timezone'};
    } else {
        $ref->{'date'} = time;
    }

    requestDB("INSERT INTO position (idObject, date, latitude, longitude, speed, course, state, time) ".
		"VALUES (".join(', ', quoteDB($res->{'id'}, $ref->{'date'}, $ref->{'latitude'}, $ref->{'longitude'}, $ref->{'speed'}, $ref->{'course'}, $ref->{'state'}, time)).")");
}

sub storeState {
    my ($ref) = @_;

    my ($res);
    return unless $res = getObject($ref);
    if (defined $ref->{'date'}) {
        $ref->{'date'} += $res->{'timezone'};
    } else {
        $ref->{'date'} = time;
    }

    requestDB("INSERT INTO state (idObject, date, key, value, time) ".
		"VALUES (".join(', ', quoteDB($res->{'id'}, $ref->{'date'}, $ref->{'key'}, $ref->{'value'}, time)).")");
}

sub getUser {
    my ($ref) = @_;

    my ($id, $login, @where);
    my @from = ('user u');
    push @where, "u.idUser = ".quoteDB($ref->{'id'}) if defined $ref->{'id'} && $ref->{'id'} =~ /^\d+$/;
    push @where, "u.login = ".quoteDB($ref->{'login'}) if defined $ref->{'login'} && $ref->{'login'} =~ /^[a-z0-9\.]{3,32}$/i;
    if (defined $ref->{'alert'}) {
        if ($ref->{'alert'} eq '') {
            push @where, "u.alert != 0";
        } else {
            push @where, "u.alert = ".quoteDB($ref->{'alert'});
        }
    }
    if (defined $ref->{'phone'}) {
        if ($ref->{'phone'} eq '') {
            push @where, "u.phone != ''"
        } else {
            push @where, "u.phone = ".quoteDB($ref->{'phone'});
        }
    }
    if (defined $ref->{'object'}) {
        push @from, 'INNER JOIN property p USING(idUser)';
        push @where, "p.idObject = ".quoteDB($ref->{'object'});
    }

    my $res = selectDB(
        'SELECT u.idUser, u.fio, u.password, u.alert, u.phone '.
        'FROM '.join(' ', @from).(@where?(' WHERE '.join(' AND ', @where)):'')
    );

    return unless $res;

    my $out = sub {
        my ($data) = @_;

        return {
	    'id'	=> @{$data}[0],
	    'fio'	=> @{$data}[1],
	    'password'	=> @{$data}[2],
	    'alert'	=> @{$data}[3],
	    'phone'	=> @{$data}[4],
        }
    };

    return map { &$out($_) } @{$res};
}

sub storeProperty {
    my ($ref) = @_;

    return unless (defined $ref->{'property'} && $ref->{'property'} =~ /^\d+$/) || (defined $ref->{'object'} && defined $ref->{'user'} && $ref->{'object'} =~ /^\d+$/ && $ref->{'user'} =~ /^\d+$/);

    return requestDB(defined $ref->{'property'} && $ref->{'property'} =~ /^\d+$/?
	"UPDATE property SET ".join(', ',
		defined $ref->{'object'}?"idObject = ".quoteDB($ref->{'object'}):(),
		defined $ref->{'user'}?"idUser = ".quoteDB($ref->{'user'}):(),
		defined $ref->{'title'}?"title = ".quoteDB($ref->{'title'}):(),
	    )." WHERE idProperty = ".$ref->{'property'}:
	"INSERT INTO property (idUser, idObject, title) VALUES (".join(', ', quoteDB($ref->{'user'}, $ref->{'object'}, $ref->{'title'})).")");
}

sub getDays {
    my ($ref) = @_;

    my (@data);
    if (defined $ref->{'property'} &&
	($ref->{'property'} =~ /^\d+$/) &&
	(my $data = selectDB(<<EOF
SELECT date
FROM (
	SELECT strftime('%Y%m%d', datetime(case when time > 0 then time else date end, 'unixepoch')) AS date
	FROM position INNER JOIN property USING(idObject)
	WHERE idProperty = $ref->{'property'}
    ) AS d
GROUP BY date
ORDER BY date
EOF
	    ))) {
	foreach (@{$data}) {
	    push @data, map { /(\d{4})(\d{2})(\d{2})/; join('.', $3, $2, $1) } @{$_}[0];
	}
    }

    return @data;
}

sub getPositions {
    my ($ref) = @_;

    my ($res);
    my $from = {
	'position' =>  'position p'
    };
    my @from = ('position');
    my (@where);

    if (defined $ref->{'object'} && ($ref->{'object'} =~ /^\d+$/)) {
	push @where, 'p.idObject = '.quoteDB($ref->{'object'});
    }
    if (defined $ref->{'user'} && ($ref->{'user'} =~ /^\d+$/)) {
	$from->{'property'} = 'INNER JOIN property pr USING(idObject)';
	push @from, 'property';
	push @where, 'pr.idUser = '.quoteDB($ref->{'user'});
    }
    if (defined $ref->{'id'}) {
        if ($ref->{'id'} =~ /^([<=>])?(\d+)$/) {
            push @where, 'p.idposition '.($1?$1:'=').' '.quoteDB($2);
        }
    }
    if (defined $ref->{'day'} && ($ref->{'day'} =~ /^\d{2}\.\d{2}\.\d{4}$/)) {
	push @where, 'strftime(\'%d.%m.%Y\', datetime('.($ref->{'realtime'}?'p.time':'p.date').', \'unixepoch\')) = '.quoteDB($ref->{'day'});
    } else {
	if (defined $ref->{'start'} && ($ref->{'start'} =~ /^\d+$/)) {
	    push @where, ($ref->{'realtime'}?'p.time':'p.date').' >= '.quoteDB($ref->{'start'});
	}
	if (defined $ref->{'stop'} && ($ref->{'stop'} =~ /^\d+$/)) {
	    push @where, ($ref->{'realtime'}?'p.time':'p.date').' <= '.quoteDB($ref->{'stop'});
	}
    }

    if (my $data = selectDB(
            'SELECT p.date, p.latitude, p.longitude, p.speed, p.time, p.idPosition, p.idObject '.
            'FROM '.join(' ', map { $from->{$_} } @from).
            (@where?(' WHERE '.join(' AND ', @where)):'').
            ' ORDER BY p.date'.
            ($ref->{'last'} ? ' DESC LIMIT 1' : ''))) {
	foreach (@{$data}) {
	    push @{$res}, {
		'date'		=> $ref->{'realtime'}?@{$_}[4]?@{$_}[4]:@{$_}[0]:@{$_}[0],
		'latitude'	=> @{$_}[1],
		'longitude'	=> @{$_}[2],
		'speed'		=> @{$_}[3],
		'time'		=> @{$_}[4],
		'id'		=> @{$_}[5],
		'object'	=> @{$_}[6],
	    }
	}
    }

    return $res;
}

sub getState {
    my ($ref) = @_;

    my ($res);
    my $from = {
	'state'         => 'state s'
    };
    my @from = ('state');
    my (@where);

    if (defined $ref->{'object'} && ($ref->{'object'} =~ /^\d+$/)) {
	push @where, 's.idObject = '.quoteDB($ref->{'object'});
    }
    if (defined $ref->{'user'} && ($ref->{'user'} =~ /^\d+$/)) {
	$from->{'property'} = 'INNER JOIN property pr USING(idObject)';
	push @from, 'property';
	push @where, 'pr.idUser = '.quoteDB($ref->{'user'});
    }
    if (defined $ref->{'id'}) {
        if ($ref->{'id'} =~ /^([<=>])?(\d+)$/) {
            push @where, 's.idState '.($1 ? $1 : '=').' '.quoteDB($2);
        }
    }
    if (defined $ref->{'day'} && ($ref->{'day'} =~ /^\d{2}\.\d{2}\.\d{4}$/)) {
	push @where, 'strftime(\'%d.%m.%Y\', datetime('.($ref->{'realtime'}?'s.time':'s.date').', \'unixepoch\')) = '.quoteDB($ref->{'day'});
    } else {
	if (defined $ref->{'start'} && ($ref->{'start'} =~ /^\d+$/)) {
	    push @where, ($ref->{'realtime'}?'s.time':'s.date').' >= '.quoteDB($ref->{'start'});
	}
	if (defined $ref->{'stop'} && ($ref->{'stop'} =~ /^\d+$/)) {
	    push @where, ($ref->{'realtime'}?'s.time':'s.date').' <= '.quoteDB($ref->{'stop'});
	}
    }

    my ($seen);
    @from = grep { !$seen->{$_}++ } @from;
    if (my $data = selectDB(
            'SELECT s.date, s.key, s.value, s.time, s.idState, s.idObject '.
            'FROM '.join(' ', map { $from->{$_} } @from).
            (@where?(' WHERE '.join(' AND ', @where)):'').
            ' ORDER BY s.date')) {
        print STDERR Dumper $data if $debug > 5;
	foreach (@{$data}) {
	    push @{$res}, {
		'date'		=> $ref->{'realtime'} ? @{$_}[3] ? @{$_}[3] : @{$_}[0] : @{$_}[0],
		'key'           => @{$_}[1],
		'value'         => @{$_}[2],
		'time'		=> @{$_}[3],
		'id'		=> @{$_}[4],
		'object'	=> @{$_}[5],
	    }
	}
    }

    return $res;
}


sub getAlert {
    my ($ref) = @_;

    my $from = {
        'alert'         => 'alerts a',
        'position'      => 'INNER JOIN position p ON a.idData = p.idPosition AND a.isPosition = 1',
    };
    my @from = ('alert', 'position');

    my (@where);
    if (defined $ref->{'id'} && ($ref->{'id'} =~ /^\d+$/)) {
        push @where, 'a.idalert = '.quoteDB($ref->{'id'});
    }
    if (defined $ref->{'object'} && ($ref->{'object'} =~ /^\d+$/)) {
        push @where, 'p.idObject = '.quoteDB($ref->{'object'});
    }

    my ($res, $data);
    if ($data = selectDB('SELECT a.idAlert, a.idData, p.idObject, p.date, p.latitude, p.longitude, p.speed, p.time, a.idType '.
                            'FROM '.join(' ', map { $from->{$_} } @from).
                            (@where ? (' WHERE '.join(' AND ', @where)) : '').
                            ' ORDER BY a.idalert')) {
        print STDERR Dumper $data if $debug > 4;
        foreach (@{$data}) {
            $res->{@{$_}[2]}->{@{$_}[8]} = {
                'id'            => @{$_}[0],
                'position'      => @{$_}[1],
                'object'        => @{$_}[2],
                'date'          => @{$_}[7]?@{$_}[7]:@{$_}[3]?@{$_}[3]:0,
		'latitude'	=> @{$_}[4],
		'longitude'	=> @{$_}[5],
		'speed'		=> @{$_}[6],
		'time'		=> @{$_}[7],
            }
        }
    }

    $from = {
        'alert'         => 'alerts a',
        'state'         => 'INNER JOIN state s ON a.idData = s.idState AND a.isPosition = 0',
    };
    @from = ('alert', 'state');
    @where = map { s/^p\./s./; $_ } @where;
    if ($data = selectDB('SELECT a.idAlert, a.idData, s.idObject, s.date, s.time, a.idType '.
                            'FROM '.join(' ', map { $from->{$_} } @from).
                            (@where ? (' WHERE '.join(' AND ', @where)) : '').
                            ' ORDER BY a.idAlert')) {
        print STDERR Dumper $data if $debug > 4;
        foreach (@{$data}) {
            $res->{@{$_}[2]}->{@{$_}[5]} = {
                'id'            => @{$_}[0],
                'state'         => @{$_}[1],
                'object'        => @{$_}[2],
                'date'          => @{$_}[4]?@{$_}[4]:@{$_}[3]?@{$_}[3]:0,
		'time'		=> @{$_}[4],
            }
        }
    }

    return $res;
}

sub setAlert {
    my ($ref) = @_;

    return unless $ref->{'position'};

    unless (defined $ref->{'id'} && ($ref->{'id'} =~ /^\d+$/)) {
        if (my $pos = getPositions({ 'id' => $ref->{'position'} })) {
            if (my $alert = getAlert({ 'object' => @{$pos}[0]->{'object'} })) {
                $ref->{'id'} = $alert->{(keys %{$alert})[0]}->{'id'};
            }
        }
    }

    $ref->{'position'} = quoteDB($ref->{'position'});
    $ref->{'type'} = quoteDB(defined $ref->{'type'} && $ref->{'type'} =~ /^\d+$/ ? $ref->{'type'} : 0);
    $ref->{'mode'} = quoteDB(defined $ref->{'mode'} ? $ref->{'mode'} : 1);
    if (defined $ref->{'id'} && ($ref->{'id'} =~ /^\d+$/)) {
        requestDB('UPDATE alerts SET idData = '.$ref->{'position'}.', isPosition = '.$ref->{'mode'}.' WHERE idAlert = '.quoteDB($ref->{'id'}));
    } else {
        requestDB('INSERT INTO alerts (idData, idType, isPosition) VALUES ('.$ref->{'position'}.', '.$ref->{'type'}.', '.$ref->{'mode'}.')');
    }
}

1;
